import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore collection: `notifications`
///
/// Document fields:
///   userId       – String  – owner of the notification
///   title        – String  – bold headline
///   message      – String  – subtitle/body text
///   type         – String  – see [NotifType] constants below
///   isRead       – bool
///   relatedId    – String? – e.g. leave request id, monthYear, etc.
///   createdAt    – Timestamp
class NotificationService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _items(String userId) {
    return _db.collection('notifications').doc(userId).collection('items');
  }

  // ─── Notification type constants ──────────────────────────────────────────

  static const String typeLeaveApproved = 'leave_approved';
  static const String typeLeaveRejected = 'leave_rejected';
  static const String typeLeavePending = 'leave_pending';
  static const String typeLeaveBalanceLow = 'leave_balance_low';
  static const String typeLeaveRequest = 'leave_request'; // admin view
  static const String typeAttendance = 'attendance';
  static const String typePayroll = 'payroll';
  static const String typePayrollReminder = 'payroll_reminder';
  static const String typeLate = 'late';
  static const String typeLateArrival = 'late_arrival';
  static const String typeAbsentSummary = 'absent_summary';
  static const String typeNewEmployee = 'new_employee'; // admin view
  static const String typeSystem = 'system';

  // ─── Reads ────────────────────────────────────────────────────────────────

  /// Returns all notifications for [userId], newest first.
  static Future<List<Map<String, dynamic>>> getNotifications(
    String userId,
  ) async {
    final nested = await _items(
      userId,
    ).orderBy('createdAt', descending: true).get();
    return nested.docs.map((d) => _mapNotifDoc(d, userId: userId)).toList();
  }

  /// Real-time stream of notifications for [userId], newest first.
  static Stream<List<Map<String, dynamic>>> streamNotifications(String userId) {
    return _items(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => _mapNotifDoc(d, userId: userId)).toList(),
        );
  }

  /// Returns the unread notification count for [userId].
  static Future<int> getUnreadCount(String userId) async {
    final nested = await _items(
      userId,
    ).where('isRead', isEqualTo: false).count().get();
    return nested.count ?? 0;
  }

  /// Real-time stream of the unread count for [userId].
  static Stream<int> streamUnreadCount(String userId) {
    return _items(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ─── Mutations ────────────────────────────────────────────────────────────

  /// Marks a single notification as read.
  static Future<void> markRead(
    String notifId, {
    String? userId,
    String? refPath,
  }) async {
    if (refPath != null && refPath.isNotEmpty) {
      await _db.doc(refPath).update({'isRead': true});
      return;
    }

    if (userId != null && userId.isNotEmpty) {
      await _items(userId).doc(notifId).update({'isRead': true});
      return;
    }

    await _db.collection('notifications').doc(notifId).update({'isRead': true});
  }

  /// Marks all notifications for [userId] as read.
  static Future<void> markAllRead(String userId) async {
    final nested = await _items(userId).where('isRead', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in nested.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Sends a notification to a user.
  static Future<void> send({
    required String userId,
    required String title,
    required String message,
    String type = typeSystem,
    String? relatedId,
    String? subtitle,
    Map<String, dynamic>? extra,
  }) async {
    if (userId.trim().isEmpty) return;

    final payload = <String, dynamic>{
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'relatedId': relatedId,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (subtitle != null && subtitle.trim().isNotEmpty) {
      payload['subtitle'] = subtitle.trim();
    }
    if (extra != null && extra.isNotEmpty) {
      payload.addAll(extra);
    }

    await _items(userId).add(payload);
  }

  /// Sends one notification to all admins.
  static Future<void> sendToAdmins({
    required String title,
    required String message,
    String type = typeSystem,
    String? relatedId,
    String? subtitle,
    Map<String, dynamic>? extra,
  }) async {
    final adminUids = await getAdminUids();
    if (adminUids.isEmpty) return;

    final futures = adminUids.map(
      (uid) => send(
        userId: uid,
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
        subtitle: subtitle,
        extra: extra,
      ),
    );
    await Future.wait(futures);
  }

  /// Returns admin UIDs from users collection.
  static Future<List<String>> getAdminUids() async {
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .where('isActive', isEqualTo: true)
          .get();
    } catch (_) {
      snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
    }

    if (snap.docs.isEmpty) {
      return const [];
    }

    return snap.docs
        .map((doc) => doc.id)
        .where((id) => id.trim().isNotEmpty)
        .toList(growable: false);
  }

  static Map<String, dynamic> _mapNotifDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String userId,
  }) {
    final data = doc.data();
    final message = (data['message'] as String?) ?? '';
    final title = ((data['title'] as String?) ?? '').trim();
    return {
      'id': doc.id,
      ...data,
      'userId': userId,
      'title': title.isEmpty
          ? _titleFromType(data['type'] as String?, message)
          : title,
      '__refPath': doc.reference.path,
    };
  }

  static String _titleFromType(String? type, String message) {
    switch ((type ?? '').toLowerCase()) {
      case typeLeaveApproved:
        return 'Leave Approved';
      case typeLeaveRejected:
        return 'Leave Rejected';
      case typeLeavePending:
        return 'Leave Request Submitted';
      case typeLeaveBalanceLow:
        return 'Leave Balance Low';
      case typeLeaveRequest:
        return 'New Leave Request';
      case typePayroll:
        return 'Payroll Update';
      case typePayrollReminder:
        return 'Payroll Reminder';
      case typeAttendance:
        return 'Attendance Update';
      case typeLate:
      case typeLateArrival:
        return 'Late Mark Alert';
      case typeAbsentSummary:
        return 'Absent Summary';
      case typeNewEmployee:
        return 'New Employee';
      default:
        return message.isEmpty ? 'Notification' : 'Update';
    }
  }
}
