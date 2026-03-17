import 'package:cloud_firestore/cloud_firestore.dart';

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

  // ── Employee Leave V2 (`leaves`) ────────────────────────

  /// Returns remaining balances from `users/{uid}`.
  static Future<Map<String, int>> getUserLeaveBalances(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() ?? <String, dynamic>{};
    return {
      'casual':
          (data['casualLeaveBalance'] as num?)?.toInt() ??
          (data['casualLeave'] as num?)?.toInt() ??
          0,
      'sick':
          (data['sickLeaveBalance'] as num?)?.toInt() ??
          (data['sickLeave'] as num?)?.toInt() ??
          0,
      'earned':
          (data['earnedLeaveBalance'] as num?)?.toInt() ??
          (data['earnedLeave'] as num?)?.toInt() ??
          0,
    };
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
    final ref = await _db.collection('leaves').add({
      'uid': uid,
      'leaveType': leaveType,
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'totalDays': totalDays,
      'reason': reason,
      'status': 'pending',
      'appliedOn': FieldValue.serverTimestamp(),
      'reviewedBy': null,
    });
    return ref.id;
  }

  /// Streams employee's leave history in descending applied date order.
  static Stream<List<Map<String, dynamic>>> streamMyLeaves(String uid) {
    return _db
        .collection('leaves')
        .where('uid', isEqualTo: uid)
        .orderBy('appliedOn', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        });
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
