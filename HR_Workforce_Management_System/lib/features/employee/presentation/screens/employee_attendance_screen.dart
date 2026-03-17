import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/attendance_service.dart';
import 'shared/employee_dashboard_constants.dart';

class EmployeeAttendancePage extends StatefulWidget {
  const EmployeeAttendancePage({super.key, required this.userId});

  final String userId;

  @override
  State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  late Future<List<Map<String, dynamic>>> _monthRecordsFuture;
  late Future<Map<String, dynamic>?> _selectedRecordFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadRecords();
  }

  @override
  void didUpdateWidget(covariant EmployeeAttendancePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadRecords();
    }
  }

  void _loadRecords() {
    if (widget.userId.isEmpty) {
      _monthRecordsFuture = Future.value(const []);
      _selectedRecordFuture = Future.value(null);
      return;
    }

    final month = DateFormat('yyyy-MM').format(_focusedMonth);
    _monthRecordsFuture = AttendanceService.getMonthlyAttendance(
      widget.userId,
      month,
    );
    _selectedRecordFuture = AttendanceService.getAttendanceForDate(
      widget.userId,
      _selectedDate,
    );
  }

  void _changeMonth(int delta) {
    final moved = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
    setState(() {
      _focusedMonth = moved;
      _selectedDate = DateTime(moved.year, moved.month, 1);
      _loadRecords();
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _selectedRecordFuture = widget.userId.isEmpty
          ? Future.value(null)
          : AttendanceService.getAttendanceForDate(
              widget.userId,
              _selectedDate,
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 108),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InnerPageHeader(title: 'Attendance Tracking'),
          const SizedBox(height: 18),
          _AttendanceCalendarCard(
            focusedMonth: _focusedMonth,
            selectedDate: _selectedDate,
            monthRecordsFuture: _monthRecordsFuture,
            onPreviousMonth: () => _changeMonth(-1),
            onNextMonth: () => _changeMonth(1),
            onSelectDate: _selectDate,
          ),
          const SizedBox(height: 24),
          _DailyLogAndWeeklyCard(
            userId: widget.userId,
            selectedDate: _selectedDate,
            selectedRecordFuture: _selectedRecordFuture,
          ),
        ],
      ),
    );
  }
}

