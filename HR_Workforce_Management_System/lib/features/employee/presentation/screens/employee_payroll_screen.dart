import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/payroll_service.dart';
import 'shared/employee_dashboard_constants.dart';

enum _PayrollTabType { currentMonth, taxInfo, documents }

class EmployeePayrollPage extends StatefulWidget {
  const EmployeePayrollPage({super.key, required this.userId});

  final String userId;

  @override
  State<EmployeePayrollPage> createState() => _EmployeePayrollPageState();
}

class _EmployeePayrollPageState extends State<EmployeePayrollPage> {
  _PayrollTabType _activeTab = _PayrollTabType.currentMonth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 108),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PayrollHeader(
            activeTab: _activeTab,
            onTabSelected: (tab) => setState(() => _activeTab = tab),
          ),
          const SizedBox(height: 14),
          if (_activeTab == _PayrollTabType.currentMonth)
            _CurrentMonthTab(userId: widget.userId)
          else if (_activeTab == _PayrollTabType.taxInfo)
            _TaxInfoTab(userId: widget.userId)
          else
            _DocumentsTab(userId: widget.userId),
        ],
      ),
    );
  }
}

class _PayrollHeader extends StatelessWidget {
  const _PayrollHeader({required this.activeTab, required this.onTabSelected});

  final _PayrollTabType activeTab;
  final ValueChanged<_PayrollTabType> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1DF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Payroll & Salary',
                style: GoogleFonts.outfit(
                  color: AppColors.title,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFE8ECF4),
                shape: BoxShape.circle,
              ),
              child: const Center(child: BellIcon()),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _PayrollTab(
              label: 'Current Month',
              active: activeTab == _PayrollTabType.currentMonth,
              onTap: () => onTabSelected(_PayrollTabType.currentMonth),
            ),
            const SizedBox(width: 18),
            _PayrollTab(
              label: 'Tax Info',
              active: activeTab == _PayrollTabType.taxInfo,
              onTap: () => onTabSelected(_PayrollTabType.taxInfo),
            ),
            const SizedBox(width: 18),
            _PayrollTab(
              label: 'Documents',
              active: activeTab == _PayrollTabType.documents,
              onTap: () => onTabSelected(_PayrollTabType.documents),
            ),
          ],
        ),
      ],
    );
  }
}

class _PayrollTab extends StatelessWidget {
  const _PayrollTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.primary : AppColors.muted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 3,
            width: active ? 84 : 0,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentMonthTab extends StatelessWidget {
  const _CurrentMonthTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const _EmptyPayroll(message: 'User session unavailable.');
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: PayrollService.getCurrentMonthPayroll(userId),
      builder: (context, snapshot) {
        final payroll = snapshot.data;
        if (payroll == null) {
          return const _EmptyPayroll(
            message: 'No payroll available for current month.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SalaryCard(payroll: payroll),
            const SizedBox(height: 22),
            _EarningsCard(payroll: payroll),
            const SizedBox(height: 18),
            _DeductionsCard(payroll: payroll),
            const SizedBox(height: 22),
            _PreviousSlipsCard(userId: userId),
          ],
        );
      },
    );
  }
}

