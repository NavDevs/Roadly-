import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/report.dart';
import '../providers/app_provider.dart';

class Badge {
  final String name;
  final IconData icon;
  final int threshold;

  Badge({required this.name, required this.icon, required this.threshold});
}

final List<Badge> badges = [
  Badge(name: 'First Report', icon: Icons.flag, threshold: 1),
  Badge(name: 'Verified', icon: Icons.check_circle, threshold: 50),
  Badge(name: '100 Pts', icon: Icons.emoji_events, threshold: 100),
  Badge(name: '500 Pts', icon: Icons.star, threshold: 500),
  Badge(name: 'Top Reporter', icon: Icons.trending_up, threshold: 1000),
];

class LeaderboardEntry {
  final int rank;
  final String name;
  final int points;
  final int reports;
  final bool isUser;

  LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.reports,
    this.isUser = false,
  });
}

final List<LeaderboardEntry> baseLeaderboard = [
  LeaderboardEntry(rank: 1, name: 'Rajesh K.', points: 450, reports: 28),
  LeaderboardEntry(rank: 2, name: 'Priya S.', points: 380, reports: 24),
  LeaderboardEntry(rank: 3, name: 'Amit V.', points: 320, reports: 19),
  LeaderboardEntry(rank: 4, name: 'Sneha M.', points: 260, reports: 16),
  LeaderboardEntry(rank: 5, name: 'Karan D.', points: 210, reports: 12),
];

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final points = appProvider.points;
          final rank = appProvider.rank;
          final reports = appProvider.reports;
          final myReportsCount = reports.where((r) => r.byUser).length;

          final leaderboard = [
            ...baseLeaderboard,
            LeaderboardEntry(
              rank: rank,
              name: 'You',
              points: points,
              reports: myReportsCount,
              isUser: true,
            ),
          ];

          final nextBadge = badges.firstWhere((b) => b.threshold > points, orElse: () => badges.last);
          final progressTo = nextBadge.threshold > points ? points / nextBadge.threshold : 1.0;

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: MediaQuery.of(context).padding.bottom + 40,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rewards',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Earn points by reporting verified road issues',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                // Hero card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF16A34A), Color(0xFF0E7C3A), Color(0xFF064E2C)],
                    ),
                    borderRadius: BorderRadius.circular(AppColors.radius + 8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Points',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                points.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rank #$rank this week',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.emoji_events, size: 32, color: Colors.white),
                          ),
                        ],
                      ),
                      if (nextBadge.threshold > points) ...[
                        const SizedBox(height: 18),
                        Column(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: FractionallySizedBox(
                                widthFactor: progressTo,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${nextBadge.threshold - points} pts to ${nextBadge.name}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Badges section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Badges',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${badges.where((b) => points >= b.threshold).length} of ${badges.length}',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: badges.map((b) {
                    final earned = points >= b.threshold;
                    return Container(
                      width: (MediaQuery.of(context).size.width - 60) / 3,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: earned ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: earned
                                  ? AppColors.primary.withOpacity(0.13)
                                  : AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              b.icon,
                              color: earned ? AppColors.primary : AppColors.mutedForeground,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            b.name,
                            style: const TextStyle(
                              color: AppColors.foreground,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                // Leaderboard section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Leaderboard',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'This week',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: leaderboard.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final user = entry.value;
                      final isLast = idx == leaderboard.length - 1;
                      
                      Color medalColor = AppColors.mutedForeground;
                      if (user.rank == 1) medalColor = const Color(0xFFFBBF24);
                      else if (user.rank == 2) medalColor = const Color(0xFFCBD5E1);
                      else if (user.rank == 3) medalColor = const Color(0xFFB923C);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: user.isUser ? AppColors.primary.withOpacity(0.10) : null,
                          border: isLast ? null : Border(bottom: BorderSide(color: AppColors.border)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: user.rank <= 3
                                  ? Icon(Icons.emoji_events, color: medalColor, size: 16)
                                  : Text(
                                      '${user.rank}',
                                      style: TextStyle(
                                        color: AppColors.mutedForeground,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: TextStyle(
                                      color: AppColors.foreground,
                                      fontSize: 15,
                                      fontWeight: user.isUser ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${user.reports} reports',
                                    style: TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              user.points.toString(),
                              style: const TextStyle(
                                color: AppColors.foreground,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
