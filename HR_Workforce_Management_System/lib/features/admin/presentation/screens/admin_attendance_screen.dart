import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/admin_attendance_service.dart';
import '../../../../core/services/user_service.dart';
import '../widgets/admin_ui_kit.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  static const String _allDepartments = 'All Dept.';

  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  String _selectedDepartment = _allDepartments;

  late Future<AdminAttendanceDayData> _dayFuture;
  Stream<AdminAttendanceDayData>? _todayStream;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _reload();
  }

  void _reload() {
    _dayFuture = AdminAttendanceService.getOverviewForDate(_selectedDate);
    _todayStream = null;
  }

  Future<void> _onRefresh() async {
    setState(_reload);
    await _dayFuture;
  }

  void _changeMonth(int delta) {
    final moved = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
    final current = _selectedDate;
    final sameMonth =
        current.year == moved.year && current.month == moved.month;

    setState(() {
      _focusedMonth = moved;
      _selectedDate = sameMonth
          ? current
          : DateTime(moved.year, moved.month, 1);
      _reload();
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _reload();
    });
  }

  Future<void> _openManualMarkSheet() async {
    final employees = await UserService.getAllEmployees();
    if (!mounted) return;

    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No employees available for manual mark.'),
        ),
      );
      return;
    }

    String? selectedUid = (employees.first['id'] as String?);
    String status = 'present';
    TimeOfDay? inTime;
    TimeOfDay? outTime;
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickTime(bool isIn) async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked == null) return;
              setSheetState(() {
                if (isIn) {
                  inTime = picked;
                } else {
                  outTime = picked;
                }
              });
            }

            Future<void> submit() async {
              if (selectedUid == null || selectedUid!.isEmpty) return;
              setSheetState(() => saving = true);

              final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
              final inDate = _mergeDateAndTime(_selectedDate, inTime);
              final outDate = _mergeDateAndTime(_selectedDate, outTime);

              try {
                await AdminAttendanceService.markAttendanceManually(
                  uid: selectedUid!,
                  date: _selectedDate,
                  status: status,
                  clockIn: inDate,
                  clockOut: outDate,
                  adminUid: adminUid,
                );
                if (!mounted) return;
                Navigator.of(context).pop();
                setState(_reload);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Attendance marked successfully.'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                setSheetState(() => saving = false);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Failed to mark attendance: $e')),
                );
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manual Attendance Mark',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedUid,
                      items: employees
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e['id'] as String?,
                              child: Text(
                                ((e['name'] as String?) ?? 'Employee').trim(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedUid = v),
                      decoration: const InputDecoration(labelText: 'Employee'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(
                          value: 'present',
                          child: Text('Present'),
                        ),
                        DropdownMenuItem(value: 'late', child: Text('Late')),
                        DropdownMenuItem(
                          value: 'absent',
                          child: Text('Absent'),
                        ),
                      ],
                      onChanged: (v) =>
                          setSheetState(() => status = v ?? 'present'),
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: status == 'absent'
                                ? null
                                : () => pickTime(true),
                            child: Text(
                              inTime == null
                                  ? 'Clock In'
                                  : inTime!.format(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: status == 'absent'
                                ? null
                                : () => pickTime(false),
                            child: Text(
                              outTime == null
                                  ? 'Clock Out (Optional)'
                                  : outTime!.format(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving ? null : submit,
                        child: Text(saving ? 'Saving...' : 'Confirm'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _exportSummary() async {
    final payload = await AdminAttendanceService.buildDayExportPayload(
      _selectedDate,
    );
    if (!mounted) return;
    final rows = (payload['rows'] as List).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export payload ready for $rows records.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _todayStream != null
        ? StreamBuilder<AdminAttendanceDayData>(
            stream: _todayStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return _buildContent(snapshot.data!);
              }
              if (snapshot.hasError) {
                return _buildError();
              }
              return _buildLoader();
            },
          )
        : FutureBuilder<AdminAttendanceDayData>(
            future: _dayFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoader();
              }
              if (snapshot.hasError) {
                return _buildError();
              }
              return _buildContent(
                snapshot.data ??
                    AdminAttendanceDayData(
                      selectedDate: _selectedDate,
                      present: 0,
                      late: 0,
                      absent: 0,
                      onLeave: 0,
                      logs: const [],
                      departments: const [],
                    ),
              );
            },
          );

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
        child: body,
      ),
    );
  }

  Widget _buildLoader() {
    return const Padding(
      padding: EdgeInsets.only(top: 120),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError() {
    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Failed to load attendance overview.',
            style: TextStyle(
              color: Color(0xFF991B1B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _onRefresh, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(AdminAttendanceDayData vm) {
    final availableDepartments = [_allDepartments, ...vm.departments];
    final visibleLogs = _selectedDepartment == _allDepartments
        ? vm.logs
        : vm.logs
              .where((item) => item.department == _selectedDepartment)
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Overview',
                    style: TextStyle(
                      color: AdminColors.text,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'ADMIN PORTAL',
                    style: TextStyle(
                      color: Color(0xFF6B7F99),
                      fontSize: 15,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _exportSummary,
              icon: const Icon(
                Icons.download_rounded,
                color: AdminColors.primary,
              ),
              tooltip: 'Download summary',
            ),
            IconButton(
              onPressed: _openManualMarkSheet,
              icon: const Icon(
                Icons.add_circle_rounded,
                color: AdminColors.primary,
              ),
              tooltip: 'Manual mark',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MonthCalendarCard(
          focusedMonth: _focusedMonth,
          selectedDate: _selectedDate,
          onPreviousMonth: () => _changeMonth(-1),
          onNextMonth: () => _changeMonth(1),
          onSelectDate: _selectDate,
        ),
        const SizedBox(height: 14),
        _StatGrid(
          present: vm.present,
          late: vm.late,
          absent: vm.absent,
          onLeave: vm.onLeave,
        ),
        const SizedBox(height: 14),
        _DepartmentFilterRow(
          departments: availableDepartments,
          selectedDepartment: _selectedDepartment,
          onSelect: (value) {
            setState(() {
              _selectedDepartment = value;
            });
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Attendance Logs',
                style: TextStyle(
                  color: AdminColors.text,
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              DateFormat('EEE, d MMM').format(vm.selectedDate),
              style: const TextStyle(
                color: AdminColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (visibleLogs.isEmpty)
          const AdminSurfaceCard(
            child: Text(
              'No attendance logs for this date.',
              style: TextStyle(
                color: AdminColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          ...visibleLogs.map((item) => _AttendanceLogCard(item: item)),
      ],
    );
  }

  DateTime? _mergeDateAndTime(DateTime day, TimeOfDay? time) {
    if (time == null) return null;
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }
}

class _MonthCalendarCard extends StatelessWidget {
  const _MonthCalendarCard({
    required this.focusedMonth,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final monthDays = DateUtils.getDaysInMonth(
      focusedMonth.year,
      focusedMonth.month,
    );
    final lead = DateTime(focusedMonth.year, focusedMonth.month, 1).weekday % 7;

    return AdminSurfaceCard(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(focusedMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AdminColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: weekdays
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF8193AA),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            runSpacing: 8,
            children: List.generate(42, (index) {
              final day = index - lead + 1;
              final inMonth = day >= 1 && day <= monthDays;
              final date = DateTime(
                focusedMonth.year,
                focusedMonth.month,
                inMonth ? day : 1,
              );
              final selected = inMonth && _sameDate(date, selectedDate);

              return SizedBox(
                width: (MediaQuery.sizeOf(context).width - 84) / 7,
                child: Center(
                  child: inMonth
                      ? InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => onSelectDate(date),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AdminColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$day',
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AdminColors.text,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 36),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.present,
    required this.late,
    required this.absent,
    required this.onLeave,
  });

  final int present;
  final int late;
  final int absent;
  final int onLeave;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      children: [
        _StatCard(
          label: 'PRESENT',
          value: present,
          bg: const Color(0xFFDDF5E8),
          fg: const Color(0xFF0A7A4A),
        ),
        _StatCard(
          label: 'LATE',
          value: late,
          bg: const Color(0xFFFFF3D6),
          fg: const Color(0xFFB15C00),
        ),
        _StatCard(
          label: 'ABSENT',
          value: absent,
          bg: const Color(0xFFFFE6EA),
          fg: const Color(0xFFB1123D),
        ),
        _StatCard(
          label: 'ON LEAVE',
          value: onLeave,
          bg: const Color(0xFFE8EDFF),
          fg: const Color(0xFF3442B7),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });

  final String label;
  final int value;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              color: fg,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentFilterRow extends StatelessWidget {
  const _DepartmentFilterRow({
    required this.departments,
    required this.selectedDepartment,
    required this.onSelect,
  });

  final List<String> departments;
  final String selectedDepartment;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: departments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = departments[index];
          final selected = value == selectedDepartment;
          return ChoiceChip(
            label: Text(value),
            selected: selected,
            onSelected: (_) => onSelect(value),
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF1E3251),
              fontWeight: FontWeight.w700,
            ),
            selectedColor: AdminColors.primary,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AdminColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          );
        },
      ),
    );
  }
}

class _AttendanceLogCard extends StatelessWidget {
  const _AttendanceLogCard({required this.item});

  final AdminAttendanceLogData item;

  @override
  Widget build(BuildContext context) {
    final badge = _statusMeta(item.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AdminSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFE8EDF3),
              child: Text(
                _initials(item.name),
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: AdminColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.department} - ${item.designation}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.login_rounded,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.clockIn == null
                            ? '--:--'
                            : DateFormat('hh:mm a').format(item.clockIn!),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.logout_rounded,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.clockOut == null
                            ? '--:--'
                            : DateFormat('hh:mm a').format(item.clockOut!),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badge.$1,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge.$2,
                    style: TextStyle(
                      color: badge.$3,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _durationLabel(item),
                  style: const TextStyle(
                    color: Color(0xFF8090A8),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _durationLabel(AdminAttendanceLogData entry) {
    if (entry.status == 'absent') return '0h 00m';
    if (entry.hasNoLogs) return 'No logs recorded for today';

    if (entry.totalHours > 0) {
      final h = entry.totalHours.floor();
      final m = ((entry.totalHours - h) * 60).round();
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }

    return entry.status == 'late' ? 'On Clock' : 'Active';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'E';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }
}

(Color, String, Color) _statusMeta(String status) {
  switch (status) {
    case 'present':
      return (const Color(0xFFD9F7E7), 'PRESENT', const Color(0xFF0A7A4A));
    case 'late':
      return (const Color(0xFFFFF0CF), 'LATE', const Color(0xFFB15C00));
    case 'absent':
      return (const Color(0xFFFFE3E8), 'ABSENT', const Color(0xFFB1123D));
    default:
      return (const Color(0xFFE6ECFF), 'ON LEAVE', const Color(0xFF3342B2));
  }
}
