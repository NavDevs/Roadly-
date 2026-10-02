import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../models/report.dart';
import '../providers/app_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;
  String _locationMode = 'Always';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsOn = prefs.getBool('notificationsOn') ?? true;
        _locationMode = prefs.getString('locationMode') ?? 'Always';
      });
    }
  }

  Future<void> _toggleNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsOn = !_notificationsOn;
    });
    await prefs.setBool('notificationsOn', _notificationsOn);
  }

  Future<void> _toggleLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locationMode = _locationMode == 'Always' ? 'While Using' : (_locationMode == 'While Using' ? 'Never' : 'Always');
    });
    await prefs.setString('locationMode', _locationMode);
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title, style: const TextStyle(color: AppColors.foreground)),
        content: Text(content, style: const TextStyle(color: AppColors.mutedForeground)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final phone = appProvider.phone;
          final name = appProvider.name;
          final points = appProvider.points;
          final rank = appProvider.rank;
          final reports = appProvider.reports;
          final myReports = reports.where((r) => r.byUser).toList();
          final verified = myReports.where((r) => r.status == ReportStatus.verified).length;

          final displayPrimary = name != null && name.isNotEmpty ? name : (phone != null ? '+91 ${phone.substring(0, 5)} ${phone.substring(5)}' : 'Not signed in');
          final displaySecondary = (name != null && name.isNotEmpty && phone != null) ? '+91 ${phone.substring(0, 5)} ${phone.substring(5)}' : 'Reporter since today';

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
                Text(
                  'Profile',
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate()
                    .fade(delay: 40.ms, duration: 400.ms)
                    .slideY(delay: 40.ms, duration: 400.ms, begin: 0.06, curve: Curves.easeOutQuad),
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
                        displayPrimary,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displaySecondary,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.only(top: 18),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
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
                                  const Text(
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
                                  const Text(
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
                                  const Text(
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
                )
                    .animate()
                    .fade(delay: 140.ms, duration: 400.ms)
                    .slideY(delay: 140.ms, duration: 400.ms, begin: 0.06, curve: Curves.easeOutQuad),
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
                      _listItem(Icons.notifications, 'Notifications', _notificationsOn ? 'On' : 'Off', _toggleNotifications),
                      _divider(),
                      _listItem(Icons.location_on, 'Location services', _locationMode, _toggleLocation),
                      _divider(),
                      _listItem(Icons.shield, 'Privacy', null, () => _showInfoDialog('Privacy', 'Your data is secured using SQLite and stored locally.')),
                      _divider(),
                      _listItem(Icons.help, 'Help & support', null, () => _showInfoDialog('Help', 'Please contact support@roadly.local for help.')),
                      _divider(),
                      _listItem(Icons.info, 'About Roadly', 'v1.0', () => _showInfoDialog('About', 'Roadly v1.0\nBuilt for the final college project!')),
                    ],
                  ),
                )
                    .animate()
                    .fade(delay: 220.ms, duration: 400.ms)
                    .slideY(delay: 220.ms, duration: 400.ms, begin: 0.06, curve: Curves.easeOutQuad),
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: AppColors.danger, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Sign out',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fade(delay: 300.ms, duration: 400.ms)
                    .slideY(delay: 300.ms, duration: 400.ms, begin: 0.06, curve: Curves.easeOutQuad),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _listItem(IconData icon, String label, [String? meta, VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 12,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.mutedForeground, size: 18),
          ],
        ),
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
