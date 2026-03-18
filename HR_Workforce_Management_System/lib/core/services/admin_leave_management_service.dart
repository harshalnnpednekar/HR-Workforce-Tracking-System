import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

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

    return _db
        .collection('leaves')
        .where('status', isEqualTo: normalized)
        .snapshots()
        .map((snap) {
          final rows = snap.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          rows.sort((a, b) {
            final aTime = _readSortDate(a, normalized);
            final bTime = _readSortDate(b, normalized);
            return bTime.compareTo(aTime);
          });
          return rows;
        });
  }

  static DateTime _readSortDate(Map<String, dynamic> row, String status) {
    if (status == 'pending') {
      return _asDateTime(row['appliedOn']) ??
          _asDateTime(row['fromDate']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    return _asDateTime(row['reviewedAt']) ??
        _asDateTime(row['appliedOn']) ??
        _asDateTime(row['fromDate']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _asDateTime(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
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
      'title': 'Leave Approved',
      'message':
          'Your ${_normalizeLeaveType(leaveType)} leave ($dateRangeLabel) was approved',
      'subtitle':
          '$dateRangeLabel · $totalDays ${totalDays == 1 ? 'Day' : 'Days'}',
      'type': NotificationService.typeLeaveApproved,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'relatedId': leaveId,
      'leaveId': leaveId,
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

    await _sendLowBalanceWarningIfNeeded(
      employeeUid: employeeUid,
      leaveType: leaveType,
    );
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
      'title': 'Leave Rejected',
      'message':
          'Your ${_normalizeLeaveType(leaveType)} leave ($dateRangeLabel) was rejected',
      'subtitle': rejectionReason.trim().isEmpty
          ? 'Reason not provided'
          : rejectionReason.trim(),
      'type': NotificationService.typeLeaveRejected,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'relatedId': leaveId,
      'leaveId': leaveId,
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

  static Future<void> _sendLowBalanceWarningIfNeeded({
    required String employeeUid,
    required String leaveType,
  }) async {
    final field = _balanceFieldForLeaveType(leaveType);
    if (field == null) return;

    final userDoc = await _db.collection('users').doc(employeeUid).get();
    final remaining = (userDoc.data()?[field] as num?)?.toInt();
    if (remaining == null || remaining > 2) {
      return;
    }

    try {
      await NotificationService.send(
        userId: employeeUid,
        title: 'Leave Balance Low',
        message:
            'Only $remaining ${_normalizeLeaveType(leaveType)} leave remaining',
        type: NotificationService.typeLeaveBalanceLow,
        subtitle: 'Please plan upcoming requests accordingly.',
      );
    } catch (_) {
      // Approval flow is already committed; skip warning on notification error.
    }
  }
}
