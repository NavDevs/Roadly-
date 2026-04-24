import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/report_types.dart';
import '../models/report.dart';

class MapPreview extends StatelessWidget {
  final List<Report> reports;

  const MapPreview({super.key, required this.reports});

  static const List<Map<String, double>> markerPositions = [
    {'top': 0.22, 'left': 0.28},
    {'top': 0.48, 'left': 0.62},
    {'top': 0.62, 'left': 0.22},
    {'top': 0.32, 'left': 0.72},
    {'top': 0.70, 'left': 0.55},
  ];

  @override
  Widget build(BuildContext context) {
    final visible = reports.take(markerPositions.length).toList();

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F1A14), Color(0xFF0B0F12), Color(0xFF1A1208)],
              ),
            ),
          ),
          // Grid lines
          ...List.generate(6, (i) => Positioned(
            top: (i + 1) * 14.0 / 100 * 280,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              color: const Color(0x10FFFFFF),
            ),
          )),
          ...List.generate(5, (i) => Positioned(
            left: (i + 1) * 18.0 / 100 * MediaQuery.of(context).size.width,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1,
              color: const Color(0x10FFFFFF),
            ),
          )),
          // Roads
          Positioned(
            top: 0.44 * 280,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              color: const Color(0x18FFFFFF),
            ),
          ),
          Positioned(
            left: 0.52 * MediaQuery.of(context).size.width,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              color: const Color(0x18FFFFFF),
            ),
          ),
          // User marker
          Positioned(
            top: 0.5 * 280 - 11,
            left: 0.5 * MediaQuery.of(context).size.width - 11,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // Report markers
          ...visible.asMap().entries.map((entry) {
            final idx = entry.key;
            final report = entry.value;
            final meta = ReportTypes.getMeta(report.type);
            final pos = markerPositions[idx];
            
            return Positioned(
              top: pos!['top']! * 280 - 16,
              left: pos['left']! * MediaQuery.of(context).size.width - 16,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: meta.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: meta.color.withOpacity(0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Icon(
                  _getIconData(meta.iconName),
                  color: Colors.white,
                  size: 14,
                ),
              ),
            );
          }).toList(),
          // Badges
          Positioned(
            bottom: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    '${reports.length} reports nearby',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Live',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
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
      case 'alert_octagon':
        return Icons.warning;
      case 'tool':
        return Icons.build;
      case 'truck':
        return Icons.local_shipping;
      case 'slash':
        return Icons.block;
      default:
        return Icons.error_outline;
    }
  }
}
