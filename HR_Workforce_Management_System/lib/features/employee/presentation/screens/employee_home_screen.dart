import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared/employee_dashboard_constants.dart';

class EmployeeHomePage extends StatelessWidget {
  const EmployeeHomePage({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 108),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HomeHeader(),
          const SizedBox(height: 22),
          Text(
            'Good Morning, $name',
            style: GoogleFonts.outfit(
              color: AppColors.title,
              fontWeight: FontWeight.w700,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: AppColors.muted),
              SizedBox(width: 8),
              Text(
                'Monday, Oct 23, 2023',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _WeeklyHoursCard(),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: _MiniMetricCard(
                  icon: Icons.beach_access_rounded,
                  title: 'REM.',
                  subtitle: 'Leave Balance',
                  value: '14 Days',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _MiniMetricCard(
                  icon: Icons.warning_amber_rounded,
                  title: '',
                  subtitle: 'Late Marks',
                  value: '1',
                  alert: '-1',
                  iconColor: Color(0xFFE66021),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Quick Actions',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  label: 'CLOCK IN',
                  icon: Icons.fingerprint_rounded,
                  active: true,
                  onTap: () => showActionMessage(context, 'Clock in captured.'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _QuickAction(
                  label: 'LEAVE',
                  icon: Icons.event_note_rounded,
                  onTap: () => showActionMessage(
                    context,
                    'Open leave request form from Leaves tab.',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _QuickAction(
                  label: 'PAYSLIP',
                  icon: Icons.payments_outlined,
                  onTap: () => showActionMessage(
                    context,
                    'Payslip download action triggered.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.title,
                ),
              ),
              TextButton(
                onPressed: () =>
                    showActionMessage(context, 'Showing all activities soon.'),
                child: const Text(
                  'VIEW ALL',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _RecentActivityCard(),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.business_outlined,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'myHR',
          style: GoogleFonts.outfit(
            color: AppColors.primary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        const BellIcon(),
        const SizedBox(width: 14),
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFDDD2BF),
          child: Text(
            'A',
            style: GoogleFonts.outfit(
              color: AppColors.title,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyHoursCard extends StatelessWidget {
  const _WeeklyHoursCard();

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFFFFF1DF),
            ),
            child: const Icon(
              Icons.access_time_filled,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WEEKLY HOURS',
                  style: TextStyle(
                    color: AppColors.muted,
                    letterSpacing: 1.6,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '38h 20m',
                  style: GoogleFonts.outfit(
                    color: AppColors.title,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFDFF3EA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              '+2h',
              style: TextStyle(
                color: Color(0xFF159A67),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.alert,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String? alert;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1DF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const Spacer(),
              if (alert != null)
                Text(
                  alert!,
                  style: const TextStyle(
                    color: Color(0xFFFF8E68),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              color: AppColors.title,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    this.active = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          height: 134,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.cardBorder,
            ),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x2CF48300),
                      blurRadius: 20,
                      offset: Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 34,
                color: active ? Colors.white : AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF344966),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: const [
          _RecentItem(
            icon: Icons.login_rounded,
            title: 'Clock In Successful',
            subtitle: 'Office Location • Today',
            time: '09:02 AM',
            iconBg: Color(0xFFDEEFE7),
            iconColor: Color(0xFF2E9D6D),
          ),
          Divider(height: 1, color: AppColors.cardBorder),
          _RecentItem(
            icon: Icons.logout_rounded,
            title: 'Clock Out Successful',
            subtitle: 'Remote • Yesterday',
            time: '06:15 PM',
            iconBg: Color(0xFFF0F2F6),
            iconColor: Color(0xFF516683),
          ),
          Divider(height: 1, color: AppColors.cardBorder),
          _RecentItem(
            icon: Icons.login_rounded,
            title: 'Clock In Successful',
            subtitle: 'Remote • Yesterday',
            time: '08:58 AM',
            iconBg: Color(0xFFF0F2F6),
            iconColor: Color(0xFF516683),
          ),
        ],
      ),
    );
  }
}

class _RecentItem extends StatelessWidget {
  const _RecentItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.iconBg,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AppColors.title,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.outfit(
              color: AppColors.title,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}
