import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/attendance_service.dart';
import '../../../../core/services/user_service.dart';
import 'shared/employee_dashboard_constants.dart';

class EmployeeHomePage extends StatefulWidget {
  const EmployeeHomePage({
    super.key,
    required this.name,
    required this.userId,
    this.onOpenLeaves,
    this.onOpenPayroll,
  });

  final String name;
  final String userId;
  final VoidCallback? onOpenLeaves;
  final VoidCallback? onOpenPayroll;

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  late Future<Map<String, dynamic>?> _userFuture;
  late Future<double> _weeklyHoursFuture;
  late Future<int> _lateMarksFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSnapshotFutures();
  }

  void _loadSnapshotFutures() {
    if (widget.userId.isEmpty) {
      _userFuture = Future.value(null);
      _weeklyHoursFuture = Future.value(0);
      _lateMarksFuture = Future.value(0);
      return;
    }

    _userFuture = UserService.getUser(widget.userId);
    _weeklyHoursFuture = AttendanceService.getWeeklyHours(widget.userId);
    _lateMarksFuture = AttendanceService.getMonthlyLateMarks(widget.userId);
  }

  Future<void> _onClockAction(_ClockButtonState state) async {
    if (_busy || state == _ClockButtonState.done) return;
    if (widget.userId.isEmpty) {
      showActionMessage(
        context,
        'User session unavailable. Please login again.',
      );
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      if (state == _ClockButtonState.clockIn) {
        final time = await AttendanceService.clockIn(widget.userId);
        if (!mounted) return;
        showActionMessage(
          context,
          'Clock-in successful - ${DateFormat('hh:mm a').format(time)}',
        );
      } else {
        final time = await AttendanceService.clockOut(widget.userId);
        if (!mounted) return;
        showActionMessage(
          context,
          'Clock-out successful - ${DateFormat('hh:mm a').format(time)}',
        );
      }

      setState(_loadSnapshotFutures);
    } on Exception catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      showActionMessage(context, message);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEEE, MMM d, y').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 108),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeHeader(userId: widget.userId),
          const SizedBox(height: 22),
          FutureBuilder<Map<String, dynamic>?>(
            future: _userFuture,
            builder: (context, snapshot) {
              final dbName = (snapshot.data?['name'] as String?)?.trim();
              final displayName = dbName == null || dbName.isEmpty
                  ? widget.name
                  : dbName;
              return Text(
                'Good Morning, $displayName',
                style: GoogleFonts.outfit(
                  color: AppColors.title,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: AppColors.muted),
              const SizedBox(width: 8),
              Text(
                dateText,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          FutureBuilder<double>(
            future: _weeklyHoursFuture,
            builder: (context, snapshot) {
              final hours = snapshot.data ?? 0;
              return _WeeklyHoursCard(hours: hours);
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _userFuture,
                  builder: (context, snapshot) {
                    final leaveTotal = _leaveBalance(snapshot.data);
                    return _MiniMetricCard(
                      icon: Icons.beach_access_rounded,
                      title: 'REM.',
                      subtitle: 'Leave Balance',
                      value: '$leaveTotal Days',
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FutureBuilder<int>(
                  future: _lateMarksFuture,
                  builder: (context, snapshot) {
                    final marks = snapshot.data ?? 0;
                    return _MiniMetricCard(
                      icon: Icons.warning_amber_rounded,
                      title: '',
                      subtitle: 'Late Marks',
                      value: '$marks',
                      alert: marks > 0 ? '-$marks' : null,
                      iconColor: const Color(0xFFE66021),
                    );
                  },
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
                child: StreamBuilder<Map<String, dynamic>?>(
                  stream: widget.userId.isEmpty
                      ? Stream<Map<String, dynamic>?>.value(null)
                      : AttendanceService.streamTodayAttendance(widget.userId),
                  builder: (context, snapshot) {
                    final state = _clockButtonState(snapshot.data);
                    final button = _clockButtonStyle(state);
                    return _QuickAction(
                      label: button.label,
                      icon: button.icon,
                      background: button.background,
                      foreground: button.foreground,
                      enabled: !_busy && state != _ClockButtonState.done,
                      onTap: () => _onClockAction(state),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _QuickAction(
                  label: 'LEAVE',
                  icon: Icons.event_note_rounded,
                  onTap: widget.onOpenLeaves,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _QuickAction(
                  label: 'PAYSLIP',
                  icon: Icons.payments_outlined,
                  onTap: widget.onOpenPayroll,
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
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.userId.isEmpty
                ? Stream<List<Map<String, dynamic>>>.value(const [])
                : AttendanceService.streamRecentRecords(widget.userId),
            builder: (context, snapshot) {
              return _RecentActivityCard(records: snapshot.data ?? const []);
            },
          ),
        ],
      ),
    );
  }

  int _leaveBalance(Map<String, dynamic>? user) {
    final casual = (user?['casualLeave'] as num?)?.toInt() ?? 0;
    final sick = (user?['sickLeave'] as num?)?.toInt() ?? 0;
    final earned = (user?['earnedLeave'] as num?)?.toInt() ?? 0;
    return casual + sick + earned;
  }

  _ClockButtonState _clockButtonState(Map<String, dynamic>? record) {
    if (record == null || record['clockIn'] == null) {
      return _ClockButtonState.clockIn;
    }
    if (record['clockOut'] == null) {
      return _ClockButtonState.clockOut;
    }
    return _ClockButtonState.done;
  }

  _QuickActionStyle _clockButtonStyle(_ClockButtonState state) {
    switch (state) {
      case _ClockButtonState.clockIn:
        return const _QuickActionStyle(
          label: 'CLOCK IN',
          icon: Icons.fingerprint_rounded,
          background: AppColors.primary,
          foreground: Colors.white,
        );
      case _ClockButtonState.clockOut:
        return const _QuickActionStyle(
          label: 'CLOCK OUT',
          icon: Icons.logout_rounded,
          background: Color(0xFFF6E3DF),
          foreground: Color(0xFFB7401C),
        );
      case _ClockButtonState.done:
        return const _QuickActionStyle(
          label: 'DONE TODAY',
          icon: Icons.check_circle_outline_rounded,
          background: Color(0xFFE9EDF3),
          foreground: Color(0xFF6A7B95),
        );
    }
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.userId});

  final String userId;

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
        BellIcon(userId: userId),
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
  const _WeeklyHoursCard({required this.hours});

  final double hours;

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
                  _formatHours(hours),
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
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              '7D',
              style: TextStyle(
                color: Color(0xFF2A5FA8),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(double totalHours) {
    final wholeHours = totalHours.floor();
    final minutes = ((totalHours - wholeHours) * 60).round();
    if (minutes == 60) {
      return '${wholeHours + 1}h 0m';
    }
    return '${wholeHours}h ${minutes}m';
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
    this.background = Colors.white,
    this.foreground = AppColors.primary,
    this.enabled = true,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 134,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: enabled ? foreground.withAlpha(128) : AppColors.cardBorder,
            ),
            boxShadow: background == AppColors.primary
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
                color: enabled ? foreground : const Color(0xFF9DA9BD),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? foreground : const Color(0xFF7A879C),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  fontSize: 14,
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
  const _RecentActivityCard({required this.records});

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries(records).take(5).toList();

    return BaseCard(
      padding: EdgeInsets.zero,
      child: entries.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No recent activity yet.',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            )
          : Column(
              children: List.generate(entries.length, (index) {
                final entry = entries[index];
                return Column(
                  children: [
                    _RecentItem(
                      icon: entry.icon,
                      title: entry.title,
                      subtitle: entry.subtitle,
                      time: DateFormat('hh:mm a').format(entry.time),
                      iconBg: entry.iconBg,
                      iconColor: entry.iconColor,
                    ),
                    if (index < entries.length - 1)
                      const Divider(height: 1, color: AppColors.cardBorder),
                  ],
                );
              }),
            ),
    );
  }

  List<_ActivityEntry> _buildEntries(List<Map<String, dynamic>> raw) {
    final out = <_ActivityEntry>[];
    for (final row in raw) {
      final date = _friendlyDate((row['date'] as String?) ?? '');
      final clockIn = row['clockIn'];
      final clockOut = row['clockOut'];

      if (clockIn is Timestamp) {
        out.add(
          _ActivityEntry(
            title: 'Clock In Successful',
            subtitle: date,
            time: clockIn.toDate(),
            icon: Icons.login_rounded,
            iconBg: const Color(0xFFDEEFE7),
            iconColor: const Color(0xFF2E9D6D),
          ),
        );
      }
      if (clockOut is Timestamp) {
        out.add(
          _ActivityEntry(
            title: 'Clock Out Successful',
            subtitle: date,
            time: clockOut.toDate(),
            icon: Icons.logout_rounded,
            iconBg: const Color(0xFFF0F2F6),
            iconColor: const Color(0xFF516683),
          ),
        );
      }
    }

    out.sort((a, b) => b.time.compareTo(a.time));
    return out;
  }

  String _friendlyDate(String date) {
    try {
      return DateFormat('EEE, MMM d').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
}

class _ActivityEntry {
  const _ActivityEntry({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final DateTime time;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
}

enum _ClockButtonState { clockIn, clockOut, done }

class _QuickActionStyle {
  const _QuickActionStyle({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
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
