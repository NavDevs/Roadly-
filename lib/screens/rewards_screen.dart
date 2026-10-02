import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/report.dart';
import '../providers/app_provider.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final points = provider.points;
    final rank = provider.rank;
    final reports = provider.reports;
    final leaderboard = provider.leaderboard;

    // Real counts from data
    final myReports = reports.where((r) => r.byUser).toList();
    final totalSubmitted = myReports.length;
    final verifiedCount = myReports.where((r) => r.status == ReportStatus.verified).length;

    // Badges with real unlock conditions
    final badges = [
      {
        'title': 'First Reporter',
        'desc': 'Submit your first report',
        'icon': Icons.fiber_new,
        'earned': totalSubmitted >= 1,
      },
      {
        'title': 'Road Guardian',
        'desc': 'Submit 5 reports',
        'icon': Icons.shield,
        'earned': totalSubmitted >= 5,
      },
      {
        'title': 'Traffic Hero',
        'desc': 'Submit 10 reports',
        'icon': Icons.stars,
        'earned': totalSubmitted >= 10,
      },
      {
        'title': 'Verified Eye',
        'desc': 'Get a report verified',
        'icon': Icons.verified,
        'earned': verifiedCount >= 1,
      },
      {
        'title': 'Point Hunter',
        'desc': 'Earn 50+ points',
        'icon': Icons.emoji_events,
        'earned': points >= 50,
      },
      {
        'title': 'Legend',
        'desc': 'Reach #1 on leaderboard',
        'icon': Icons.military_tech,
        'earned': rank == 1 && points > 0,
      },
    ];

    final earnedCount = badges.where((b) => b['earned'] == true).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Rewards & Leaderboard',
          style: TextStyle(color: AppColors.foreground, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            Row(
              children: [
                _statBox('Your Points', '$points', AppColors.accent),
                const SizedBox(width: 14),
                _statBox('Global Rank', '#$rank', AppColors.foreground),
                const SizedBox(width: 14),
                _statBox('Reports', '$totalSubmitted', AppColors.primary),
              ],
            )
                .animate()
                .fade(delay: 60.ms, duration: 400.ms)
                .slideY(delay: 60.ms, duration: 400.ms, begin: 0.06, curve: Curves.easeOutQuad),
            const SizedBox(height: 30),

            // Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Badges', style: TextStyle(color: AppColors.foreground, fontSize: 18, fontWeight: FontWeight.w700)),
                Text('$earnedCount / ${badges.length} unlocked', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
              ],
            )
                .animate()
                .fade(delay: 140.ms, duration: 400.ms)
                .slideY(delay: 140.ms, duration: 400.ms, begin: 0.06, curve: Curves.easeOutQuad),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: badges.map((b) {
                  final earned = b['earned'] as bool;
                  return GestureDetector(
                    onTap: () => _showBadgeInfo(context, b),
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                      decoration: BoxDecoration(
                        color: earned ? AppColors.card : AppColors.secondary,
                        borderRadius: BorderRadius.circular(AppColors.radius),
                        border: Border.all(
                          color: earned ? AppColors.primary : AppColors.border,
                          width: earned ? 1.5 : 1,
                        ),
                        boxShadow: earned
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Icon(b['icon'] as IconData, size: 30, color: earned ? AppColors.primary : AppColors.mutedForeground),
                          const SizedBox(height: 10),
                          Text(
                            b['title'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: earned ? AppColors.foreground : AppColors.mutedForeground,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (earned) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'EARNED',
                                style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.border.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'LOCKED',
                                style: TextStyle(color: AppColors.mutedForeground, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
                .animate()
                .fade(delay: 220.ms, duration: 400.ms)
                .slideY(delay: 220.ms, duration: 400.ms, begin: 0.06, curve: Curves.easeOutQuad),
            const SizedBox(height: 30),

            // Leaderboard
            Text('Top Citizens', style: const TextStyle(color: AppColors.foreground, fontSize: 18, fontWeight: FontWeight.w700))
                .animate()
                .fade(delay: 300.ms, duration: 400.ms)
                .slideY(delay: 300.ms, duration: 400.ms, begin: 0.06, curve: Curves.easeOutQuad),
            const SizedBox(height: 14),
            (leaderboard.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppColors.radius), border: Border.all(color: AppColors.border)),
                  child: const Center(child: Text('No citizens yet. Be the first!', style: TextStyle(color: AppColors.mutedForeground))),
                )
              : Container(
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppColors.radius), border: Border.all(color: AppColors.border)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: leaderboard.length,
                    separatorBuilder: (_, __) => Divider(color: AppColors.border, height: 1),
                    itemBuilder: (context, index) {
                      final entry = leaderboard[index];
                      final isUser = entry['isUser'] == true;
                      final medal = index == 0 ? '🥇' : (index == 1 ? '🥈' : (index == 2 ? '🥉' : ''));
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isUser ? AppColors.primary : (index < 3 ? AppColors.accent.withValues(alpha: 0.1) : AppColors.secondary),
                          child: medal.isNotEmpty && !isUser
                            ? Text(medal, style: const TextStyle(fontSize: 18))
                            : Text('${index + 1}', style: TextStyle(color: isUser ? Colors.white : AppColors.mutedForeground, fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                        title: Text(
                          entry['name'] as String,
                          style: TextStyle(
                            color: isUser ? AppColors.primary : AppColors.foreground,
                            fontWeight: isUser ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${entry['verified']} verified reports',
                          style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                        ),
                        trailing: Text(
                          '${entry['points']} pts',
                          style: TextStyle(color: isUser ? AppColors.primary : AppColors.accent, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      );
                    },
                  ),
                ))
                .animate()
                .fade(delay: 360.ms, duration: 400.ms)
                .slideY(delay: 360.ms, duration: 400.ms, begin: 0.06, curve: Curves.easeOutQuad),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppColors.radius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: valueColor, fontSize: 28, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  static void _showBadgeInfo(BuildContext context, Map<String, Object> badge) {
    final earned = badge['earned'] as bool;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(badge['icon'] as IconData, color: earned ? AppColors.primary : AppColors.mutedForeground, size: 28),
            const SizedBox(width: 12),
            Text(badge['title'] as String, style: const TextStyle(color: AppColors.foreground, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge['desc'] as String,
              style: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: earned ? AppColors.primary.withValues(alpha: 0.1) : AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                earned ? '✅ Badge unlocked!' : '🔒 Keep going to unlock this badge',
                style: TextStyle(
                  color: earned ? AppColors.primary : AppColors.mutedForeground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
