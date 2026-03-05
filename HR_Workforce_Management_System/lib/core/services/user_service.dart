import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore collection: `users`
///
/// Document ID = Firebase Auth UID
/// Document fields:
///   name, username, email, role ('admin'|'employee'),
///   phone, designationId, department, isActive, joinDate
class UserService {
  static final _db = FirebaseFirestore.instance;

  /// Returns the profile document for [uid].
  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  /// Admin: returns all active employees (role = 'employee').
  static Future<List<Map<String, dynamic>>> getAllEmployees() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'employee')
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Admin: returns all users regardless of role.
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Updates profile fields for [uid].
  static Future<void> updateProfile(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    await _db.collection('users').doc(uid).update(fields);
  }

  /// Soft-deletes a user (sets isActive = false).
  static Future<void> deactivateUser(String uid) async {
    await _db.collection('users').doc(uid).update({'isActive': false});
  }
}
