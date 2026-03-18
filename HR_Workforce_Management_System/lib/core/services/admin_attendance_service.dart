import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminAttendanceDayData {
  const AdminAttendanceDayData({
    required this.selectedDate,
    required this.present,
    required this.late,
    required this.absent,
    required this.onLeave,
    required this.logs,
    required this.departments,
  });

  final DateTime selectedDate;
  final int present;
  final int late;
  final int absent;
  final int onLeave;
  final List<AdminAttendanceLogData> logs;
  final List<String> departments;
}

class AdminAttendanceLogData {
  const AdminAttendanceLogData({
    required this.userId,
    required this.name,
    required this.department,
    required this.designation,
    required this.photoUrl,
    required this.status,
    required this.clockIn,
    required this.clockOut,
    required this.totalHours,
    required this.hasNoLogs,
  });

  final String userId;
  final String name;
  final String department;
  final String designation;
  final String? photoUrl;
  final String status;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final double totalHours;
  final bool hasNoLogs;
}

class AdminAttendanceService {
  static final _db = FirebaseFirestore.instance;

  static Future<AdminAttendanceDayData> getOverviewForDate(
    DateTime date,
  ) async {
    final records = await _safeRecordsForDate(date);
    final onLeave = await _onLeaveCount(date);
    return _toDayData(date, records, onLeave);
  }

  static Stream<AdminAttendanceDayData> streamOverviewForDate(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return _db
        .collectionGroup('records')
        .where('date', isEqualTo: dateKey)
        .snapshots()
        .asyncMap((snap) async {
          final records = _rowsFromRecordsSnapshot(snap);
          final onLeave = await _onLeaveCount(date);
          return _toDayData(date, records, onLeave);
        });
  }

