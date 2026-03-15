import 'package:flutter/material.dart';

import '../widgets/admin_ui_kit.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const reports = [
      _ReportItem(
        title: 'Attendance Trend Report',
        summary: 'Compare on-time arrival, absenteeism and weekly consistency.',
        accent: Color(0xFFEAF2FF),
        icon: Icons.show_chart_rounded,
      ),
      _ReportItem(
        title: 'Leave Utilization Report',
        summary: 'Track approvals, pending cases and department leave load.',
        accent: Color(0xFFFFF1E8),
        icon: Icons.event_note_rounded,
      ),
      _ReportItem(
        title: 'Payroll Variance Report',
        summary:
            'Review month-over-month payroll changes, deductions and payouts.',
        accent: Color(0xFFE9F9EF),
        icon: Icons.account_balance_wallet_rounded,
      ),
      _ReportItem(
        title: 'Headcount Overview',
        summary: 'Monitor active, inactive and new hires across departments.',
        accent: Color(0xFFFFECEC),
        icon: Icons.groups_rounded,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AdminColors.text,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Review the core HR reporting modules available to administrators in the portal.',
            style: TextStyle(
              color: Color(0xFF6B7C96),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          ...reports.map(
            (report) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AdminSurfaceCard(
                child: Row(
                  children: [
                    AdminIconBadge(
                      icon: report.icon,
                      iconColor: AdminColors.text,
                      backgroundColor: report.accent,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            style: const TextStyle(
                              color: AdminColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report.summary,
                            style: const TextStyle(
                              color: Color(0xFF6B7C96),
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9AA8BE),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportItem {
  const _ReportItem({
    required this.title,
    required this.summary,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String summary;
  final Color accent;
  final IconData icon;
}
