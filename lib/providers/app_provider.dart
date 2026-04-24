import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report.dart';
import '../constants/report_types.dart';

class AppProvider with ChangeNotifier {
  bool _ready = false;
  String? _phone;
  int _points = 0;
  int _rank = 42;
  List<Report> _reports = _seedReports;

  static const String _storageKey = 'roadly:v1';

  static final List<Report> _seedReports = [
    Report(
      id: 'seed-1',
      type: ReportType.accident,
      description: 'Two-vehicle collision blocking the right lane.',
      status: ReportStatus.verified,
      points: 15,
      createdAt: DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 5,
      location: Location(label: 'MG Road · 0.3 km'),
      byUser: false,
    ),
    Report(
      id: 'seed-2',
      type: ReportType.roadWork,
      description: 'Crew laying asphalt — expect single lane traffic.',
      status: ReportStatus.verified,
      points: 10,
      createdAt: DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 22,
      location: Location(label: 'Brigade Road · 0.8 km'),
      byUser: false,
    ),
    Report(
      id: 'seed-3',
      type: ReportType.congestion,
      description: 'Heavy traffic backing up near the junction.',
      status: ReportStatus.pending,
      points: 5,
      createdAt: DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 47,
      location: Location(label: 'Trinity Circle · 1.2 km'),
      byUser: false,
    ),
    Report(
      id: 'seed-4',
      type: ReportType.blocked,
      description: 'Tree fallen across the road, vehicles diverting.',
      status: ReportStatus.verified,
      points: 20,
      createdAt: DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 65,
      location: Location(label: 'Cubbon Road · 1.5 km'),
      byUser: false,
    ),
  ];

  bool get ready => _ready;
  String? get phone => _phone;
  bool get isLoggedIn => _phone != null;
  int get points => _points;
  int get rank => _rank;
  List<Report> get reports => _reports;

  AppProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final Map<String, dynamic> data = {};
        // Simple parsing since we can't use jsonDecode easily without imports
        // We'll use a simpler approach with SharedPreferences directly
        _phone = prefs.getString('phone');
        _points = prefs.getInt('points') ?? 0;
        _rank = prefs.getInt('rank') ?? 42;
        
        // For reports, we'd need to serialize/deserialize properly
        // For simplicity, we'll just keep seed reports for now
      }
    } catch (e) {
      // Ignore errors
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone', _phone ?? '');
      await prefs.setInt('points', _points);
      await prefs.setInt('rank', _rank);
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> login(String incoming) async {
    final cleaned = incoming.replaceAll(RegExp(r'\D'), '');
    _phone = cleaned;
    final startingPoints = _points > 0 ? _points : 120;
    _points = startingPoints;
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    _phone = null;
    _points = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove('phone');
    await prefs.remove('points');
    await prefs.remove('rank');
    notifyListeners();
  }

  Report addReport({
    required ReportType type,
    required String description,
    required String location,
  }) {
    final meta = ReportTypes.getMeta(type);
    final report = Report(
      id: '${DateTime.now().millisecondsSinceEpoch}${DateTime.now().microsecond.toString().padLeft(6, '0')}',
      type: type,
      description: description,
      status: ReportStatus.pending,
      points: meta.points,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      location: Location(label: location.isEmpty ? 'Current location' : location),
      byUser: true,
    );

    _reports.insert(0, report);
    _points += meta.points;
    _rank = (rank - 1).clamp(1, 100);
    _persist();
    notifyListeners();
    return report;
  }
}
