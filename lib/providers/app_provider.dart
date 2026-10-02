import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/report.dart';
import '../constants/report_types.dart';
import '../navigation.dart';

class AppProvider with ChangeNotifier {
  bool _ready = false;
  String? _phone;
  String? _name;
  String? _userId;
  int _points = 0;
  int _rank = 1;
  List<Report> _reports = [];
  List<Map<String, dynamic>> _leaderboard = [];
  // Reports already announced as expired (so the periodic tick notifies once
  // per transition, not every 10 seconds).
  final Set<String> _expiredAnnounced = {};
  Timer? _expiryTick;
  Timer? _syncTick;

  // One-shot message shown on the next login screen (e.g. the server data
  // reset notice). Consumed on read so it never survives a re-login.
  String? _sessionNotice;

  /// Returns the pending login-screen notice (if any) and clears it.
  String? consumeNotice() {
    final notice = _sessionNotice;
    _sessionNotice = null;
    return notice;
  }

  static String get baseUrl {
    return 'https://clearpath-server.onrender.com';
  }

  late IO.Socket socket;

  bool get ready => _ready;
  String? get phone => _phone;
  String? get name => _name;
  bool get isLoggedIn => _userId != null;
  int get points => _points;
  int get rank => _rank;
  List<Report> get reports => _reports;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;

  /// Driver-owned lifecycle states: the server lets these finish (grace past
  /// the TTL) instead of resolving them the moment the clock runs out.
  static const _handledStates = {'ACCEPTED', 'EN_ROUTE', 'ARRIVED'};

  /// Whether the server still shows this incident to citizens.
  ///
  /// Time comes from the backend's `expires_at` (never local clock math on
  /// invented durations): the report disappears exactly at its TTL, even if
  /// the auto-expiry sweep (up to 2 min later) hasn't resolved it yet.
  bool isLiveReport(Report r) {
    final lc = (r.lifecycleState ?? '').toUpperCase();
    if (lc == 'RESOLVED' || lc == 'REJECTED') return false;
    final exp = r.expiresAt == null ? null : DateTime.tryParse(r.expiresAt!);
    if (exp == null) return true;
    if (exp.toUtc().isAfter(DateTime.now().toUtc())) return true;
    return _handledStates.contains(lc);
  }

  /// Reports the home feed, map and "Active" stats show. History ("My
  /// Reports") keeps resolved rows until the server purges them (48h).
  List<Report> get liveReports =>
      List.unmodifiable(_reports.where(isLiveReport));

  AppProvider(String? initialUserId) {
    _userId = initialUserId;
    debugPrint('[AppProvider] Constructor: initialUserId=$initialUserId');
    _init();
  }

  /// Periodic expiry check: when a report crosses its TTL while the app is
  /// open (and no socket event has arrived yet), notify the UI once so the
  /// home list and map can animate the item out. No countdown is shown — this
  /// only drives removal.
  void _startExpiryTick() {
    _expiryTick?.cancel();
    _expiryTick = Timer.periodic(const Duration(seconds: 10), (_) {
      var changed = false;
      for (final r in _reports) {
        if (!isLiveReport(r) && _expiredAnnounced.add(r.id)) changed = true;
      }
      if (changed) notifyListeners();
    });
  }

