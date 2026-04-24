import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/report.dart';
import '../providers/app_provider.dart';
import '../widgets/report_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final reports = appProvider.reports;
          final myReports = reports.where((r) => r.byUser).toList();
          final totalPoints = myReports.fold<int>(0, (sum, r) => sum + r.points);
          final verifiedCount = myReports.where((r) => r.status == ReportStatus.verified).length;

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
                  'My Reports',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Everything you\'ve reported so far',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _statCard(myReports.length.toString(), 'Reports'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(totalPoints.toString(), 'Points earned', color: AppColors.accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(verifiedCount.toString(), 'Verified', color: AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (myReports.isEmpty)
                  _emptyState(context)
                else
                  Column(
                    children: myReports.map((r) => ReportCard(report: r)).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String value, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.foreground,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.inbox,
              color: AppColors.mutedForeground,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No reports yet',
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Spot something on the road? Report it to help others and earn points.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 13,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/report'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'New report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
}
