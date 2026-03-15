import 'package:flutter/material.dart';

import '../widgets/admin_navigation.dart';
import '../widgets/admin_ui_kit.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key, required this.onSectionSelected});

  final ValueChanged<AdminSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final stats = const [
      _DashboardStat(
        title: 'Total Employees',
        value: '120',
        icon: Icons.people_alt_rounded,
        color: AdminColors.primary,
        tint: AdminColors.softOrange,
      ),
      _DashboardStat(
        title: 'Present Today',
        value: '105',
        icon: Icons.how_to_reg_rounded,
        color: AdminColors.green,
        tint: AdminColors.softGreen,
      ),
      _DashboardStat(
        title: 'On Leave',
        value: '5',
        icon: Icons.event_busy_rounded,
        color: AdminColors.red,
        tint: AdminColors.softRed,
      ),
      _DashboardStat(
        title: 'Late Today',
        value: '10',
        icon: Icons.access_time_filled_rounded,
        color: AdminColors.amber,
        tint: Color(0xFFFFF2E1),
      ),
    ];

    final quickActions = [
      _QuickAction(
        label: 'Add Employee',
        icon: Icons.person_add_alt_1_rounded,
        onTap: () => onSectionSelected(AdminSection.employees),
      ),
      _QuickAction(
        label: 'View Attendance',
        icon: Icons.fact_check_rounded,
        onTap: () => onSectionSelected(AdminSection.dashboard),
      ),
      _QuickAction(
        label: 'Approve Leaves',
        icon: Icons.task_alt_rounded,
        onTap: () => onSectionSelected(AdminSection.leaves),
      ),
      _QuickAction(
        label: 'Payroll',
        icon: Icons.account_balance_wallet_rounded,
        onTap: () => onSectionSelected(AdminSection.payroll),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AdminColors.text,
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            itemCount: stats.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (context, index) => _StatCard(stat: stats[index]),
          ),
          const SizedBox(height: 18),
          AdminSurfaceCard(
            backgroundColor: const Color(0xFFFFF0E8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: [
                const AdminIconBadge(
                  icon: Icons.assignment_late_rounded,
                  iconColor: AdminColors.primary,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    '8 Pending leave requests require your approval',
                    style: TextStyle(
                      color: AdminColors.primary,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onSectionSelected(AdminSection.leaves),
                  child: const Text(
                    'REVIEW',
                    style: TextStyle(
                      color: AdminColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const AdminSectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 14),
          GridView.builder(
            itemCount: quickActions.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) =>
                _QuickActionCard(action: quickActions[index]),
          ),
          const SizedBox(height: 28),
          AdminSectionHeader(
            title: 'Recent Activity',
            actionLabel: 'View All',
            onAction: () => onSectionSelected(AdminSection.employees),
          ),
          const SizedBox(height: 14),
          AdminSurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: const [
                _ActivityTile(
                  icon: Icons.login_rounded,
                  iconColor: Color(0xFF3366FF),
                  iconBackground: Color(0xFFE8F0FF),
                  title: 'John Doe clocked in at 08:55 AM',
                  subtitle: '2 minutes ago',
                ),
                Divider(height: 1, color: AdminColors.border),
                _ActivityTile(
                  icon: Icons.mail_outline_rounded,
                  iconColor: AdminColors.primary,
                  iconBackground: Color(0xFFFFF2E8),
                  title: 'Sarah Smith submitted a new Leave Request',
                  subtitle: '15 minutes ago',
                ),
                Divider(height: 1, color: AdminColors.border),
                _ActivityTile(
                  icon: Icons.logout_rounded,
                  iconColor: Color(0xFFFF4D4F),
                  iconBackground: Color(0xFFFFEDEE),
                  title: 'Mike Johnson clocked out early 11:30 AM',
                  subtitle: '1 hour ago',
                ),
                Divider(height: 1, color: AdminColors.border),
                _ActivityTile(
                  icon: Icons.verified_rounded,
                  iconColor: Color(0xFF16A34A),
                  iconBackground: Color(0xFFE6FBEA),
                  title: 'Payroll Batch #1023 was successfully processed',
                  subtitle: '3 hours ago',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStat {
  const _DashboardStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.tint,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color tint;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _DashboardStat stat;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminIconBadge(
                icon: stat.icon,
                iconColor: stat.color,
                backgroundColor: stat.tint,
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stat.title,
                  style: const TextStyle(
                    color: Color(0xFF566C8D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            stat.value,
            style: const TextStyle(
              color: AdminColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      onTap: action.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AdminIconBadge(
            icon: action.icon,
            iconColor: AdminColors.primary,
            backgroundColor: const Color(0xFFFFF0E8),
            size: 58,
          ),
          const SizedBox(height: 16),
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AdminColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminIconBadge(
            icon: icon,
            iconColor: iconColor,
            backgroundColor: iconBackground,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
