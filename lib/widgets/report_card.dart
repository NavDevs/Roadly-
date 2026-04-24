import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/report_types.dart';
import '../models/report.dart';
import '../utils/format.dart';

class ReportCard extends StatelessWidget {
  final Report report;

  const ReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final meta = ReportTypes.getMeta(report.type);
    
    final statusColors = {
      ReportStatus.verified: {
        'bg': const Color(0x2916A34A),
        'fg': const Color(0xFF22C55E),
      },
      ReportStatus.pending: {
        'bg': const Color(0x29F59E0B),
        'fg': const Color(0xFFF59E0B),
      },
      ReportStatus.resolved: {
        'bg': const Color(0x2938BDF8),
        'fg': const Color(0xFF38BDF8),
      },
    };

    final statusStyle = statusColors[report.status] ?? statusColors[ReportStatus.pending]!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: AppColors.border),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: meta.color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: meta.color.withOpacity(0.33)),
            ),
            child: Icon(
              _getIconData(meta.iconName),
              color: meta.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      meta.label,
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusStyle['bg'],
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        report.status.name,
                        style: TextStyle(
                          color: statusStyle['fg'],
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  report.description.isNotEmpty ? report.description : 'No description provided.',
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                    height: 1.38,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  children: [
                    _metaItem(Icons.location_on, report.location.label),
                    _metaItem(Icons.access_time, FormatUtils.timeAgo(report.createdAt)),
                    _metaItem(Icons.emoji_events, '+${report.points} pts', color: AppColors.accent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color ?? AppColors.mutedForeground),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color ?? AppColors.mutedForeground,
            fontSize: 11,
          ),
        ),
      ],
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
