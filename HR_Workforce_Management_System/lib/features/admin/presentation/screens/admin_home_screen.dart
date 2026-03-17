import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/admin_dashboard_service.dart';
import '../widgets/admin_navigation.dart';
import '../widgets/admin_ui_kit.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, required this.onSectionSelected});

  final ValueChanged<AdminSection> onSectionSelected;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<AdminDashboardMetrics> _metricsFuture;

  @override
  void initState() {
    super.initState();
    _metricsFuture = AdminDashboardService.getDashboardMetrics();
  }

  Future<void> _refresh() async {
    setState(() {
      _metricsFuture = AdminDashboardService.getDashboardMetrics();
    });
    await _metricsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      _QuickAction(
        label: 'Add Employee',
        icon: Icons.person_add_alt_1_rounded,
        onTap: () => widget.onSectionSelected(AdminSection.employees),
      ),
      _QuickAction(
        label: 'View Attendance',
        icon: Icons.fact_check_rounded,
        onTap: () => widget.onSectionSelected(AdminSection.dashboard),
      ),
      _QuickAction(
        label: 'Approve Leaves',
        icon: Icons.task_alt_rounded,
        onTap: () => widget.onSectionSelected(AdminSection.leaves),
      ),
      _QuickAction(
        label: 'Payroll',
        icon: Icons.account_balance_wallet_rounded,
        onTap: () => widget.onSectionSelected(AdminSection.payroll),
      ),
    ];

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
            FutureBuilder<AdminDashboardMetrics>(
              future: _metricsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _GridLoader();
                }

                if (snapshot.hasError) {
                  return _InlineError(
                    message: 'Failed to load dashboard stats.',
                    onRetry: _refresh,
                  );
                }

                final metrics =
                    snapshot.data ??
                    const AdminDashboardMetrics(
                      totalEmployees: 0,
                      presentToday: 0,
                      onLeaveToday: 0,
                      lateToday: 0,
                    );

                final stats = [
                  _DashboardStat(
                    title: 'Total Employees',
                    value: metrics.totalEmployees.toString(),
                    icon: Icons.people_alt_rounded,
                    color: AdminColors.primary,
                    tint: AdminColors.softOrange,
                  ),
                  _DashboardStat(
                    title: 'Present Today',
                    value: metrics.presentToday.toString(),
                    icon: Icons.how_to_reg_rounded,
                    color: AdminColors.green,
                    tint: AdminColors.softGreen,
                  ),
                  _DashboardStat(
                    title: 'On Leave',
                    value: metrics.onLeaveToday.toString(),
                    icon: Icons.event_busy_rounded,
                    color: AdminColors.red,
                    tint: AdminColors.softRed,
                  ),
                  _DashboardStat(
                    title: 'Late Today',
                    value: metrics.lateToday.toString(),
                    icon: Icons.access_time_filled_rounded,
                    color: AdminColors.amber,
                    tint: const Color(0xFFFFF2E1),
                  ),
                ];

                return GridView.builder(
                  itemCount: stats.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.08,
                  ),
                  itemBuilder: (context, index) =>
                      _StatCard(stat: stats[index]),
                );
              },
            ),
            const SizedBox(height: 18),
            StreamBuilder<int>(
              stream: AdminDashboardService.streamPendingLeaveCount(),
              builder: (context, snapshot) {
                final pending = snapshot.data ?? 0;
                if (pending <= 0) {
                  return const SizedBox.shrink();
                }
                return AdminSurfaceCard(
                  backgroundColor: const Color(0xFFFFF0E8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      const AdminIconBadge(
                        icon: Icons.assignment_late_rounded,
                        iconColor: AdminColors.primary,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          '$pending Pending leave requests require your approval',
                          style: const TextStyle(
                            color: AdminColors.primary,
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            widget.onSectionSelected(AdminSection.leaves),
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
                );
              },
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
              actionLabel: 'View Leaves',
              onAction: () => widget.onSectionSelected(AdminSection.leaves),
            ),
            const SizedBox(height: 14),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: AdminDashboardService.streamRecentActivity(limit: 10),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _InlineError(
                    message: 'Failed to load recent activity.',
                  );
                }

                if (!snapshot.hasData) {
                  return const _ActivityLoader();
                }

                final activities = snapshot.data ?? const [];
                if (activities.isEmpty) {
                  return const AdminSurfaceCard(
                    child: Text(
                      'No recent activity yet.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return AdminSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: List.generate(activities.length, (index) {
                      final activity = activities[index];
                      final iconMeta = _iconForType(
                        (activity['type'] as String?)?.toLowerCase() ?? '',
                      );

                      final tile = _ActivityTile(
                        icon: iconMeta.icon,
                        iconColor: iconMeta.iconColor,
                        iconBackground: iconMeta.backgroundColor,
                        title:
                            (activity['message'] as String?) ??
                            'Activity updated',
                        subtitle: _formatRelativeTime(activity['timestamp']),
                      );

                      if (index == activities.length - 1) {
                        return tile;
                      }

                      return Column(
                        children: [
                          tile,
                          const Divider(height: 1, color: AdminColors.border),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  _ActivityIconMeta _iconForType(String type) {
    switch (type) {
      case 'clockin':
        return const _ActivityIconMeta(
          icon: Icons.login_rounded,
          iconColor: Color(0xFF3366FF),
          backgroundColor: Color(0xFFE8F0FF),
        );
      case 'clockout':
        return const _ActivityIconMeta(
          icon: Icons.logout_rounded,
          iconColor: Color(0xFFFF4D4F),
          backgroundColor: Color(0xFFFFEDEE),
        );
      case 'leave':
        return const _ActivityIconMeta(
          icon: Icons.event_note_rounded,
          iconColor: AdminColors.primary,
          backgroundColor: Color(0xFFFFF2E8),
        );
      case 'payroll':
        return const _ActivityIconMeta(
          icon: Icons.verified_rounded,
          iconColor: Color(0xFF16A34A),
          backgroundColor: Color(0xFFE6FBEA),
        );
      default:
        return const _ActivityIconMeta(
          icon: Icons.notifications_active_rounded,
          iconColor: Color(0xFF6B7280),
          backgroundColor: Color(0xFFF3F4F6),
        );
    }
  }

  String _formatRelativeTime(dynamic rawTimestamp) {
    if (rawTimestamp is! Timestamp) {
      return 'Just now';
    }
    final date = rawTimestamp.toDate();
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('dd MMM, hh:mm a').format(date);
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

class _ActivityIconMeta {
  const _ActivityIconMeta({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
}

class _GridLoader extends StatelessWidget {
  const _GridLoader();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, _) => const AdminSurfaceCard(
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ActivityLoader extends StatelessWidget {
  const _ActivityLoader();

  @override
  Widget build(BuildContext context) {
    return const AdminSurfaceCard(
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF991B1B),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => onRetry!.call(),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
