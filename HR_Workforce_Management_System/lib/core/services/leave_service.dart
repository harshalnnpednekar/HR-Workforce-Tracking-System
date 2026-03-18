import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

/// Firestore collections: `leaveTypes`, `leaveRequests`
///
/// leaveTypes fields: name, maxDaysPerYear, isPaid, isActive
///
/// leaveRequests fields:
///   userId, userName, leaveTypeId, leaveTypeName,
///   fromDate (YYYY-MM-DD), toDate (YYYY-MM-DD), totalDays,
///   reason, status ('pending'|'approved'|'rejected'),
///   approvedBy, approvedOn, comments, createdAt
class LeaveService {
  static final _db = FirebaseFirestore.instance;
  static const int _defaultCasualLeave = 12;
  static const int _defaultSickLeave = 10;
  static const int _defaultEarnedLeave = 20;

  // ── Employee Leave V2 (`leaves`) ────────────────────────

  /// Returns remaining balances from `users/{uid}`.
  static Future<Map<String, int>> getUserLeaveBalances(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() ?? <String, dynamic>{};
    final casual =
        (data['casualLeaveBalance'] as num?)?.toInt() ??
        (data['casualLeave'] as num?)?.toInt() ??
        _defaultCasualLeave;
    final sick =
        (data['sickLeaveBalance'] as num?)?.toInt() ??
        (data['sickLeave'] as num?)?.toInt() ??
        _defaultSickLeave;
    final earned =
        (data['earnedLeaveBalance'] as num?)?.toInt() ??
        (data['earnedLeave'] as num?)?.toInt() ??
        _defaultEarnedLeave;

    if (doc.exists) {
      final seedFields = <String, dynamic>{};
      if (data['casualLeaveBalance'] == null && data['casualLeave'] == null) {
        seedFields['casualLeaveBalance'] = casual;
      }
      if (data['sickLeaveBalance'] == null && data['sickLeave'] == null) {
        seedFields['sickLeaveBalance'] = sick;
      }
      if (data['earnedLeaveBalance'] == null && data['earnedLeave'] == null) {
        seedFields['earnedLeaveBalance'] = earned;
      }
      if (seedFields.isNotEmpty) {
        await _db
            .collection('users')
            .doc(uid)
            .set(seedFields, SetOptions(merge: true));
      }
    }

    return {'casual': casual, 'sick': sick, 'earned': earned};
  }

  /// Submits a leave request into `leaves` collection.
  static Future<String> submitLeave({
    required String uid,
    required String leaveType,
    required DateTime fromDate,
    required DateTime toDate,
    required int totalDays,
    required String reason,
  }) async {
    final employeeName = await _readEmployeeName(uid);
    final ref = await _db.collection('leaves').add({
      'uid': uid,
      'leaveType': leaveType,
      'employeeName': employeeName,
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'totalDays': totalDays,
      'reason': reason,
      'status': 'pending',
      'appliedOn': FieldValue.serverTimestamp(),
      'reviewedBy': null,
    });

    final normalizedLeaveType = _normalizeLeaveType(leaveType);
    final dateRange = _dateRangeLabel(fromDate, toDate);
    final dayLabel = totalDays == 1 ? '1 Day' : '$totalDays Days';

    try {
      await NotificationService.send(
        userId: uid,
        title: 'Leave Request Submitted',
        message: 'Your $normalizedLeaveType leave request has been submitted',
        subtitle: '$dateRange · $dayLabel · Pending approval',
        type: NotificationService.typeLeavePending,
        relatedId: ref.id,
        extra: {'leaveId': ref.id},
      );

      await NotificationService.sendToAdmins(
        title: 'New Leave Request',
        message: '$employeeName submitted a $normalizedLeaveType leave request',
        subtitle: '$dateRange · $dayLabel',
        type: NotificationService.typeLeaveRequest,
        relatedId: ref.id,
        extra: {'leaveId': ref.id, 'employeeUid': uid},
      );
    } catch (_) {
      // Do not fail leave submission if notification write is unavailable.
    }

    return ref.id;
  }