  static Future<List<Map<String, dynamic>>> _safeRecordsForDate(
    DateTime date,
  ) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    try {
      final snap = await _db
          .collectionGroup('records')
          .where('date', isEqualTo: dateKey)
          .get();
      return _rowsFromRecordsSnapshot(snap);
    } catch (_) {
      return const [];
    }
  }

  static List<Map<String, dynamic>> _rowsFromRecordsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    return snap.docs
        .map((doc) {
          final userId = doc.reference.parent.parent?.id;
          return {
            'id': doc.id,
            if (userId != null) 'userId': userId,
            ...doc.data(),
          };
        })
        .toList(growable: false);
  }

  static Future<void> markAttendanceManually({
    required String uid,
    required DateTime date,
    required String status,
    DateTime? clockIn,
    DateTime? clockOut,
    required String adminUid,
  }) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final user = userDoc.data() ?? <String, dynamic>{};

    final normalizedStatus = status.toLowerCase();
    final key = DateFormat('yyyy-MM-dd').format(date);

    final validClockIn = normalizedStatus == 'absent' ? null : clockIn;
    final validClockOut = normalizedStatus == 'absent' ? null : clockOut;

    final totalHours = _hours(validClockIn, validClockOut);

    await _db
        .collection('attendance')
        .doc(uid)
        .collection('records')
        .doc(key)
        .set({
          'date': key,
          'status': normalizedStatus,
          'clockIn': validClockIn == null
              ? null
              : Timestamp.fromDate(validClockIn),
          'clockOut': validClockOut == null
              ? null
              : Timestamp.fromDate(validClockOut),
          'totalHours': totalHours,
          'employeeName': (user['name'] as String?)?.trim().isNotEmpty == true
              ? (user['name'] as String).trim()
              : 'Employee',
          'department': ((user['department'] as String?) ?? '').trim(),
          'designation': ((user['designation'] as String?) ?? '').trim(),
          'photoUrl': (user['photoUrl'] as String?) ?? '',
          'isManual': true,
          'markedBy': adminUid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>> buildDayExportPayload(
    DateTime date,
  ) async {
    final overview = await getOverviewForDate(date);
    final byDepartment = <String, Map<String, int>>{};

    for (final row in overview.logs) {
      final dep = row.department.trim().isEmpty ? 'Unknown' : row.department;
      final bucket = byDepartment.putIfAbsent(
        dep,
        () => {'present': 0, 'late': 0, 'absent': 0},
      );
      if (row.status == 'present')
        bucket['present'] = (bucket['present'] ?? 0) + 1;
      if (row.status == 'late') bucket['late'] = (bucket['late'] ?? 0) + 1;
      if (row.status == 'absent')
        bucket['absent'] = (bucket['absent'] ?? 0) + 1;
    }

    return {
      'date': DateFormat('yyyy-MM-dd').format(date),
      'summary': {
        'present': overview.present,
        'late': overview.late,
        'absent': overview.absent,
        'onLeave': overview.onLeave,
      },
      'departmentBreakdown': byDepartment,
      'rows': overview.logs
          .map(
            (r) => {
              'name': r.name,
              'department': r.department,
              'designation': r.designation,
              'status': r.status,
              'clockIn': r.clockIn,
              'clockOut': r.clockOut,
              'totalHours': r.totalHours,
            },
          )
          .toList(),
    };
  }

  static Future<int> _onLeaveCount(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      final snap = await _db
          .collection('leaves')
          .where('status', isEqualTo: 'approved')
          .get();

      var count = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final from = _toDateTime(data['fromDate']);
        final to = _toDateTime(data['toDate']);
        if (from == null || to == null) {
          continue;
        }
        if (!from.isAfter(dayEnd) && !to.isBefore(dayStart)) {
          count += 1;
        }
      }

      return count;
    } catch (_) {
      return 0;
    }
  }

  static AdminAttendanceDayData _toDayData(
    DateTime date,
    List<Map<String, dynamic>> rows,
    int onLeave,
  ) {
    var present = 0;
    var late = 0;
    var absent = 0;
    final logs = <AdminAttendanceLogData>[];
    final departments = <String>{};

    for (final data in rows) {
      final status = ((data['status'] as String?) ?? '').toLowerCase();
      if (status == 'present' || status == 'done') present += 1;
      if (status == 'late') late += 1;
      if (status == 'absent') absent += 1;

      final dep = ((data['department'] as String?) ?? '').trim();
      if (dep.isNotEmpty) departments.add(dep);

      final userId = (data['userId'] as String?) ?? '';
      final clockIn = _toDateTime(data['clockIn']);
      final clockOut = _toDateTime(data['clockOut']);

      logs.add(
        AdminAttendanceLogData(
          userId: userId,
          name: ((data['employeeName'] as String?) ?? '').trim().isNotEmpty
              ? (data['employeeName'] as String).trim()
              : 'Employee',
          department: dep.isEmpty ? '-' : dep,
          designation: (((data['designation'] as String?) ?? '').trim().isEmpty)
              ? '-'
              : ((data['designation'] as String?) ?? '').trim(),
          photoUrl: (data['photoUrl'] as String?)?.trim().isNotEmpty == true
              ? (data['photoUrl'] as String).trim()
              : null,
          status: status == 'done' ? 'present' : status,
          clockIn: clockIn,
          clockOut: clockOut,
          totalHours:
              (data['totalHours'] as num?)?.toDouble() ??
              _hours(clockIn, clockOut),
          hasNoLogs: clockIn == null && clockOut == null,
        ),
      );
    }

    logs.sort((a, b) {
      final rank = _statusRank(a.status).compareTo(_statusRank(b.status));
      if (rank != 0) return rank;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return AdminAttendanceDayData(
      selectedDate: date,
      present: present,
      late: late,
      absent: absent,
      onLeave: onLeave,
      logs: logs,
      departments: departments.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
    );
  }

  static int _statusRank(String status) {
    switch (status) {
      case 'present':
        return 0;
      case 'late':
        return 1;
      case 'absent':
        return 2;
      default:
        return 3;
    }
  }

  static DateTime? _toDateTime(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static double _hours(DateTime? clockIn, DateTime? clockOut) {
    if (clockIn == null || clockOut == null) return 0;
    final mins = clockOut.difference(clockIn).inMinutes;
    if (mins <= 0) return 0;
    return double.parse((mins / 60.0).toStringAsFixed(2));
  }
}
