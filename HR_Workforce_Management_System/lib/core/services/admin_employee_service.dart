import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class AdminEmployeeService {
  static final _db = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> getEmployees({
    String? department,
    String? status,
    String? designation,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection('users')
        .where('role', isEqualTo: 'employee');

    if (department != null && department.trim().isNotEmpty) {
      query = query.where('department', isEqualTo: department.trim());
    }

    if (designation != null && designation.trim().isNotEmpty) {
      query = query.where('designation', isEqualTo: designation.trim());
    }

    if (status != null && status.trim().isNotEmpty) {
      query = query.where('status', isEqualTo: status.trim().toLowerCase());
    }

    final snap = await query.get();
    final rows = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    rows.sort((a, b) {
      final an = (a['name'] as String?)?.toLowerCase() ?? '';
      final bn = (b['name'] as String?)?.toLowerCase() ?? '';
      return an.compareTo(bn);
    });
    return rows;
  }

  static Future<Map<String, dynamic>?> getEmployeeById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  static Future<Map<String, dynamic>> createEmployee({
    required String adminUid,
    required String name,
    required String email,
    required String defaultPassword,
    required String employeeId,
    required String designation,
    required String department,
    required String phone,
    required String location,
    required String manager,
    required String employmentType,
    required num basicSalary,
    int casualLeaveBalance = 12,
    int sickLeaveBalance = 10,
    int earnedLeaveBalance = 20,
  }) async {
    final appName = 'admin-create-${DateTime.now().millisecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: defaultPassword,
      );

      final uid = credential.user!.uid;
      final normalizedName = name.trim();
      final now = FieldValue.serverTimestamp();

      await _db.collection('users').doc(uid).set({
        'name': normalizedName,
        'employeeId': employeeId.trim(),
        'designation': designation.trim(),
        'department': department.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'photoUrl': '',
        'joiningDate': now,
        'manager': manager.trim(),
        'location': location.trim(),
        'employmentType': employmentType.trim().toLowerCase(),
        'status': 'active',
        'isActive': true,
        'role': 'employee',
        'basicSalary': basicSalary,
        'casualLeaveBalance': casualLeaveBalance,
        'sickLeaveBalance': sickLeaveBalance,
        'earnedLeaveBalance': earnedLeaveBalance,
        'createdBy': adminUid,
        'createdAt': now,
      });

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

      await _db.collection('activityLog').add({
        'message': '$normalizedName was added as a new employee',
        'type': 'employee',
        'employeeName': normalizedName,
        'timestamp': FieldValue.serverTimestamp(),
        'uid': uid,
        'createdBy': adminUid,
      });

      return {'uid': uid, 'email': email.trim(), 'name': normalizedName};
    } finally {
      await secondaryAuth.signOut();
      await secondaryApp.delete();
    }
  }

  static Future<void> updateEmployee(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    await _db.collection('users').doc(uid).update(fields);
  }

  static Future<void> deactivateEmployee({
    required String uid,
    required String adminUid,
  }) async {
    final user = await getEmployeeById(uid);
    await _db.collection('users').doc(uid).update({
      'status': 'inactive',
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('activityLog').add({
      'message': '${(user?['name'] as String?) ?? 'Employee'} was deactivated',
      'type': 'employee',
      'employeeName': (user?['name'] as String?) ?? 'Employee',
      'timestamp': FieldValue.serverTimestamp(),
      'uid': uid,
      'createdBy': adminUid,
    });
  }
}
