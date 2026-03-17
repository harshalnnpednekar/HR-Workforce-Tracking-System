import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLeaveManagementService {
  static final _db = FirebaseFirestore.instance;

  static Stream<int> streamPendingCount() {
    return _db
        .collection('leaves')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  static Stream<List<Map<String, dynamic>>> streamLeavesByStatus(
    String status,
  ) {
    final normalized = status.toLowerCase();
    final orderField = normalized == 'pending' ? 'appliedOn' : 'reviewedAt';

    return _db
        .collection('leaves')
        .where('status', isEqualTo: normalized)
        .orderBy(orderField, descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        });
  }

  static Future<void> approveLeave({
    required String leaveId,
    required String adminUid,
    required String employeeUid,
    required String employeeName,
    required String leaveType,
    required int totalDays,
    required String dateRangeLabel,
  }) async {
    final leaveRef = _db.collection('leaves').doc(leaveId);
    final userRef = _db.collection('users').doc(employeeUid);
    final notifRef = _db
        .collection('notifications')
        .doc(employeeUid)
        .collection('items')
        .doc();
    final activityRef = _db.collection('activityLog').doc();

    final batch = _db.batch();
    batch.update(leaveRef, {
      'status': 'approved',
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': '',
    });

    final balanceField = _balanceFieldForLeaveType(leaveType);
    if (balanceField != null) {
      batch.update(userRef, {balanceField: FieldValue.increment(-totalDays)});
    }

    batch.set(notifRef, {
      'message':
          'Your ${_normalizeLeaveType(leaveType)} leave ($dateRangeLabel) was approved',
      'type': 'leave',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(activityRef, {
      'message': '$employeeName leave request was approved',
      'type': 'leave',
      'employeeName': employeeName,
      'timestamp': FieldValue.serverTimestamp(),
      'uid': employeeUid,
      'createdBy': adminUid,
    });

    await batch.commit();
  }

  static Future<void> rejectLeave({
    required String leaveId,
    required String adminUid,
    required String employeeUid,
    required String employeeName,
    required String leaveType,
    required String dateRangeLabel,
    String rejectionReason = '',
  }) async {
    final leaveRef = _db.collection('leaves').doc(leaveId);
    final notifRef = _db
        .collection('notifications')
        .doc(employeeUid)
        .collection('items')
        .doc();
    final activityRef = _db.collection('activityLog').doc();

    final batch = _db.batch();
    batch.update(leaveRef, {
      'status': 'rejected',
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': rejectionReason,
    });

    batch.set(notifRef, {
      'message':
          'Your ${_normalizeLeaveType(leaveType)} leave ($dateRangeLabel) was rejected',
      'type': 'leave',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(activityRef, {
      'message': '$employeeName leave request was rejected',
      'type': 'leave',
      'employeeName': employeeName,
      'timestamp': FieldValue.serverTimestamp(),
      'uid': employeeUid,
      'createdBy': adminUid,
    });

    await batch.commit();
  }

  static String? _balanceFieldForLeaveType(String leaveType) {
    final key = leaveType.trim().toLowerCase();
    switch (key) {
      case 'casual':
        return 'casualLeaveBalance';
      case 'sick':
        return 'sickLeaveBalance';
      case 'annual':
      case 'earned':
        return 'earnedLeaveBalance';
      default:
        return null;
    }
  }

  static String _normalizeLeaveType(String leaveType) {
    final key = leaveType.trim();
    if (key.isEmpty) return 'leave';
    return '${key[0].toUpperCase()}${key.substring(1).toLowerCase()}';
  }
}
