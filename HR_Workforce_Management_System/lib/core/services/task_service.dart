import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore collection: `tasks`
///
/// Document fields:
///   title, description, assignedTo (userId), assignedToName,
///   assignedBy (userId), assignedByName,
///   status ('pending'|'in_progress'|'completed'|'on_hold'),
///   priority ('low'|'medium'|'high'),
///   dueDate (YYYY-MM-DD), createdAt, updatedAt
///
/// Subcollection: tasks/{taskId}/workdone
///   userId, note, hours, loggedAt
class TaskService {
  static final _db = FirebaseFirestore.instance;

  // ── Tasks ────────────────────────────────────────────────

  /// Creates a new task. Returns the new document ID.
  static Future<String> createTask({
    required String title,
    required String description,
    required String assignedTo,
    required String assignedToName,
    required String assignedBy,
    required String assignedByName,
    required String dueDate,
    String priority = 'medium',
  }) async {
    final ref = await _db.collection('tasks').add({
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedBy': assignedBy,
      'assignedByName': assignedByName,
      'status': 'pending',
      'priority': priority,
      'dueDate': dueDate,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Returns tasks assigned to [userId].
  static Future<List<Map<String, dynamic>>> getMyTasks(String userId) async {
    final snap = await _db
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Returns count of completed tasks assigned to [userId].
  static Future<int> getCompletedTaskCount(String userId) async {
    final snap = await _db
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Admin: returns all tasks.
  static Future<List<Map<String, dynamic>>> getAllTasks() async {
    final snap = await _db
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Updates the status of a task.
  static Future<void> updateStatus(String taskId, String status) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Work Done Logs ───────────────────────────────────────

  /// Logs work done on a task.
  static Future<void> logWorkDone({
    required String taskId,
    required String userId,
    required String note,
    required double hours,
  }) async {
    await _db.collection('tasks').doc(taskId).collection('workdone').add({
      'userId': userId,
      'note': note,
      'hours': hours,
      'loggedAt': FieldValue.serverTimestamp(),
    });
    // Update task status to in_progress if still pending
    await _db.collection('tasks').doc(taskId).update({
      'status': 'in_progress',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns all work logs for a task.
  static Future<List<Map<String, dynamic>>> getWorkLogs(String taskId) async {
    final snap = await _db
        .collection('tasks')
        .doc(taskId)
        .collection('workdone')
        .orderBy('loggedAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
