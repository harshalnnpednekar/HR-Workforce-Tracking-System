import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../widgets/admin_ui_kit.dart';
import '../../../../core/services/admin_report_service.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  Future<void> _selectMonthAndGenerate(BuildContext context, String title, Function(DateTime) onGenerate) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'SELECT MONTH FOR ${title.toUpperCase()}',
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...'), duration: Duration(seconds: 2)),
      );

      try {
        final pdfBytes = await onGenerate(picked);
        if (!context.mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Report Generated: $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: const Text('Choose how you want to handle the generated PDF report.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Printing.layoutPdf(onLayout: (_) => pdfBytes, name: '$title.pdf');
                },
                child: const Text('PREVIEW', style: TextStyle(color: AdminColors.primary)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Printing.sharePdf(bytes: pdfBytes, filename: '$title.pdf');
                },
                child: const Text('SHARE / DOWNLOAD', style: TextStyle(color: AdminColors.primary)),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateHeadcount(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating Headcount Report...')),
    );
    try {
      final pdfBytes = await AdminReportService.generateHeadcountOverviewReport();
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Headcount Report Generated', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: const Text('Choose an action for the headcount overview.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Printing.layoutPdf(onLayout: (_) => pdfBytes, name: 'Headcount_Report.pdf');
              },
              child: const Text('PREVIEW', style: TextStyle(color: AdminColors.primary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Printing.sharePdf(bytes: pdfBytes, filename: 'Headcount_Report.pdf');
              },
              child: const Text('SHARE / DOWNLOAD', style: TextStyle(color: AdminColors.primary)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = [
      _ReportItem(
        title: 'Attendance Trend Report',
        summary: 'Compare on-time arrival, absenteeism and weekly consistency.',
        accent: const Color(0xFFEAF2FF),
        icon: Icons.show_chart_rounded,
        onTap: () => _selectMonthAndGenerate(
          context,
          'Attendance Trend',
          (date) => AdminReportService.generateAttendanceTrendReport(date),
        ),
      ),
      _ReportItem(
        title: 'Leave Utilization Report',
        summary: 'Track approvals, pending cases and department leave load.',
        accent: const Color(0xFFFFF1E8),
        icon: Icons.event_note_rounded,
        onTap: () => _selectMonthAndGenerate(
          context,
          'Leave Utilization',
          (date) => AdminReportService.generateLeaveUtilizationReport(date),
        ),
      ),
      _ReportItem(
        title: 'Payroll Variance Report',
        summary: 'Review month-over-month payroll changes, deductions and payouts.',
        accent: const Color(0xFFE9F9EF),
        icon: Icons.account_balance_wallet_rounded,
        onTap: () => _selectMonthAndGenerate(
          context,
          'Payroll Variance',
          (date) => AdminReportService.generatePayrollVarianceReport(date),
        ),
      ),
      _ReportItem(
        title: 'Headcount Overview',
        summary: 'Monitor active, inactive and new hires across departments.',
        accent: const Color(0xFFFFECEC),
        icon: Icons.groups_rounded,
        onTap: () => _generateHeadcount(context),
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
                onTap: report.onTap,
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
    required this.onTap,
  });

  final String title;
  final String summary;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;
}
