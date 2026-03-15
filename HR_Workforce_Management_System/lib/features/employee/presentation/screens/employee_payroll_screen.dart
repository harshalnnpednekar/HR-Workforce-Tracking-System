import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared/employee_dashboard_constants.dart';

class EmployeePayrollPage extends StatelessWidget {
  const EmployeePayrollPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 108),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PayrollHeader(),
          SizedBox(height: 12),
          _SalaryCard(),
          SizedBox(height: 22),
          _EarningsCard(),
          SizedBox(height: 18),
          _DeductionsCard(),
          SizedBox(height: 22),
          _PreviousSlipsCard(),
        ],
      ),
    );
  }
}

class _PayrollHeader extends StatelessWidget {
  const _PayrollHeader();

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
                Icons.arrow_back_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Payroll & Salary',
              style: GoogleFonts.outfit(
                color: AppColors.title,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const Spacer(),
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
        const Row(
          children: [
            _PayrollTab(label: 'Current Month', active: true),
            SizedBox(width: 18),
            _PayrollTab(label: 'Tax Info'),
            SizedBox(width: 18),
            _PayrollTab(label: 'Documents'),
          ],
        ),
      ],
    );
  }
}

class _PayrollTab extends StatelessWidget {
  const _PayrollTab({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _SalaryCard extends StatelessWidget {
  const _SalaryCard();

  @override
  Widget build(BuildContext context) {
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
              const Expanded(
                child: Text(
                  'NET SALARY - AUGUST 2023',
                  style: TextStyle(
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
            'Rs68,500.00',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Credited on: 31st Aug\nHDFC Bank •••• 4291',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.35,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    showActionMessage(context, 'Downloading payroll PDF...'),
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
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard();

  @override
  Widget build(BuildContext context) {
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
            const Text(
              '+ Rs72,000',
              style: TextStyle(
                color: Color(0xFF089362),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const BaseCard(
          child: Column(
            children: [
              _EarningRow(
                title: 'Basic Salary',
                amount: 'Rs45,000',
                progress: 0.85,
                color: Color(0xFF18B57C),
                icon: Icons.work_rounded,
              ),
              SizedBox(height: 14),
              _EarningRow(
                title: 'HRA',
                amount: 'Rs18,000',
                progress: 0.6,
                color: Color(0xFF2E7BF7),
                icon: Icons.home_rounded,
              ),
              SizedBox(height: 14),
              _EarningRow(
                title: 'Conveyance',
                amount: 'Rs9,000',
                progress: 0.4,
                color: Color(0xFF9448EA),
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
            color: color.withOpacity(0.12),
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
                  value: progress,
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
  const _DeductionsCard();

  @override
  Widget build(BuildContext context) {
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
            const Text(
              '-Rs3,500',
              style: TextStyle(
                color: Color(0xFFE34545),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _DeductionItem(
          title: 'Late Arrival Deduction',
          subtitle: '3 late marks beyond buffer time',
          amount: '-Rs500',
          icon: Icons.access_time_filled_rounded,
          highlighted: true,
        ),
        const SizedBox(height: 10),
        const _DeductionItem(
          title: 'Provident Fund (PF)',
          subtitle: 'Standard 12% contribution',
          amount: 'Rs2,800',
          icon: Icons.account_balance_wallet_rounded,
        ),
        const SizedBox(height: 10),
        const _DeductionItem(
          title: 'Professional Tax',
          subtitle: 'Monthly statutory deduction',
          amount: 'Rs200',
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
              fontSize: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviousSlipsCard extends StatelessWidget {
  const _PreviousSlipsCard();

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
              'View All',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _SlipRow(title: 'July 2023', amount: 'Rs69,000', status: 'PAID'),
        const SizedBox(height: 10),
        const _SlipRow(title: 'June 2023', amount: 'Rs68,500', status: 'PAID'),
      ],
    );
  }
}

class _SlipRow extends StatelessWidget {
  const _SlipRow({
    required this.title,
    required this.amount,
    required this.status,
  });

  final String title;
  final String amount;
  final String status;

  @override
  Widget build(BuildContext context) {
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
                        color: const Color(0xFFDEF5E7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Color(0xFF148C59),
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
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.download_rounded, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }
}
