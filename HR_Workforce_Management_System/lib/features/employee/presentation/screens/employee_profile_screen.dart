import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared/employee_dashboard_constants.dart';

class EmployeeProfilePage extends StatelessWidget {
  const EmployeeProfilePage({
    required this.fullName,
    required this.onLogoutRequested,
  });

  final String fullName;
  final VoidCallback onLogoutRequested;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 108),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ProfileHeaderBar(),
          const SizedBox(height: 16),
          const _ProfileAvatar(),
          const SizedBox(height: 10),
          Center(
            child: Text(
              fullName,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.title,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'SOFTWARE DEVELOPER | EQT102',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 25,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Column(
              children: [
                _ContactRow(
                  icon: Icons.email_rounded,
                  value: 'ali@equitec.com',
                ),
                SizedBox(height: 6),
                _ContactRow(icon: Icons.phone_rounded, value: '+91 9876543210'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: _ProfileStatCardTasks()),
              SizedBox(width: 14),
              Expanded(child: _ProfileStatCardHours()),
            ],
          ),
          const SizedBox(height: 16),
          const _ProfileSummarySection(),
          const SizedBox(height: 16),
          const _WorkInfoCard(),
          const SizedBox(height: 16),
          const _DocumentsPayrollActions(),
          const SizedBox(height: 16),
          _SettingsList(onLogoutTap: onLogoutRequested),
        ],
      ),
    );
  }
}

class _ProfileHeaderBar extends StatelessWidget {
  const _ProfileHeaderBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.arrow_back_rounded, color: AppColors.title, size: 35),
        const Spacer(),
        Text(
          'My Profile',
          style: GoogleFonts.outfit(
            color: AppColors.title,
            fontWeight: FontWeight.w700,
            fontSize: 26,
          ),
        ),
        const Spacer(),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.edit_rounded, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 72,
            backgroundColor: const Color(0xFFE6D6BE),
            child: Text(
              'A',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: AppColors.title,
                fontSize: 28,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: 8,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.settings, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF7E8EA7), size: 22),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ProfileStatCardTasks extends StatelessWidget {
  const _ProfileStatCardTasks();

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.task_alt_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'TASKS',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '24',
                  style: GoogleFonts.outfit(
                    color: AppColors.title,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
                const TextSpan(
                  text: ' Done',
                  style: TextStyle(color: AppColors.muted, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.92,
              minHeight: 6,
              backgroundColor: Color(0xFFE8EDF5),
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '92% Completion Rate',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCardHours extends StatelessWidget {
  const _ProfileStatCardHours();

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.watch_later_rounded, color: Color(0xFF3A7CE3)),
              SizedBox(width: 8),
              Text(
                'HOURS',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '142',
                  style: GoogleFonts.outfit(
                    color: AppColors.title,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
                const TextSpan(
                  text: ' Hrs',
                  style: TextStyle(color: AppColors.muted, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "This Month's Total",
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummarySection extends StatelessWidget {
  const _ProfileSummarySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUMMARY',
          style: TextStyle(
            color: AppColors.muted,
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(
              child: _SummaryChip(
                value: '18',
                label: 'PRESENT',
                color: Color(0xFF18A55E),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _SummaryChip(
                value: '2',
                label: 'LATE',
                color: Color(0xFFF59A00),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _SummaryChip(
                value: '1',
                label: 'ABSENT',
                color: Color(0xFFE43A46),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _SummaryChip(
                value: '7',
                label: 'LEAVES',
                color: AppColors.primary,
                highlighted: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(
              child: _SmallLeavePill(
                title: 'CASUAL',
                value: '5 Left',
                icon: Icons.calendar_today_rounded,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _SmallLeavePill(
                title: 'SICK',
                value: '2 Left',
                icon: Icons.medical_services_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.value,
    required this.label,
    required this.color,
    this.highlighted = false,
  });

  final String value;
  final String label;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFF3E5) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallLeavePill extends StatelessWidget {
  const _SmallLeavePill({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: AppColors.title,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: const Color(0xFFB8C3D6)),
        ],
      ),
    );
  }
}

class _WorkInfoCard extends StatelessWidget {
  const _WorkInfoCard();

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Work Information',
                style: GoogleFonts.outfit(
                  color: AppColors.title,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _WorkLine(
            label: 'Joining Date',
            value: '10 Jan 2024',
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(height: 10),
          const _WorkLine(
            label: 'Manager',
            value: 'Sushant Patil',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 10),
          const _WorkLine(
            label: 'Location',
            value: 'Mumbai Office',
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: _WorkLine(
                  label: 'Type',
                  value: '',
                  icon: Icons.badge_rounded,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF6E7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'FULL-TIME',
                  style: TextStyle(
                    color: Color(0xFF1A9B66),
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

class _WorkLine extends StatelessWidget {
  const _WorkLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF9AABC1), size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 20),
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: const TextStyle(
              color: AppColors.title,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _DocumentsPayrollActions extends StatelessWidget {
  const _DocumentsPayrollActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DOCUMENTS & PAYROLL',
          style: TextStyle(
            color: AppColors.muted,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showActionMessage(
                  context,
                  'Opening salary slip preview...',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.visibility_rounded,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Salary Slip',
                  style: TextStyle(
                    color: AppColors.title,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    showActionMessage(context, 'Payslip download started.'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: const Text(
                  'Payslip',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.onLogoutTap});

  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SETTINGS',
          style: TextStyle(
            color: AppColors.muted,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        BaseCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const _SettingRow(
                icon: Icons.lock_rounded,
                label: 'Change Password',
              ),
              const Divider(height: 1, color: AppColors.cardBorder),
              const _SettingRow(
                icon: Icons.notifications_rounded,
                label: 'Notifications',
              ),
              const Divider(height: 1, color: AppColors.cardBorder),
              _SettingRow(
                icon: Icons.logout_rounded,
                label: 'Logout',
                danger: true,
                onTap: onLogoutTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => showActionMessage(context, '$label tapped.'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: danger
                    ? const Color(0xFFFFEEF0)
                    : const Color(0xFFF0F4FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: danger
                    ? const Color(0xFFE5394F)
                    : const Color(0xFF798CA8),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: danger ? const Color(0xFFE5394F) : AppColors.title,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!danger)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFA2AFC2)),
          ],
        ),
      ),
    );
  }
}
