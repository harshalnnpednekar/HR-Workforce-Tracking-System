import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared/employee_dashboard_constants.dart';

class EmployeeAttendancePage extends StatelessWidget {
  const EmployeeAttendancePage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 108),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          InnerPageHeader(title: 'Attendance Tracking'),
          SizedBox(height: 18),
          _AttendanceCalendarCard(),
          SizedBox(height: 24),
          _DailyLogAndWeeklyCard(),
        ],
      ),
    );
  }
}

class _AttendanceCalendarCard extends StatelessWidget {
  const _AttendanceCalendarCard();

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              _MonthNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => showActionMessage(context, 'Previous month'),
              ),
              Expanded(
                child: Text(
                  'October 2023',
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
                onTap: () => showActionMessage(context, 'Next month'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _CalendarWeekLabels(),
          const SizedBox(height: 10),
          const _CalendarDays(),
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
  const _CalendarDays();

  @override
  Widget build(BuildContext context) {
    final days = [
      _DayItem(day: '24', inactive: true),
      _DayItem(day: '25', inactive: true),
      _DayItem(day: '26', inactive: true),
      _DayItem(day: '27', inactive: true),
      _DayItem(day: '28', inactive: true),
      _DayItem(day: '29', inactive: true),
      _DayItem(day: '1', present: true),
      _DayItem(day: '2', present: true),
      _DayItem(day: '3', present: true),
      _DayItem(day: '4', late: true),
      _DayItem(day: '5', selected: true),
      _DayItem(day: '6', absent: true),
      _DayItem(day: '7', present: true),
      _DayItem(day: '8'),
      _DayItem(day: '9'),
      _DayItem(day: '10'),
      _DayItem(day: '11'),
      _DayItem(day: '12'),
      _DayItem(day: '13'),
      _DayItem(day: '14'),
      _DayItem(day: '15'),
    ];

    return Wrap(
      spacing: 2,
      runSpacing: 8,
      children: days
          .map(
            (item) => SizedBox(
              width: (MediaQuery.of(context).size.width - 102) / 7,
              child: item,
            ),
          )
          .toList(),
    );
  }
}

class _DayItem extends StatelessWidget {
  const _DayItem({
    required this.day,
    this.present = false,
    this.late = false,
    this.absent = false,
    this.selected = false,
    this.inactive = false,
  });

  final String day;
  final bool present;
  final bool late;
  final bool absent;
  final bool selected;
  final bool inactive;

  @override
  Widget build(BuildContext context) {
    Color textColor = const Color(0xFF121A2E);
    Color borderColor = Colors.transparent;
    Color bg = Colors.transparent;

    if (inactive) {
      textColor = const Color(0xFFC8D0DD);
    }
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

    return Center(
      child: Container(
        width: 42,
        height: 42,
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
    );
  }
}

class _DailyLogAndWeeklyCard extends StatelessWidget {
  const _DailyLogAndWeeklyCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_available_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Daily Log - Oct 5, 2023',
              style: GoogleFonts.outfit(
                color: AppColors.title,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(
              child: _AttendanceInfoBox(
                title: 'FIRST LOGIN',
                value: '08:45 AM',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _AttendanceInfoBox(
                title: 'LAST LOGOUT',
                value: '06:15 PM',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _AttendanceInfoBox(
                title: 'EFFECTIVE',
                value: '8h 30m',
                highlighted: true,
              ),
            ),
          ],
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
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Avg: 7h 45m / day',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 14),
              const _WeekBarChart(),
            ],
          ),
        ),
      ],
    );
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
  const _WeekBarChart();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('MON', 0.78),
      ('TUE', 0.92),
      ('WED', 0.85),
      ('THU', 0.86),
      ('FRI', 0.64),
      ('SAT', 0.14),
      ('SUN', 0.12),
    ];
    return SizedBox(
      height: 208,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: items.map((e) {
          final active = e.$1 == 'WED';
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 34,
                  height: 130 * e.$2,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : const Color(0xFFECC18B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 6),
                  child: active
                      ? const Text(
                          '8.5h',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  e.$1,
                  style: TextStyle(
                    color: active ? AppColors.primary : const Color(0xFF93A0B6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
