import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/report.dart';
import '../providers/app_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final phone = appProvider.phone;
          final points = appProvider.points;
          final rank = appProvider.rank;
          final reports = appProvider.reports;
          final myReports = reports.where((r) => r.byUser).toList();
          final verified = myReports.where((r) => r.status == ReportStatus.verified).length;

          final displayPhone = phone != null ? '+91 ${phone.substring(0, 5)} ${phone.substring(5)}' : 'Not signed in';

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
                  'Profile',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 18),
                // Profile card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.person, size: 28, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        displayPhone,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reporter since today',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.only(top: 18),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    points.toString(),
                                    style: const TextStyle(
                                      color: AppColors.foreground,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Points',
                                    style: TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '#$rank',
                                    style: const TextStyle(
                                      color: AppColors.foreground,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rank',
                                    style: TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    verified.toString(),
                                    style: const TextStyle(
                                      color: AppColors.foreground,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // Settings list
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _listItem(Icons.notifications, 'Notifications', 'On'),
                      _divider(),
                      _listItem(Icons.location_on, 'Location services', 'Always'),
                      _divider(),
                      _listItem(Icons.shield, 'Privacy'),
                      _divider(),
                      _listItem(Icons.help, 'Help & support'),
                      _divider(),
                      _listItem(Icons.info, 'About Roadly', 'v1.0'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Logout button
                GestureDetector(
                  onTap: () async {
                    await appProvider.logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppColors.radius),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, color: AppColors.danger, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Sign out',
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _listItem(IconData icon, String label, [String? meta]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.mutedForeground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (meta != null)
            Text(
              meta,
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
              ),
            ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: AppColors.mutedForeground, size: 18),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: AppColors.border,
    );
  }
}