class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.payroll});

  final Map<String, dynamic> payroll;

  @override
  Widget build(BuildContext context) {
    final month =
        (payroll['month'] as String?) ??
        DateFormat('MMMM y').format(DateTime.now());
    final net = (payroll['netSalary'] as num?)?.toDouble() ?? 0;
    final bankLast4 = (payroll['bankLast4'] as String?) ?? '----';
    final status = ((payroll['status'] as String?) ?? 'pending').toLowerCase();
    final creditedOnRaw = payroll['creditedOn'];
    final creditedOn = creditedOnRaw is Timestamp
        ? creditedOnRaw.toDate()
        : null;
    final creditedLabel = status == 'paid' && creditedOn != null
        ? DateFormat('dd MMM y').format(creditedOn)
        : 'Processing';
    final slipUrl = (payroll['pdfSlipUrl'] as String?) ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFF48300), Color(0xFFFFA81B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'NET SALARY - ${month.toUpperCase()}',
                  style: const TextStyle(
                    color: Color(0xFFFFEED6),
                    fontSize: 14,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0x32FFFFFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _inr(net),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Credited on: $creditedLabel\nHDFC Bank •••• $bankLast4',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.35,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: slipUrl.isEmpty
                    ? null
                    : () => _openPdf(context, slipUrl),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(120, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.download_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                label: const Text(
                  'PDF Slip',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openPdf(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      showActionMessage(context, 'Invalid payslip URL.');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      showActionMessage(context, 'Could not open payslip URL.');
    }
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.payroll});

  final Map<String, dynamic> payroll;

  @override
  Widget build(BuildContext context) {
    final basic = (payroll['basicSalary'] as num?)?.toDouble() ?? 0;
    final hra = (payroll['hra'] as num?)?.toDouble() ?? 0;
    final conveyance = (payroll['conveyance'] as num?)?.toDouble() ?? 0;
    final gross =
        (payroll['grossSalary'] as num?)?.toDouble() ??
        (basic + hra + conveyance);
    final max = gross == 0 ? 1.0 : gross;

    return Column(
      children: [
        Row(
          children: [
            Text(
              'Earnings Breakdown',
              style: GoogleFonts.outfit(
                color: AppColors.title,
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
            ),
            const Spacer(),
            Text(
              '+ ${_inr(gross)}',
              style: const TextStyle(
                color: Color(0xFF089362),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        BaseCard(
          child: Column(
            children: [
              _EarningRow(
                title: 'Basic Salary',
                amount: _inr(basic),
                progress: basic / max,
                color: const Color(0xFF18B57C),
                icon: Icons.work_rounded,
              ),
              const SizedBox(height: 14),
              _EarningRow(
                title: 'HRA',
                amount: _inr(hra),
                progress: hra / max,
                color: const Color(0xFF2E7BF7),
                icon: Icons.home_rounded,
              ),
              const SizedBox(height: 14),
              _EarningRow(
                title: 'Conveyance',
                amount: _inr(conveyance),
                progress: conveyance / max,
                color: const Color(0xFF9448EA),
                icon: Icons.directions_car_filled_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EarningRow extends StatelessWidget {
  const _EarningRow({
    required this.title,
    required this.amount,
    required this.progress,
    required this.color,
    required this.icon,
  });

  final String title;
  final String amount;
  final double progress;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: AppColors.title,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE8EDF5),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          amount,
          style: GoogleFonts.outfit(
            color: AppColors.title,
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
      ],
    );
  }
}

class _DeductionsCard extends StatelessWidget {
  const _DeductionsCard({required this.payroll});

  final Map<String, dynamic> payroll;

  @override
  Widget build(BuildContext context) {
    final lateDeduction = (payroll['lateDeduction'] as num?)?.toDouble() ?? 0;
    final pf = (payroll['pf'] as num?)?.toDouble() ?? 0;
    final tax = (payroll['professionalTax'] as num?)?.toDouble() ?? 0;
    final total =
        (payroll['totalDeductions'] as num?)?.toDouble() ??
        (lateDeduction + pf + tax);

    return Column(
      children: [
        Row(
          children: [
            Text(
              'Policy Deductions',
              style: GoogleFonts.outfit(
                color: AppColors.title,
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
            ),
            const Spacer(),
            Text(
              '-${_inr(total)}',
              style: const TextStyle(
                color: Color(0xFFE34545),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _DeductionItem(
          title: 'Late Arrival Deduction',
          subtitle: 'Based on monthly late marks',
          amount: '-${_inr(lateDeduction)}',
          icon: Icons.access_time_filled_rounded,
          highlighted: true,
        ),
        const SizedBox(height: 10),
        _DeductionItem(
          title: 'Provident Fund (PF)',
          subtitle: 'Statutory contribution',
          amount: _inr(pf),
          icon: Icons.account_balance_wallet_rounded,
        ),
        const SizedBox(height: 10),
        _DeductionItem(
          title: 'Professional Tax',
          subtitle: 'Monthly statutory deduction',
          amount: _inr(tax),
          icon: Icons.shield_outlined,
        ),
      ],
    );
  }
}

class _DeductionItem extends StatelessWidget {
  const _DeductionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFEFF0) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? const Color(0xFFF4CACF) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: highlighted
                  ? const Color(0xFFFFDCE0)
                  : const Color(0xFFF1F4F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: highlighted
                  ? const Color(0xFFE64156)
                  : const Color(0xFF7D8FA9),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: highlighted
                        ? const Color(0xFF8A121F)
                        : AppColors.title,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: highlighted ? const Color(0xFFE64156) : AppColors.title,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviousSlipsCard extends StatelessWidget {
  const _PreviousSlipsCard({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Previous Slips',
              style: GoogleFonts.outfit(
                color: AppColors.title,
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
            ),
            const Spacer(),
            const Text(
              'Last 6',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: PayrollService.streamPreviousMonths(userId),
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <Map<String, dynamic>>[];
            if (rows.isEmpty) {
              return const BaseCard(
                child: Text(
                  'No previous slips available.',
                  style: TextStyle(color: AppColors.muted),
                ),
              );
            }

            return Column(
              children: List.generate(rows.length, (index) {
                final row = rows[index];
                final month =
                    (row['month'] as String?) ??
                    row['id'] as String? ??
                    'Month';
                final amount = _inr(
                  (row['netSalary'] as num?)?.toDouble() ?? 0,
                );
                final status = ((row['status'] as String?) ?? 'pending')
                    .toUpperCase();
                final url = (row['pdfSlipUrl'] as String?) ?? '';
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == rows.length - 1 ? 0 : 10,
                  ),
                  child: _SlipRow(
                    title: month,
                    amount: amount,
                    status: status,
                    onDownload: url.isEmpty
                        ? null
                        : () => _openPdf(context, url),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openPdf(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      showActionMessage(context, 'Invalid payslip URL.');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      showActionMessage(context, 'Could not open payslip URL.');
    }
  }
}

class _SlipRow extends StatelessWidget {
  const _SlipRow({
    required this.title,
    required this.amount,
    required this.status,
    this.onDownload,
  });

  final String title;
  final String amount;
  final String status;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final paid = status.toLowerCase() == 'paid';
    return BaseCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F9),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFF7B8EA9),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AppColors.title,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      amount,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: AppColors.muted)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: paid
                            ? const Color(0xFFDEF5E7)
                            : const Color(0xFFFFF1DA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: paid
                              ? const Color(0xFF148C59)
                              : const Color(0xFFBD7507),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onDownload,
            borderRadius: BorderRadius.circular(14),
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.download_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxInfoTab extends StatelessWidget {
  const _TaxInfoTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userId.isEmpty
          ? const Stream<List<Map<String, dynamic>>>.empty()
          : PayrollService.streamPreviousMonths(userId, limit: 12),
      builder: (context, snapshot) {
        final months = snapshot.data ?? const <Map<String, dynamic>>[];
        final now = DateTime.now();
        final fyStart = now.month >= 4 ? now.year : now.year - 1;
        final fyLabel = '$fyStart-${(fyStart + 1).toString().substring(2)}';

        double taxableIncome = 0;
        double totalTax = 0;
        for (final m in months) {
          taxableIncome += (m['grossSalary'] as num?)?.toDouble() ?? 0;
          final tds = (m['tds'] as num?)?.toDouble();
          totalTax += tds ?? ((m['professionalTax'] as num?)?.toDouble() ?? 0);
        }

        final regime =
            (months.isNotEmpty ? months.first['taxRegime'] : null) as String?;
        final pan =
            (months.isNotEmpty ? months.first['panNumber'] : null) as String?;
        final resident =
            (months.isNotEmpty ? months.first['residentStatus'] : null)
                as String?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BaseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tax Summary',
                    style: GoogleFonts.outfit(
                      color: AppColors.title,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Financial Year: $fyLabel',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Text('Taxable Income: ${_inr(taxableIncome)}'),
                  Text('Total Tax Deducted: ${_inr(totalTax)}'),
                  Text(
                    'Remaining Tax: ${_inr((months.isNotEmpty ? (months.first['remainingTax'] as num?)?.toDouble() : 0) ?? 0)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            BaseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly TDS Breakdown',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.title,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...months.take(6).map((m) {
                    final label =
                        (m['month'] as String?) ?? (m['id'] as String?) ?? '--';
                    final value =
                        (m['tds'] as num?)?.toDouble() ??
                        ((m['professionalTax'] as num?)?.toDouble() ?? 0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(label)),
                          Text(
                            _inr(value),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            BaseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Tax Regime',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.title,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('✔ ${regime ?? 'New Tax Regime'}'),
                  const SizedBox(height: 10),
                  Text('PAN Number: ${pan ?? 'Not available'}'),
                  Text('Tax Category: Individual'),
                  Text('Resident Status: ${resident ?? 'Resident'}'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DocumentsSection(
          title: 'Salary Slips',
          child: _PreviousSlipsCard(userId: userId),
        ),
        const SizedBox(height: 14),
        const _DocumentsSection(
          title: 'Employment Documents',
          child: _SimpleDocsList(
            labels: ['Offer Letter', 'Employment Contract', 'Promotion Letter'],
          ),
        ),
        const SizedBox(height: 14),
        const _DocumentsSection(
          title: 'Government Documents',
          child: _SimpleDocsList(
            labels: ['PAN Card', 'Aadhar Card', 'Bank Details'],
          ),
        ),
        const SizedBox(height: 14),
        const _DocumentsSection(
          title: 'HR Policy Documents',
          child: _SimpleDocsList(
            labels: [
              'Company Leave Policy',
              'HR Guidelines',
              'Code of Conduct',
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: AppColors.title,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SimpleDocsList extends StatelessWidget {
  const _SimpleDocsList({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: labels
            .map(
              (label) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: Color(0xFF7B8EA9),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(label)),
                    const Icon(
                      Icons.download_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EmptyPayroll extends StatelessWidget {
  const _EmptyPayroll({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.muted, fontSize: 14),
      ),
    );
  }
}

String _inr(double amount) {
  final format = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs',
    decimalDigits: 0,
  );
  return format.format(amount);
}
