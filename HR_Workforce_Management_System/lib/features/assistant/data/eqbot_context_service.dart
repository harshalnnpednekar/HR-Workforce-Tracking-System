import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'eqbot_models.dart';

class EqBotContextService {
  EqBotContextService._();

  static final _db = FirebaseFirestore.instance;

  static Future<EqBotUserContext> fetchForUser(String uid) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final monthStartKey = _dateKey(monthStart);
    final monthEndKey = _dateKey(monthEnd);
    final payrollDocId = _monthDocId(now);

    final userFuture = _db.collection('users').doc(uid).get();
    final payrollFuture = _db
        .collection('payroll')
        .doc(uid)
        .collection('months')
        .doc(payrollDocId)
        .get();
    final attendanceFuture = _db
        .collection('attendance')
        .doc(uid)
        .collection('records')
        .where('date', isGreaterThanOrEqualTo: monthStartKey)
        .where('date', isLessThanOrEqualTo: monthEndKey)
        .get();
    final hrRulesFuture = _db.collection('hrRules').get();
    final policyFuture = _db.collection('hr_rules').doc('equitec').get();

    final results = await Future.wait([
      userFuture,
      payrollFuture,
      attendanceFuture,
      hrRulesFuture,
      policyFuture,
    ]);

    final userSnap = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final payrollSnap = results[1] as DocumentSnapshot<Map<String, dynamic>>;
    final attendanceSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final hrRulesSnap = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final policySnap = results[4] as DocumentSnapshot<Map<String, dynamic>>;

    final user = userSnap.data() ?? const <String, dynamic>{};
    final payroll = payrollSnap.data() ?? const <String, dynamic>{};
    final policy = policySnap.data() ?? const <String, dynamic>{};

    final hrRules = <String, String>{
      for (final doc in hrRulesSnap.docs)
        doc.id: '${doc.data()['value'] ?? ''}',
    };

    var present = 0;
    var late = 0;
    var absent = 0;
    for (final record in attendanceSnap.docs) {
      final status = (record.data()['status'] as String? ?? '').toLowerCase();
      if (status == 'present') {
        present++;
      } else if (status == 'late') {
        late++;
      } else if (status == 'absent') {
        absent++;
      }
    }

    final employeeName = _readFirstString(user, [
      'name',
      'fullName',
      'employeeName',
    ], fallback: 'Employee');
    final department = _readFirstString(user, [
      'department',
      'dept',
    ], fallback: 'Not available');
    final role = _readFirstString(user, [
      'designation',
      'designationId',
      'role',
    ], fallback: 'Not available');

    final leaveCasual = _readFirstInt(user, [
      'casualLeaveBalance',
      'casualLeave',
    ], fallback: 0);
    final leaveSick = _readFirstInt(user, [
      'sickLeaveBalance',
      'sickLeave',
    ], fallback: 0);
    final leaveAnnual = _readFirstInt(user, [
      'earnedLeaveBalance',
      'earnedLeave',
    ], fallback: 0);

    final currentMonthSalary = _readFirstDouble(payroll, [
      'netSalary',
      'currentMonthSalary',
      'salary',
    ]);
    final salaryStatus = _readFirstString(payroll, [
      'status',
    ], fallback: 'Not available');

    final officeIn =
        hrRules['office_intime'] ??
        _toTimeString(policy['officeInTime']) ??
        '09:30';
    final officeOut =
        hrRules['office_outtime'] ??
        _toTimeString(policy['officeOutTime']) ??
        '18:30';
    final lateThresholdMinutes =
        _readIntAny(hrRules['late_threshold_minutes']) ??
        _readFirstInt(policy, ['lateThresholdMinutes'], fallback: 15);

    final lateDeduction =
        _readFirstDouble(policy, ['lateDeductionPerMark']) ?? 500;
    final pfPercent = _readFirstDouble(policy, ['pfPercentage']) ?? 12;
    final professionalTax =
        _readFirstDouble(policy, ['professionalTax']) ?? 200;

    final monthLabel = DateFormat('MMMM yyyy').format(now);

    return EqBotUserContext(
      employeeName: employeeName,
      department: department,
      role: role,
      leaveCasual: leaveCasual,
      leaveSick: leaveSick,
      leaveAnnual: leaveAnnual,
      currentMonthSalary: currentMonthSalary,
      salaryStatus: salaryStatus,
      presentCount: present,
      lateCount: late,
      absentCount: absent,
      workingHours: '${_to12Hour(officeIn)} - ${_to12Hour(officeOut)}',
      lateThresholdText:
          'after ${_to12Hour(officeIn)} + $lateThresholdMinutes min',
      lateDeduction: lateDeduction,
      pfPercent: pfPercent,
      professionalTax: professionalTax,
      monthLabel: monthLabel,
    );
  }

  static String _monthDocId(DateTime date) {
    const monthNames = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    final month = monthNames[date.month - 1];
    return '$month-${date.year}';
  }

  static String _dateKey(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _readFirstString(
    Map<String, dynamic> map,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  static int _readFirstInt(
    Map<String, dynamic> map,
    List<String> keys, {
    required int fallback,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return fallback;
  }

  static double? _readFirstDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is double) {
        return value;
      }
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  static int? _readIntAny(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static String? _toTimeString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static String _to12Hour(String hhmm) {
    final parts = hhmm.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final minuteText = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteText $suffix';
  }
}
