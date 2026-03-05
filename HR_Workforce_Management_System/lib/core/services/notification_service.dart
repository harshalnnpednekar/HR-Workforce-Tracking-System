import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore collection: `notifications`
///
/// Document fields:
///   userId, title, message, type ('leave'|'task'|'attendance'|'general'),
///   isRead (bool), relatedId, createdAt
class NotificationService {
  static final _db = FirebaseFirestore.instance;

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

  /// Marks a single notification as read.
  static Future<void> markRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({'isRead': true});
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
    String type = 'general',
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
