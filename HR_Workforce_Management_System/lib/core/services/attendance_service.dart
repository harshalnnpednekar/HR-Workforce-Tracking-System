import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

/// Firestore collection shape:
///   attendance/{uid}/records/{yyyy-MM-dd}
///
/// Record fields:
///   date (String), clockIn (Timestamp?), clockOut (Timestamp?),
///   totalHours (double), status ('present'|'late'|'absent'),
///   employeeName, department, designation, photoUrl
class AttendanceService {
  static final _db = FirebaseFirestore.instance;
  static const _rootCol = 'attendance';

  static CollectionReference<Map<String, dynamic>> _records(String userId) {
    return _db.collection(_rootCol).doc(userId).collection('records');
  }

  static DocumentReference<Map<String, dynamic>> _recordRef(
    String userId,
    DateTime date,
  ) {
    return _records(userId).doc(_dateKey(date));
  }

  /// Streams today's attendance record for [userId].
  static Stream<Map<String, dynamic>?> streamTodayAttendance(String userId) {
    return _recordRef(userId, DateTime.now()).snapshots().map((doc) {
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    });
  }

  /// Returns today's attendance record for [userId], or null if absent.
  static Future<Map<String, dynamic>?> getTodayAttendance(String userId) async {
    final doc = await _recordRef(userId, DateTime.now()).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  /// Returns attendance record for [date] and [userId], or null when absent.
  static Future<Map<String, dynamic>?> getAttendanceForDate(
    String userId,
    DateTime date,
  ) async {
    final doc = await _recordRef(userId, date).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  /// Writes today's clock-in and returns the local captured timestamp.
  static Future<DateTime> clockIn(String userId) async {
    final now = DateTime.now();
    final ref = _recordRef(userId, now);
    final isLate = await _isLateClockIn(now);
    final userMeta = await _readUserMeta(userId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        final data = snap.data() ?? {};
        final hasClockIn = data['clockIn'] != null;
        final hasClockOut = data['clockOut'] != null;
        if (hasClockOut) {
          throw Exception('Attendance already completed for today.');
        }
        if (hasClockIn) {
          throw Exception('Already clocked in for today.');
        }
      }

      tx.set(ref, {
        'date': _dateKey(now),
        'clockIn': Timestamp.fromDate(now),
        'clockOut': null,
        'totalHours': 0.0,
        'status': isLate ? 'late' : 'present',
        'employeeName': userMeta.employeeName,
        'department': userMeta.department,
        'designation': userMeta.designation,
        'photoUrl': userMeta.photoUrl,
        'isManual': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    if (isLate) {
      try {
        final timeLabel = _format12Hour(now);
        await NotificationService.send(
          userId: userId,
          title: 'Late Arrival Marked',
          message: 'You clocked in at $timeLabel today',
          type: NotificationService.typeLate,
          subtitle: 'Please try to arrive on time tomorrow.',
          relatedId: _dateKey(now),
        );
        await NotificationService.sendToAdmins(
          title: 'Late Arrival',
          message: '${userMeta.employeeName} clocked in late at $timeLabel',
          type: NotificationService.typeLateArrival,
          subtitle: '${_dateKey(now)} · ${userMeta.department}',
          relatedId: _dateKey(now),
          extra: {'employeeUid': userId},
        );
      } catch (_) {
        // Keep attendance flow successful even if notification write fails.
      }
    }

    return now;
  }

  /// Writes today's clock-out and returns the local captured timestamp.
  static Future<DateTime> clockOut(String userId) async {
    final now = DateTime.now();
    final ref = _recordRef(userId, now);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw Exception('No clock-in found for today.');
      }

      final data = snap.data() ?? {};
      final clockInRaw = data['clockIn'];
      if (clockInRaw == null) {
        throw Exception('No clock-in found for today.');
      }
      if (data['clockOut'] != null) {
        throw Exception('Already clocked out for today.');
      }

      final clockIn = (clockInRaw as Timestamp).toDate();
      final totalHours = now.difference(clockIn).inMinutes / 60.0;

      tx.set(ref, {
        'clockOut': Timestamp.fromDate(now),
        'totalHours': double.parse(totalHours.toStringAsFixed(2)),
        'status': data['status'] == 'late' ? 'late' : 'present',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    return now;
  }

  /// Returns total hours for the trailing 7 days (including today).
  static Future<double> getWeeklyHours(String userId) async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final snap = await _records(userId)
        .where('date', isGreaterThanOrEqualTo: _dateKey(start))
        .where('date', isLessThanOrEqualTo: _dateKey(now))
        .get();

    double sum = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final value = data['totalHours'];
      if (value is num) {
        sum += value.toDouble();
      }
    }
    return double.parse(sum.toStringAsFixed(2));
  }

  /// Returns late mark count for the current month.
  static Future<int> getMonthlyLateMarks(String userId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final snap = await _records(userId)
        .where('status', isEqualTo: 'late')
        .where('date', isGreaterThanOrEqualTo: _dateKey(monthStart))
        .where('date', isLessThanOrEqualTo: _dateKey(monthEnd))
        .get();
    return snap.docs.length;
  }

  /// Streams latest attendance records ordered by date descending.
  static Stream<List<Map<String, dynamic>>> streamRecentRecords(
    String userId, {
    int limit = 5,
  }) {
    return _records(
      userId,
    ).orderBy('date', descending: true).limit(limit).snapshots().map((snap) {
      return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  /// Streams records for a Monday-Sunday week containing [anchorDate].
  static Stream<List<Map<String, dynamic>>> streamWeekRecords(
    String userId,
    DateTime anchorDate,
  ) {
    final start = _startOfWeek(anchorDate);
    final end = start.add(const Duration(days: 6));
    return _records(userId)
        .where('date', isGreaterThanOrEqualTo: _dateKey(start))
        .where('date', isLessThanOrEqualTo: _dateKey(end))
        .snapshots()
        .map((snap) {
          final rows = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          rows.sort((a, b) {
            final ad = (a['date'] as String?) ?? '';
            final bd = (b['date'] as String?) ?? '';
            return ad.compareTo(bd);
          });
          return rows;
        });
  }

  /// Returns attendance records for [userId] in a given [month] (YYYY-MM).
  static Future<List<Map<String, dynamic>>> getMonthlyAttendance(
    String userId,
    String month,
  ) async {
    final snap = await _records(userId)
        .where('date', isGreaterThanOrEqualTo: '$month-01')
        .where('date', isLessThanOrEqualTo: '$month-31')
        .orderBy('date')
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Admin helper: returns all user IDs with attendance for a date.
  static Future<List<Map<String, dynamic>>> getAttendanceByDate(
    String date,
  ) async {
    final parentSnap = await _db
        .collectionGroup('records')
        .where('date', isEqualTo: date)
        .get();
    return parentSnap.docs.map((d) {
      final userId = d.reference.parent.parent?.id;
      return {'id': d.id, if (userId != null) 'userId': userId, ...d.data()};
    }).toList();
  }

  static Future<bool> _isLateClockIn(DateTime clockIn) async {
    final officeInSnap = await _db
        .collection('hrRules')
        .doc('office_intime')
        .get();
    final graceSnap = await _db
        .collection('hrRules')
        .doc('late_threshold_minutes')
        .get();

    final officeIn = (officeInSnap.data()?['value'] as String?) ?? '09:30';
    final graceMinutes =
        int.tryParse((graceSnap.data()?['value'] as String?) ?? '15') ?? 15;

    final split = officeIn.split(':');
    final h = split.isNotEmpty ? int.tryParse(split[0]) ?? 9 : 9;
    final m = split.length > 1 ? int.tryParse(split[1]) ?? 30 : 30;
    final expected = DateTime(
      clockIn.year,
      clockIn.month,
      clockIn.day,
      h,
      m,
    ).add(Duration(minutes: graceMinutes));

    return clockIn.isAfter(expected);
  }

  static String _dateKey(DateTime now) {
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _format12Hour(DateTime dateTime) {
    final hour24 = dateTime.hour;
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $suffix';
  }

  static DateTime _startOfWeek(DateTime date) {
    final base = DateTime(date.year, date.month, date.day);
    return base.subtract(Duration(days: base.weekday - DateTime.monday));
  }

  static Future<_UserAttendanceMeta> _readUserMeta(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    final data = snap.data() ?? const <String, dynamic>{};

    final employeeName = ((data['name'] as String?) ?? '').trim();
    final department = ((data['department'] as String?) ?? '').trim();
    final designation = ((data['designation'] as String?) ?? '').trim();
    final photoUrl = ((data['photoUrl'] as String?) ?? '').trim();

    return _UserAttendanceMeta(
      employeeName: employeeName.isEmpty ? 'Employee' : employeeName,
      department: department,
      designation: designation,
      photoUrl: photoUrl,
    );
  }
}

class _UserAttendanceMeta {
  const _UserAttendanceMeta({
    required this.employeeName,
    required this.department,
    required this.designation,
    required this.photoUrl,
  });

  final String employeeName;
  final String department;
  final String designation;
  final String photoUrl;
}
