import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';

import '../../firebase_options.dart';
import 'notification_service.dart';

class AdminEmployeeService {
  static final _db = FirebaseFirestore.instance;
  static const String _emailDomain = 'hrapp.internal';
  static const String _defaultLocation = 'Mumbai Office';
  static const int _defaultConveyance = 9000;
  static const int _defaultCasualLeave = 12;
  static const int _defaultSickLeave = 10;
  static const int _defaultEarnedLeave = 20;

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

  static Future<String> generateUniqueEmployeeId({
    String prefix = 'EQT',
  }) async {
    final random = Random.secure();
    for (var i = 0; i < 40; i++) {
      final id = '$prefix${100 + random.nextInt(900)}';
      final exists = await _db
          .collection('users')
          .where('employeeId', isEqualTo: id)
          .limit(1)
          .get();
      if (exists.docs.isEmpty) {
        return id;
      }
    }
    throw const AdminEmployeeException(
      'Unable to generate unique employee ID.',
    );
  }

  static Future<Map<String, dynamic>> getEmployeeCreateDefaults(
    String adminUid,
  ) async {
    final adminDoc = await _db.collection('users').doc(adminUid).get();
    final adminName =
        ((adminDoc.data()?['name'] as String?) ?? '').trim().isEmpty
        ? 'Administrator'
        : (adminDoc.data()!['name'] as String).trim();

    final rulesSnapshot = await _db.collection('hrRules').get();
    final rules = {
      for (final doc in rulesSnapshot.docs)
        doc.id.trim().toLowerCase(): ((doc.data()['value'] as String?) ?? '')
            .trim(),
    };

    int parseRuleInt(List<String> keys, int fallback) {
      for (final key in keys) {
        final raw = rules[key.trim().toLowerCase()];
        final parsed = int.tryParse(raw ?? '');
        if (parsed != null && parsed >= 0) {
          return parsed;
        }
      }
      return fallback;
    }

    String parseRuleString(List<String> keys, String fallback) {
      for (final key in keys) {
        final raw = rules[key.trim().toLowerCase()];
        if (raw != null && raw.isNotEmpty) {
          return raw;
        }
      }
      return fallback;
    }

    return {
      'managerName': adminName,
      'location': parseRuleString(const [
        'office_location',
        'location',
      ], _defaultLocation),
      'conveyance': parseRuleInt(const [
        'conveyance',
        'default_conveyance',
      ], _defaultConveyance),
      'casualLeaveBalance': parseRuleInt(const [
        'defaultcasualleave',
        'default_casual_leave',
        'default_casual_leave_balance',
      ], _defaultCasualLeave),
      'sickLeaveBalance': parseRuleInt(const [
        'defaultsickleave',
        'default_sick_leave',
        'default_sick_leave_balance',
      ], _defaultSickLeave),
      'earnedLeaveBalance': parseRuleInt(const [
        'defaultearnedleave',
        'default_earned_leave',
        'default_earned_leave_balance',
      ], _defaultEarnedLeave),
    };
  }

