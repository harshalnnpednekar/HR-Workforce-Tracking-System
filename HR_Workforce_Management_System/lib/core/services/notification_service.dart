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

  // ─── Notification type constants ──────────────────────────────────────────

  static const String typeLeaveApproved = 'leave_approved';
  static const String typeLeaveRejected = 'leave_rejected';
  static const String typeLeaveRequest  = 'leave_request';   // admin view
  static const String typeAttendance    = 'attendance';
  static const String typePayroll       = 'payroll';
  static const String typeLate          = 'late';
  static const String typeNewEmployee   = 'new_employee';    // admin view
  static const String typeSystem        = 'system';

  // ─── Reads ────────────────────────────────────────────────────────────────

  /// Returns all notifications for [userId], newest first.
  static Future<List<Map<String, dynamic>>> getNotifications(
    String userId,
  ) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Real-time stream of notifications for [userId], newest first.
  static Stream<List<Map<String, dynamic>>> streamNotifications(
    String userId,
  ) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Returns the unread notification count for [userId].
  static Future<int> getUnreadCount(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Real-time stream of the unread count for [userId].
  static Stream<int> streamUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ─── Mutations ────────────────────────────────────────────────────────────

  /// Marks a single notification as read.
  static Future<void> markRead(String notifId) async {
    await _db
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  /// Marks all notifications for [userId] as read.
  static Future<void> markAllRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
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
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'relatedId': relatedId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