  /// Safety net under the socket: while signed in, re-sync the report list
  /// every 30s so a dead or never-established socket can't freeze the home
  /// feed (driver completes a trip, citizen badge stuck on "Dispatched").
  /// No-op when signed out; a failed fetch is already swallowed by
  /// [fetchReports].
  void _startSyncTick() {
    _syncTick?.cancel();
    _syncTick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_userId != null) fetchReports();
    });
  }

  Future<String> _sessionFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path + '/roadly_session.json';
  }

  Future<String> _metaFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path + '/roadly_meta.json';
  }

  /// Boot-time guard against server data wipes.
  ///
  /// /health exposes a `dataEpoch` counter that bumps whenever the admin resets
  /// the server database. If the stored epoch differs from the server's, every
  /// cached session is dead (its user row no longer exists) — delete it so the
  /// app lands on the login screen instead of a ghost session. Any network
  /// failure keeps the current session: offline must never sign a user out.
  Future<bool> _checkDataEpoch() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return true;
      final serverEpoch = json.decode(response.body)['dataEpoch']?.toString();
      if (serverEpoch == null) return true;

      String? storedEpoch;
      try {
        final metaFile = File(await _metaFilePath());
        if (await metaFile.exists()) {
          storedEpoch = json
              .decode(await metaFile.readAsString())['dataEpoch']
              ?.toString();
        }
        await metaFile.writeAsString(
            json.encode({'dataEpoch': serverEpoch}),
            flush: true);
      } catch (e) {
        debugPrint('[AppProvider] Epoch meta write error: $e');
      }

      if (storedEpoch == null) return true; // first boot on this device
      if (storedEpoch == serverEpoch) return true;
      debugPrint('[AppProvider] data epoch $storedEpoch -> $serverEpoch');
      return false;
    } catch (e) {
      debugPrint('[AppProvider] Data epoch check failed: $e');
      return true; // unreachable: keep the cached session
    }
  }

  Future<void> _init() async {
    await _loadFromStorage();
    debugPrint('[AppProvider] After load: _userId=$_userId, _phone=$_phone');
    // Only a session loaded from disk needs the server-wipe guard (and the
    // network round-trip it costs). A fresh login screen skips it so the
    // app is usable immediately.
    if (_userId != null) {
      final intact = await _checkDataEpoch();
      if (!intact) {
        debugPrint('[AppProvider] Server data was reset — clearing local session');
        _sessionNotice = 'Server data was reset. Please sign in again.';
        _userId = null;
        _phone = null;
        _name = null;
        _points = 0;
        _rank = 1;
        _reports = [];
        _leaderboard = [];
        _expiredAnnounced.clear();
        try {
          final sessionFile = File(await _sessionFilePath());
          if (await sessionFile.exists()) await sessionFile.delete();
        } catch (e) {
          debugPrint('[AppProvider] Epoch wipe delete error: $e');
        }
      }
    }
    _setupSocket();
    _startExpiryTick();
    _startSyncTick();
    if (_userId != null) {
      await Future.wait([fetchReports(), fetchLeaderboard()]);
    } else {
      _ready = true;
      notifyListeners();
    }
  }

  void _setupSocket() {
    socket = IO.io(baseUrl, IO.OptionBuilder().setTransports(['websocket']).build());
    socket.onConnect((_) {
      debugPrint('Connected to Realtime Dispatch');
      // (Re)sync on every (re)connect: a socket that dropped (or was never
      // established) must never leave the home feed showing a stale
      // lifecycle badge after the driver completes a trip.
      if (_userId != null) fetchReports();
    });

    socket.on('new_incident', (data) {
      if (data is! Map) return;
      final mapped = Map<String, dynamic>.from(data);
      final newReport = _mapReportJson(mapped);
      final idx = _reports.indexWhere((r) => r.id == newReport.id);
      if (idx == -1) {
        _reports.insert(0, newReport);
      } else {
        _reports[idx] = newReport;
      }
      notifyListeners();
    });

    socket.on('report_updated', (data) {
      if (data is! Map) return;
      final mapped = Map<String, dynamic>.from(data);
      // Keep the row in the full list (history still shows it) — liveScreens
      // filter it out via isLiveReport, which animates it off home/map.
      final idx = _reports.indexWhere((r) => r.id == mapped['id']);
      final updated = _mapReportJson(mapped);
      if (idx != -1) {
        _reports[idx] = updated;
      } else {
        _reports.insert(0, updated);
      }
      if (isLiveReport(updated)) _expiredAnnounced.remove(updated.id);
      notifyListeners();
    });

    // The server purged the incident (48h after it resolved): it is gone from
    // the database forever, so drop it from history too.
    socket.on('report_deleted', (data) {
      if (data is! Map) return;
      final id = data['id']?.toString();
      if (id == null) return;
      _reports.removeWhere((r) => r.id == id);
      _expiredAnnounced.remove(id);
      notifyListeners();
    });

    socket.on('points_updated', (_) {
      fetchLeaderboard();
    });

    // Driver-response loop (Signal-Aid accepted / en route / arrived / done):
    // the backend also emits report_updated for these, but re-sync here so the
    // citizen never misses a transition even if one event is dropped.
    for (final event in [
      'dispatch.accepted',
      'dispatch.created',
      'trip.started',
      'trip.arrived',
      'trip.completed'
    ]) {
      socket.on(event, (_) => fetchReports());
    }

    // The admin wiped the server database: drop the dead local session
    // immediately instead of waiting for the next cold start.
    socket.on('data_reset', (_) {
      debugPrint('[AppProvider] data_reset received — signing out');
      _sessionNotice = 'Server data was reset. Please sign in again.';
      logout();
      appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
  }

  Future<void> fetchLeaderboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/leaderboard'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // The leaderboard carries this user's server-side points — refresh them
        // so a returning user always sees their current total, even after a
        // cold start with a stale session file.
        final mine = data.firstWhere(
          (e) => e is Map && e['id'] == _userId,
          orElse: () => null,
        );
        if (mine is Map && mine['points'] != null) {
          final serverPoints = mine['points'];
          final parsed = serverPoints is num
              ? serverPoints.toInt()
              : int.tryParse('$serverPoints');
          if (parsed != null && parsed != _points) {
            _points = parsed;
            await _persist();
          }
        }

        _leaderboard = data.map((e) {
          final phone = (e['phone'] ?? '').toString();
          final end = phone.length > 7 ? 7 : (phone.length > 2 ? phone.length : 2);
          final maskedPhone = phone.length > 2
              ? phone.replaceRange(2, end, '*****')
              : phone;
          return {
            'name': e['phone'] == _phone ? 'You' : (e['name'] ?? maskedPhone),
            'points': e['points'],
            'verified': ((e['points'] ?? 0) / 15).floor(),
            'isUser': e['id'] == _userId
          };
        }).toList();

        final myIdx = _leaderboard.indexWhere((e) => e['isUser'] == true);
        if (myIdx != -1) _rank = myIdx + 1;

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch leaderboard error: $e');
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final path = await _sessionFilePath();
      final file = File(path);
      debugPrint('[AppProvider] Loading from: $path');
      if (await file.exists()) {
        final raw = await file.readAsString();
        debugPrint('[AppProvider] File contents: $raw');
        final data = json.decode(raw);
        if (data['userId'] != null) _userId = data['userId'];
        if (data['phone'] != null) _phone = data['phone'];
        if (data['name'] != null) _name = data['name'];
        _points = data['points'] ?? 0;
      } else {
        debugPrint('[AppProvider] No session file found');
      }
    } catch (e) {
      debugPrint('[AppProvider] Storage read error: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final path = await _sessionFilePath();
      final file = File(path);
      final data = {
        'userId': _userId,
        'phone': _phone,
        'name': _name,
        'points': _points,
      };
      await file.writeAsString(json.encode(data), flush: true);
      debugPrint('[AppProvider] Saved session to: $path');
    } catch (e) {
      debugPrint('[AppProvider] Storage write error: $e');
    }
  }

  Report _mapReportJson(Map<String, dynamic> jsonMap) {
    final copy = Map<String, dynamic>.from(jsonMap);
    copy['byUser'] = copy['user_id'] == _userId;
    copy['location'] = {'label': copy['address'] ?? 'Unknown location'};
    if (copy['created_at'] != null) {
      final rawTs = copy['created_at'].toString();
      final utcTs = rawTs.endsWith('Z') ? rawTs : rawTs + 'Z';
      try {
        copy['createdAt'] = DateTime.parse(utcTs).millisecondsSinceEpoch;
      } catch (_) {
        copy['createdAt'] = DateTime.now().millisecondsSinceEpoch;
      }
    } else {
      copy['createdAt'] ??= DateTime.now().millisecondsSinceEpoch;
    }

    if (copy['photo_url'] != null &&
        copy['photo_url'].toString().isNotEmpty &&
        !copy['photo_url'].toString().startsWith('http')) {
      copy['photo_url'] = '$baseUrl${copy['photo_url']}';
    }

    return Report.fromJson(copy);
  }

  Future<void> fetchReports() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/reports'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _reports = data
            .whereType<Map>()
            .map((j) => _mapReportJson(Map<String, dynamic>.from(j)))
            .toList();
      }
    } catch (e) {
      debugPrint('Fetch reports error: $e');
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> login(String incomingPhone, String password) async {
    final cleaned = incomingPhone.replaceAll(RegExp(r'\D'), '');
    final response = await _postJson(
        '$baseUrl/api/auth/login', {'phone': cleaned, 'password': password});
    await _applyAuthResponse(response, 'Login success');
  }

  Future<void> register(String name, String incomingPhone, String password) async {
    final cleaned = incomingPhone.replaceAll(RegExp(r'\D'), '');
    final response = await _postJson('$baseUrl/api/auth/register',
        {'name': name, 'phone': cleaned, 'password': password});
    await _applyAuthResponse(response, 'Register success');
  }

  /// POST with a hard timeout. Network-level failures (no internet, DNS,
  /// proxy error pages, timeouts) become one friendly message — a raw
  /// exception must never reach the login screen.
  Future<http.Response> _postJson(String url, Map<String, dynamic> body) async {
    try {
      return await http
          .post(Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body))
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception('The server is taking too long. Please try again.');
    } catch (_) {
      throw Exception(
          'Could not reach the server. Check your internet connection and try again.');
    }
  }

  /// Shared success/error handling for login and register. Failures throw
  /// only human-readable text produced by [authErrorMessage].
  Future<void> _applyAuthResponse(http.Response response, String logLabel) async {
    final body = _tryDecodeObject(response.body);
    final user = body?['user'];
    if (response.statusCode == 200 && user is Map) {
      final data = Map<String, dynamic>.from(user);
      _userId = data['id']?.toString();
      _phone = data['phone']?.toString();
      _name = data['name']?.toString();
      _points = (data['points'] as num?)?.toInt() ?? 0;
      debugPrint('[AppProvider] $logLabel: userId=$_userId');
      await _persist();
      await Future.wait([fetchReports(), fetchLeaderboard()]);
      notifyListeners();
      return;
    }
    throw Exception(authErrorMessage(response.statusCode, body));
  }

  /// Decodes a response body only if it really is JSON. Anything else
  /// (HTML proxy/error pages, truncated bodies) returns null instead of
  /// throwing a FormatException at character 1.
  Map<String, dynamic>? _tryDecodeObject(String source) {
    try {
      final decoded = json.decode(source);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  /// Turns a failed auth response into a message that is safe to show the
  /// user. The server's own `error` string passes through; anything
  /// technical (FormatException text, HTML, missing body) becomes a
  /// generic sentence.
  String authErrorMessage(int statusCode, Map<String, dynamic>? body) {
    final serverError = body?['error']?.toString().trim();
    if (serverError != null &&
        serverError.isNotEmpty &&
        !serverError.contains('<!DOCTYPE')) {
      return serverError;
    }
    if (statusCode == 400) return 'Please check your details and try again.';
    if (statusCode == 401) return 'Incorrect phone number or password.';
    if (statusCode == 404) {
      return 'No account found for this number. Please sign up first.';
    }
    if (statusCode == 429) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (statusCode >= 500) {
      return 'The server is having trouble. Please try again in a moment.';
    }
    return 'Could not reach the server. Check your internet connection and try again.';
  }

  Future<void> logout() async {
    _phone = null;
    _name = null;
    _userId = null;
    _points = 0;
    _rank = 1;
    _leaderboard = [];
    // Drop the previous user's reports too, so a different account logging in
    // on this device never sees them (and nobody sees stale rows after a
    // re-login — fetchReports() repopulates from the server).
    _reports = [];
    _expiredAnnounced.clear();
    try {
      final path = await _sessionFilePath();
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[AppProvider] logout delete error: $e');
    }
    notifyListeners();
  }

  /// Returns null on success, or an error message on failure.
  Future<String?> addReport({
    required ReportType type,
    required String description,
    required String location,
    String? photoUri,
    double? latitude,
    double? longitude,
  }) async {
    if (_userId == null) {
      return 'Please log in again before submitting a report.';
    }

    final meta = ReportTypes.getMeta(type);

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/reports'));
      request.fields['user_id'] = _userId!;
      request.fields['type'] = type.name;
      request.fields['description'] = description;
      request.fields['address'] = location.isEmpty ? 'Current location' : location;
      request.fields['points'] = meta.points.toString();
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();

      if (photoUri != null && photoUri.isNotEmpty) {
        try {
          request.files.add(await http.MultipartFile.fromPath('photo', photoUri));
        } catch (e) {
          debugPrint('[AppProvider] Photo attach failed: $e');
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('[AppProvider] Submit status=${response.statusCode} body=${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          final report = _mapReportJson(data);
          _reports.removeWhere((r) => r.id == report.id);
          _reports.insert(0, report);
        }
        _points += meta.points;
        await _persist();
        notifyListeners();
        // Keep list in sync with server (lifecycle may already be updating)
        fetchReports();
        return null;
      }

      try {
        final err = json.decode(response.body);
        // Stale session (e.g. server database was reset): drop the dead
        // session so the next submit forces a fresh login instead of 500s.
        if (err is Map && (err['code'] == 'STALE_SESSION' || response.statusCode == 401)) {
          _sessionNotice = 'Server data was reset. Please sign in again.';
          await logout();
          return 'Session expired. Please log in again, then resubmit.';
        }
        return (err is Map ? err['error'] : null)?.toString() ??
            'Server rejected the report (${response.statusCode})';
      } catch (_) {
        return 'Server rejected the report (${response.statusCode}).';
      }
    } catch (e) {
      debugPrint('Submit report error: $e');
      return 'Could not submit report. Check your internet and try again.';
    }
  }
}