  /// Streams employee's leave history in descending applied date order.
  static Stream<List<Map<String, dynamic>>> streamMyLeaves(String uid) {
    return _db.collection('leaves').snapshots().map((snap) {
      final rows = snap.docs.map((d) => {'id': d.id, ...d.data()}).where((row) {
        final rowUid = (row['uid'] as String?)?.trim();
        final rowUserId = (row['userId'] as String?)?.trim();
        return rowUid == uid || rowUserId == uid;
      }).toList();
      rows.sort((a, b) {
        final aDate =
            _asDateTime(a['appliedOn']) ??
            _asDateTime(a['fromDate']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            _asDateTime(b['appliedOn']) ??
            _asDateTime(b['fromDate']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return rows;
    });
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Future<String> _readEmployeeName(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final name = ((userDoc.data()?['name'] as String?) ?? '').trim();
    return name.isEmpty ? 'Employee' : name;
  }

  static String _normalizeLeaveType(String leaveType) {
    final normalized = leaveType.trim();
    if (normalized.isEmpty) return 'leave';
    return '${normalized[0].toUpperCase()}${normalized.substring(1).toLowerCase()}';
  }

  static String _dateRangeLabel(DateTime fromDate, DateTime toDate) {
    final from = _formatShortDate(fromDate);
    final to = _formatShortDate(toDate);
    if (fromDate.year == toDate.year &&
        fromDate.month == toDate.month &&
        fromDate.day == toDate.day) {
      return from;
    }
    return '$from - $to';
  }

  static String _formatShortDate(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Returns approved leave count for a user in a given calendar month.
  static Future<int> getApprovedLeaveCountForMonth(
    String uid,
    DateTime month,
  ) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final snap = await _db
        .collection('leaves')
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'approved')
        .where('fromDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('fromDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .count()
        .get();
    return snap.count ?? 0;
  }

  // ── Leave Types ──────────────────────────────────────────

  /// Returns all active leave types.
  static Future<List<Map<String, dynamic>>> getLeaveTypes() async {
    final snap = await _db
        .collection('leaveTypes')
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Seeds default leave types. Run once during admin setup.
  static Future<void> seedLeaveTypes() async {
    final defaults = [
      {'name': 'Casual Leave', 'maxDaysPerYear': 12, 'isPaid': true},
      {'name': 'Sick Leave', 'maxDaysPerYear': 6, 'isPaid': true},
      {'name': 'Earned Leave', 'maxDaysPerYear': 15, 'isPaid': true},
      {'name': 'Unpaid Leave', 'maxDaysPerYear': 365, 'isPaid': false},
    ];
    final batch = _db.batch();
    for (final lt in defaults) {
      final ref = _db.collection('leaveTypes').doc();
      batch.set(ref, {...lt, 'isActive': true});
    }
    await batch.commit();
  }

  // ── Leave Requests ───────────────────────────────────────

  /// Submits a new leave request.
  static Future<String> applyLeave({
    required String userId,
    required String userName,
    required String leaveTypeId,
    required String leaveTypeName,
    required String fromDate,
    required String toDate,
    required int totalDays,
    required String reason,
  }) async {
    final ref = await _db.collection('leaveRequests').add({
      'userId': userId,
      'userName': userName,
      'leaveTypeId': leaveTypeId,
      'leaveTypeName': leaveTypeName,
      'fromDate': fromDate,
      'toDate': toDate,
      'totalDays': totalDays,
      'reason': reason,
      'status': 'pending',
      'approvedBy': null,
      'approvedOn': null,
      'comments': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Returns all leave requests for [userId].
  static Future<List<Map<String, dynamic>>> getMyLeaves(String userId) async {
    final snap = await _db
        .collection('leaveRequests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Admin: returns all pending leave requests.
  static Future<List<Map<String, dynamic>>> getPendingLeaves() async {
    final snap = await _db
        .collection('leaveRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt')
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Admin: all leave requests across all users.
  static Future<List<Map<String, dynamic>>> getAllLeaves() async {
    final snap = await _db
        .collection('leaveRequests')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Admin: approve or reject a leave request.
  static Future<void> updateLeaveStatus({
    required String requestId,
    required String status, // 'approved' or 'rejected'
    required String approvedBy,
    String? comments,
  }) async {
    await _db.collection('leaveRequests').doc(requestId).update({
      'status': status,
      'approvedBy': approvedBy,
      'approvedOn': FieldValue.serverTimestamp(),
      'comments': comments,
    });
  }
}
