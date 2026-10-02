import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/report_types.dart';
import '../models/report.dart';

class MapPreview extends StatefulWidget {
  final List<Report> reports;

  const MapPreview({super.key, required this.reports});

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  /// Incidents a driver has claimed (or finished) leave the public map:
  /// the card keeps showing live progress, but the pin must not look
  /// like an unattended emergency anymore.
  static const _handledStates = {'ACCEPTED', 'EN_ROUTE', 'ARRIVED', 'RESOLVED'};

  /// Markers currently rendered (live ones + briefly-lingering fading ones).
  List<Report> _markers = [];
  final Set<String> _fading = {};
  final Map<String, Timer> _fadeTimers = {};

  List<Report> _live(List<Report> src) => src
      .where((r) =>
          r.latitude != null &&
          r.longitude != null &&
          !_handledStates.contains((r.lifecycleState ?? '').toUpperCase()))
      .toList();

  @override
  void initState() {
    super.initState();
    _markers = _live(widget.reports);
  }

  @override
  void didUpdateWidget(MapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final live = _live(widget.reports);
    final liveIds = live.map((r) => r.id).toSet();

    // Markers that just went past their TTL linger for a moment with a
    // fade-out so the map never "teleports" pins away.
    for (final m in List.of(_markers)) {
      if (liveIds.contains(m.id) || _fading.contains(m.id)) continue;
      _fading.add(m.id);
      _fadeTimers[m.id] = Timer(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        setState(() {
          _fading.remove(m.id);
          _fadeTimers.remove(m.id)?.cancel();
          _markers.removeWhere((x) => x.id == m.id);
        });
      });
    }

    // A revived incident (re-opened on the dashboard) cancels its fade.
    for (final id in List.of(_fading)) {
      if (!liveIds.contains(id)) continue;
      _fadeTimers.remove(id)?.cancel();
      _fading.remove(id);
    }

    // Keep stable slot order: survivors refresh in place, fading ones hold
    // their slot until the timer drops them, new pins append.
    final liveById = {for (final r in live) r.id: r};
    final next = <Report>[];
    for (final m in _markers) {
      if (liveById.containsKey(m.id)) {
        next.add(liveById[m.id]!);
      } else if (_fading.contains(m.id)) {
        next.add(m);
      }
    }
    for (final r in live) {
      if (!_markers.any((e) => e.id == r.id)) next.add(r);
    }
    _markers = next;
    setState(() {});
  }

  @override
  void dispose() {
    for (final t in _fadeTimers.values) {
      t.cancel();
    }
    _fadeTimers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only pins that are truly live count/center; fading ones are invisible
    // within a beat.
    final validReports = _live(widget.reports);

    // Default center (Bangalore) or center on the first valid report
    final initialCenter = validReports.isNotEmpty
        ? LatLng(validReports.first.latitude!, validReports.first.longitude!)
        : const LatLng(12.9716, 77.5946);

    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.roadly',
              ),
              MarkerLayer(
                markers: _markers.map((report) {
                  final meta = ReportTypes.getMeta(report.type);
                  final fading = _fading.contains(report.id);
                  return Marker(
                    point: LatLng(report.latitude!, report.longitude!),
                    width: 40,
                    height: 40,
                    child: AnimatedOpacity(
                      opacity: fading ? 0 : 1,
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.easeOut,
                      child: Container(
                        decoration: BoxDecoration(
                          color: meta.color.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: meta.color.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Icon(
                          _getIconData(meta.iconName),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Badge
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0D12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '${validReports.length} reports nearby',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'alert_octagon': return Icons.warning;
      case 'flame': return Icons.local_fire_department;
      case 'tool': return Icons.build;
      case 'truck': return Icons.local_shipping;
      case 'slash': return Icons.block;
      default: return Icons.error_outline;
    }
  }
}
