import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';
import '../providers/app_provider.dart';
import '../widgets/expiring_report_list.dart';
import '../widgets/map_preview.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          // Only incidents the server still shows: expired/resolved ones are
          // filtered out (the list animates them away at their TTL).
          final reports = appProvider.liveReports;

          return Stack(
            children: [
              RefreshIndicator(
                color: AppColors.primarySoft,
                backgroundColor: AppColors.card,
                onRefresh: () => Future.wait([
                  appProvider.fetchReports(),
                  appProvider.fetchLeaderboard(),
                ]),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    bottom: 100, // Space for FAB
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good Morning,',
                                style: TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                appProvider.name ?? 'Citizen',
                                style: const TextStyle(
                                  color: AppColors.foreground,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.stars, color: AppColors.accent, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${appProvider.points} pts',
                                  style: const TextStyle(
                                    color: AppColors.foreground,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade(duration: 400.ms).slideY(begin: -0.2, end: 0, curve: Curves.easeOutQuad),
                    const SizedBox(height: 24),
                    // Map Preview
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: MapPreview(reports: reports),
                    ).animate().fade(delay: 100.ms, duration: 500.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutQuart),
                    const SizedBox(height: 18),
                    // Quick report CTA
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/report'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(AppColors.radius),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.warning,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Report a road issue',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Help drivers and emergency vehicles',
                                      style: TextStyle(
                                        color: const Color(0xD9FFFFFF),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                       .shimmer(delay: 2.seconds, duration: 1500.ms, color: Colors.white.withValues(alpha: 0.2))
                    ).animate().fade(delay: 500.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),
                    const SizedBox(height: 24),
                    // Recent reports header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nearby reports',
                            style: TextStyle(
                              color: AppColors.foreground,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Updated just now',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 600.ms).slideX(begin: -0.1, curve: Curves.easeOut),
                    const SizedBox(height: 10),
                    // Recent reports list — cards animate out as their TTL ends
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ExpiringReportList(reports: reports.take(6).toList()),
                    ),
                  ],
                ),
              ),
              ),
              // FAB
              Positioned(
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 24,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/report'),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ).animate()
                 .scale(delay: 1.seconds, duration: 500.ms, curve: Curves.elasticOut)
                 .then(delay: 3.seconds)
                 .shake(duration: 400.ms, hz: 3)
              ),
            ],
          );
        },
      ),
    );
  }
}
