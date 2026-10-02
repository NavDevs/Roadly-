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

    // Lifecycle state badge for the incident's response status
    final lifecycleBadge = _getLifecycleBadge(report.lifecycleState);

    return GestureDetector(
      onTap: () => _showDetails(context, meta),
      child: Container(
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
                color: meta.color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: meta.color.withValues(alpha: 0.33)),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _metaItem(Icons.location_on, report.location.label),
                      _metaItem(Icons.access_time, FormatUtils.timeAgo(report.createdAt)),
                      // Smooth badge morph when the driver-response loop advances
                      // the incident (verified → dispatched → en route → resolved).
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        // easeOut (no overshoot past 1.0) so the pop can
                        // never push the row past its bounds.
                        switchInCurve: Curves.easeOut,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(scale: animation, child: child),
                        ),
                        child: lifecycleBadge != null
                            ? KeyedSubtree(
                                key: ValueKey(report.lifecycleState),
                                child: lifecycleBadge,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Returns a widget showing the incident lifecycle state badge
  Widget? _getLifecycleBadge(String? state) {
    if (state == null) return null;
    
    Map<String, Map<String, dynamic>> badgeMap = {
      'ACTIVE': {
        'label': '📍 Active',
        'color': const Color(0xFF38BDF8),
        'bg': const Color(0x2938BDF8),
      },
      'DISPATCHED': {
        'label': '🚑 Dispatched — waiting for driver',
        'color': const Color(0xFF22C55E),
        'bg': const Color(0x2916A34A),
      },
      'ACCEPTED': {
        'label': '🚑 Driver Assigned',
        'color': const Color(0xFF22C55E),
        'bg': const Color(0x2916A34A),
      },
      'EN_ROUTE': {
        'label': '🚑 En Route',
        'color': const Color(0xFF38BDF8),
        'bg': const Color(0x2938BDF8),
      },
      'ARRIVED': {
        'label': '📍 Arrived On Scene',
        'color': const Color(0xFF38BDF8),
        'bg': const Color(0x2938BDF8),
      },
      'REJECTED': {
        'label': '❌ Rejected',
        'color': const Color(0xFFEF4444),
        'bg': const Color(0x29EF4444),
      },
      'RECHECK': {
        'label': '🔄 Recheck',
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0x29F59E0B),
      },
      'RESOLVED': {
        'label': '✔ Resolved',
        'color': const Color(0xFF22C55E),
        'bg': const Color(0x2916A34A),
      },
    };
    
    final badge = badgeMap[state];
    if (badge == null) return null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badge['bg'],
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: badge['color'].withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badge['label'],
            style: TextStyle(
              color: badge['color'],
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, dynamic meta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            // Scrollable: tall content (photo + details) can never overflow,
            // no matter how short the window is.
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: meta.color.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: meta.color.withValues(alpha: 0.33)),
                          ),
                          child: Icon(
                            _getIconData(meta.iconName),
                            color: meta.color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          meta.label,
                          style: const TextStyle(
                            color: AppColors.foreground,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (report.photoUrl != null && report.photoUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      report.photoUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      // Decode near display size: keeps large uploads from
                      // spiking memory (and dropping frames) on low-end devices.
                      cacheWidth: 1080,
                      frameBuilder: (context, child, frame, wasSync) {
                        if (wasSync) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                const Text(
                  'Description',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.description.isNotEmpty ? report.description : 'No description provided.',
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report.location.label,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Phase 17: Show lifecycle state in details (null-safe: unknown states hidden, never crash)
                if (_getLifecycleBadge(report.lifecycleState) != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      _getLifecycleBadge(report.lifecycleState)!,
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      FormatUtils.timeAgo(report.createdAt),
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events, color: AppColors.accent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '+${report.points} pts',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
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
      case 'flame':
        return Icons.local_fire_department;
      case 'tool':
        return Icons.build;
      case 'truck':
        return Icons.local_shipping;
      case 'slash':
        return Icons.block;
      case 'water':
        return Icons.water_drop;
      case 'pothole':
        return Icons.construction;
      default:
        return Icons.error_outline;
    }
  }
}