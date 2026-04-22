import 'package:flutter/material.dart';
import '../widgets/admin_ui_kit.dart';
import '../../../../core/services/admin_report_service.dart';
import '../../../../core/services/pdf_open_service.dart';

class AdminHrPolicyScreen extends StatelessWidget {
  const AdminHrPolicyScreen({super.key});

  Future<void> _generatePolicyPdf(
    BuildContext context,
    String title,
    String summary,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preparing $title...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final pdfBytes = await AdminReportService.generateHrPolicyPdf(
        title,
        summary,
      );
      if (!context.mounted) return;

      await PdfOpenService.openPdfBytes(
        pdfBytes,
        fileName: '${title.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const policies = [
      _PolicyItem(
        title: 'Leave Entitlement Policy',
        summary: 'Annual, sick and parental leave allocations for all staff.',
        updatedAt: 'Updated 4 days ago',
      ),
      _PolicyItem(
        title: 'Attendance and Punctuality',
        summary: 'Working hours, grace period, attendance review workflow.',
        updatedAt: 'Updated 1 week ago',
      ),
      _PolicyItem(
        title: 'Remote Work Guidelines',
        summary:
            'Eligibility, approval process and equipment responsibilities.',
        updatedAt: 'Updated 2 weeks ago',
      ),
      _PolicyItem(
        title: 'Code of Conduct',
        summary:
            'Behavior, grievance escalation and workplace conduct standards.',
        updatedAt: 'Updated 3 weeks ago',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HR Rules & Policy',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AdminColors.text,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Centralize policies that HR admins need to review, publish and share across the workforce.',
            style: TextStyle(
              color: Color(0xFF6B7C96),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          ...policies.map(
            (policy) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AdminSurfaceCard(
                onTap: () =>
                    _generatePolicyPdf(context, policy.title, policy.summary),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminIconBadge(
                      icon: Icons.description_rounded,
                      iconColor: AdminColors.primary,
                      backgroundColor: AdminColors.softOrange,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            policy.title,
                            style: const TextStyle(
                              color: AdminColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            policy.summary,
                            style: const TextStyle(
                              color: Color(0xFF6B7C96),
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            policy.updatedAt,
                            style: const TextStyle(
                              color: Color(0xFF9AA8BE),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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

class _PolicyItem {
  const _PolicyItem({
    required this.title,
    required this.summary,
    required this.updatedAt,
  });

  final String title;
  final String summary;
  final String updatedAt;
}