  static Future<Map<String, dynamic>> createEmployee({
    required String adminUid,
    required String fullName,
    required String username,
    required String password,
    required String employeeId,
    required String designation,
    required String department,
    required String phone,
    required DateTime joiningDate,
    required String bankLast4,
    required String location,
    required String manager,
    required String employmentType,
    required double baseSalary,
    required int conveyance,
    required int casualLeaveBalance,
    required int sickLeaveBalance,
    required int earnedLeaveBalance,
  }) async {
    final normalizedFullName = fullName.trim();
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedPhone = phone.trim();
    final normalizedLocation = location.trim();
    final normalizedManager = manager.trim();
    final normalizedDepartment = department.trim();
    final normalizedDesignation = designation.trim();
    final normalizedEmploymentType = employmentType.trim();
    final normalizedEmployeeId = employeeId.trim().toUpperCase();
    final normalizedBankLast4 = bankLast4.trim();

    if (normalizedFullName.isEmpty) {
      throw const AdminEmployeeException('Full name is required.');
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(normalizedPhone)) {
      throw const AdminEmployeeException(
        'Enter a valid 10 digit phone number.',
      );
    }
    if (!RegExp(r'^[a-z0-9._]+$').hasMatch(normalizedUsername)) {
      throw const AdminEmployeeException(
        'Username can only contain lowercase letters, numbers, dot and underscore.',
      );
    }
    if (password.length < 6) {
      throw const AdminEmployeeException(
        'Password must be at least 6 characters.',
      );
    }
    if (normalizedBankLast4.isNotEmpty &&
        !RegExp(r'^[0-9]{4}$').hasMatch(normalizedBankLast4)) {
      throw const AdminEmployeeException(
        'Bank last 4 digits must be exactly 4 digits.',
      );
    }

    final usernameTaken = await _db
        .collection('users')
        .where('username', isEqualTo: normalizedUsername)
        .limit(1)
        .get();
    if (usernameTaken.docs.isNotEmpty) {
      throw const AdminEmployeeException('This username is already in use.');
    }

    final email = '$normalizedUsername@$_emailDomain';
    final hra = double.parse((baseSalary * 0.40).toStringAsFixed(2));

    final appName = 'admin-create-${DateTime.now().millisecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    UserCredential? credential;

    try {
      credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final now = FieldValue.serverTimestamp();

      await _db.collection('users').doc(uid).set({
        'name': normalizedFullName,
        'username': normalizedUsername,
        'employeeId': normalizedEmployeeId,
        'designation': normalizedDesignation,
        'department': normalizedDepartment,
        'email': email,
        'phone': normalizedPhone,
        'photoUrl': '',
        'joiningDate': Timestamp.fromDate(joiningDate),
        'manager': normalizedManager,
        'location': normalizedLocation,
        'employmentType': normalizedEmploymentType,
        'status': 'active',
        'isActive': true,
        'role': 'employee',
        'baseSalary': baseSalary,
        'basicSalary': baseSalary,
        'hra': hra,
        'conveyance': conveyance,
        'bankLast4': normalizedBankLast4,
        'casualLeaveBalance': casualLeaveBalance,
        'sickLeaveBalance': sickLeaveBalance,
        'earnedLeaveBalance': earnedLeaveBalance,
        'createdBy': adminUid,
        'createdAt': now,
      });

      await _db.collection('activityLog').add({
        'message':
            'New employee $normalizedFullName ($normalizedEmployeeId) added',
        'type': 'new_employee',
        'employeeName': normalizedFullName,
        'timestamp': FieldValue.serverTimestamp(),
        'uid': uid,
        'createdBy': adminUid,
      });

      try {
        await NotificationService.send(
          userId: adminUid,
          title: 'New Employee Added Successfully',
          message:
              '$normalizedFullName · $normalizedEmployeeId · $normalizedDesignation',
          type: NotificationService.typeNewEmployee,
          relatedId: uid,
        );
      } catch (_) {
        // Employee creation already succeeded; keep flow resilient.
      }

      return {
        'uid': uid,
        'email': email,
        'name': normalizedFullName,
        'employeeId': normalizedEmployeeId,
      };
    } on FirebaseAuthException catch (e) {
      throw AdminEmployeeException(_mapCreateEmployeeAuthError(e.code));
    } catch (_) {
      if (credential?.user != null) {
        await credential!.user!.delete();
      }
      rethrow;
    } finally {
      await secondaryAuth.signOut();
      await secondaryApp.delete();
    }
  }

  static String _mapCreateEmployeeAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This username is already in use.';
      case 'invalid-email':
        return 'Username generated an invalid email. Please check username.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Check your internet connection.';
      default:
        return 'Something went wrong, please try again.';
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

class AdminEmployeeException implements Exception {
  const AdminEmployeeException(this.message);

  final String message;

  @override
  String toString() => message;
}