class _AttendanceCalendarCard extends StatelessWidget {
  const _AttendanceCalendarCard({
    required this.focusedMonth,
    required this.selectedDate,
    required this.monthRecordsFuture,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final Future<List<Map<String, dynamic>>> monthRecordsFuture;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              _MonthNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPreviousMonth,
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM y').format(focusedMonth),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppColors.title,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _MonthNavButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _CalendarWeekLabels(),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: monthRecordsFuture,
            builder: (context, snapshot) {
              final statusByDate = {
                for (final r
                    in (snapshot.data ?? const <Map<String, dynamic>>[]))
                  (r['date'] as String? ?? ''): (r['status'] as String? ?? ''),
              };
              return _CalendarDays(
                focusedMonth: focusedMonth,
                selectedDate: selectedDate,
                statusByDate: statusByDate,
                onSelectDate: onSelectDate,
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 18,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              LegendDot(label: 'PRESENT', color: Color(0xFF18B47F)),
              LegendDot(label: 'LATE', color: Color(0xFFF59F00)),
              LegendDot(label: 'ABSENT', color: Color(0xFFF14564)),
              LegendDot(label: 'SELECTED', color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _CalendarWeekLabels extends StatelessWidget {
  const _CalendarWeekLabels();

  @override
  Widget build(BuildContext context) {
    const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days
          .map(
            (d) => Expanded(
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9AA8BE),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalendarDays extends StatelessWidget {
  const _CalendarDays({
    required this.focusedMonth,
    required this.selectedDate,
    required this.statusByDate,
    required this.onSelectDate,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final Map<String, String> statusByDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final monthFirst = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final monthDays = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;
    final lead = monthFirst.weekday % 7;
    final total = (((lead + monthDays) / 7).ceil()) * 7;

    final cells = List<Widget>.generate(total, (index) {
      final dayNumber = index - lead + 1;
      if (dayNumber < 1 || dayNumber > monthDays) {
        return const SizedBox.shrink();
      }

      final date = DateTime(focusedMonth.year, focusedMonth.month, dayNumber);
      final key = DateFormat('yyyy-MM-dd').format(date);
      final status = statusByDate[key];

      return InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => onSelectDate(date),
        child: _DayItem(
          day: '$dayNumber',
          selected: _isSameDate(date, selectedDate),
          present: status == 'present',
          late: status == 'late',
          absent: status == 'absent',
        ),
      );
    });

    return Wrap(
      spacing: 2,
      runSpacing: 8,
      children: cells
          .map(
            (cell) => SizedBox(
              width: (MediaQuery.of(context).size.width - 102) / 7,
              child: cell,
            ),
          )
          .toList(),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayItem extends StatelessWidget {
  const _DayItem({
    required this.day,
    this.present = false,
    this.late = false,
    this.absent = false,
    this.selected = false,
  });

  final String day;
  final bool present;
  final bool late;
  final bool absent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    Color textColor = const Color(0xFF121A2E);
    Color borderColor = Colors.transparent;
    Color bg = Colors.transparent;

    if (present) {
      borderColor = const Color(0xFF9CE1CA);
      bg = const Color(0xFFEAF9F3);
    }
    if (late) {
      borderColor = const Color(0xFFF4CC80);
      bg = const Color(0xFFFFF7E8);
    }
    if (absent) {
      borderColor = const Color(0xFFF5B5C1);
      bg = const Color(0xFFFFEFF3);
      textColor = const Color(0xFFE54061);
    }
    if (selected) {
      borderColor = Colors.transparent;
      bg = AppColors.primary;
      textColor = Colors.white;
    }

    final dotColor = present
        ? const Color(0xFF18B47F)
        : late
        ? const Color(0xFFF59F00)
        : absent
        ? const Color(0xFFF14564)
        : null;

    return Center(
      child: SizedBox(
        width: 42,
        height: 46,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x2EF48300),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            if (dotColor != null)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DailyLogAndWeeklyCard extends StatelessWidget {
  const _DailyLogAndWeeklyCard({
    required this.userId,
    required this.selectedDate,
    required this.selectedRecordFuture,
  });

  final String userId;
  final DateTime selectedDate;
  final Future<Map<String, dynamic>?> selectedRecordFuture;

  @override
  Widget build(BuildContext context) {
    final selectedDateLabel = DateFormat('MMM d, y').format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_available_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Daily Log - $selectedDateLabel',
              style: GoogleFonts.outfit(
                color: AppColors.title,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FutureBuilder<Map<String, dynamic>?>(
          future: selectedRecordFuture,
          builder: (context, snapshot) {
            final record = snapshot.data;
            final clockIn = _readTimestamp(record?['clockIn']);
            final clockOut = _readTimestamp(record?['clockOut']);
            final totalHours = _recordHours(record, clockIn, clockOut);

            return Row(
              children: [
                Expanded(
                  child: _AttendanceInfoBox(
                    title: 'FIRST LOGIN',
                    value: _formatTime(clockIn),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AttendanceInfoBox(
                    title: 'LAST LOGOUT',
                    value: _formatTime(clockOut),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AttendanceInfoBox(
                    title: 'EFFECTIVE',
                    value: _formatHours(totalHours),
                    highlighted: true,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        BaseCard(
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Weekly Performance',
                    style: GoogleFonts.outfit(
                      color: AppColors.title,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2E0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'VS 8H GOAL',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _WeeklyAverageLabel(userId: userId, anchorDate: selectedDate),
              const SizedBox(height: 14),
              _WeekBarChart(userId: userId, anchorDate: selectedDate),
            ],
          ),
        ),
      ],
    );
  }

  static DateTime? _readTimestamp(Object? raw) {
    return raw is Timestamp ? raw.toDate() : null;
  }

  static double _recordHours(
    Map<String, dynamic>? record,
    DateTime? inTime,
    DateTime? outTime,
  ) {
    final raw = record?['totalHours'];
    if (raw is num) return raw.toDouble();
    if (inTime != null && outTime != null) {
      return outTime.difference(inTime).inMinutes / 60.0;
    }
    return 0;
  }

  static String _formatTime(DateTime? value) {
    if (value == null) return '--';
    return DateFormat('hh:mm a').format(value);
  }

  static String _formatHours(double totalHours) {
    if (totalHours <= 0) return '--';
    final h = totalHours.floor();
    final m = ((totalHours - h) * 60).round();
    return '${h}h ${m}m';
  }
}

class _AttendanceInfoBox extends StatelessWidget {
  const _AttendanceInfoBox({
    required this.title,
    required this.value,
    this.highlighted = false,
  });

  final String title;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: highlighted ? AppColors.primary : AppColors.title,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekBarChart extends StatelessWidget {
  const _WeekBarChart({required this.userId, required this.anchorDate});

  final String userId;
  final DateTime anchorDate;

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const SizedBox(height: 208);
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AttendanceService.streamWeekRecords(userId, anchorDate),
      builder: (context, snapshot) {
        final week = _weekStart(anchorDate);
        final dayHours = List<double>.filled(7, 0);
        for (final row in (snapshot.data ?? const <Map<String, dynamic>>[])) {
          final dateRaw = row['date'] as String?;
          final parsed = dateRaw == null ? null : DateTime.tryParse(dateRaw);
          if (parsed == null) continue;
          final index = parsed.difference(week).inDays;
          if (index < 0 || index > 6) continue;
          final val = row['totalHours'];
          dayHours[index] = val is num ? val.toDouble() : 0;
        }

        final maxValue = dayHours.fold<double>(0, (p, e) => e > p ? e : p);
        final maxY = maxValue < 8 ? 8.0 : maxValue + 1.5;
        final today = DateTime.now();

        return SizedBox(
          height: 208,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: maxY,
              barTouchData: BarTouchData(enabled: true),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const labels = [
                        'MON',
                        'TUE',
                        'WED',
                        'THU',
                        'FRI',
                        'SAT',
                        'SUN',
                      ];
                      final idx = value.toInt();
                      if (idx < 0 || idx >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      final date = week.add(Duration(days: idx));
                      final isToday = _isSameDate(date, today);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[idx],
                          style: TextStyle(
                            color: isToday
                                ? AppColors.primary
                                : const Color(0xFF93A0B6),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(7, (index) {
                final date = week.add(Duration(days: index));
                final isToday = _isSameDate(date, today);
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: dayHours[index],
                      width: 20,
                      borderRadius: BorderRadius.circular(10),
                      color: isToday
                          ? AppColors.primary
                          : const Color(0xFFECC18B),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  static DateTime _weekStart(DateTime date) {
    final base = DateTime(date.year, date.month, date.day);
    return base.subtract(Duration(days: base.weekday - DateTime.monday));
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _WeeklyAverageLabel extends StatelessWidget {
  const _WeeklyAverageLabel({required this.userId, required this.anchorDate});

  final String userId;
  final DateTime anchorDate;

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Avg: --',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AttendanceService.streamWeekRecords(userId, anchorDate),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];
        double sum = 0;
        int daysWorked = 0;
        for (final row in rows) {
          final h = row['totalHours'];
          final value = h is num ? h.toDouble() : 0.0;
          if (value > 0) {
            sum += value;
            daysWorked++;
          }
        }
        final avg = daysWorked == 0 ? 0.0 : sum / daysWorked;
        final avgLabel = daysWorked == 0 ? '--' : _formatHours(avg);

        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Avg: $avgLabel / day',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        );
      },
    );
  }

  static String _formatHours(double totalHours) {
    final h = totalHours.floor();
    final m = ((totalHours - h) * 60).round();
    return '${h}h ${m}m';
  }
}
