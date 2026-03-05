import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

/// Handles authentication and user profile operations via Firebase.
///
/// Firebase Auth stores credentials using the pattern:
///   email = "username@hrapp.internal"
/// so users only ever see/type their plain username.
class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// Signs in with [username] + [password].
  /// Fetches the user profile document from the `users` Firestore collection.
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final email = '${username.trim().toLowerCase()}@hrapp.internal';
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final doc = await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .get();
      if (!doc.exists) throw Exception('User profile not found in database.');
      return UserModel.fromFirestore(cred.user!.uid, doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  /// Creates a new user (admin only). Stores profile in Firestore.
  Future<UserModel> createUser({
    required String username,
    required String name,
    required String password,
    required String role,
    String? phone,
    String? department,
  }) async {
    final email = '${username.trim().toLowerCase()}@hrapp.internal';
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = UserModel(
        id: cred.user!.uid,
        name: name,
        username: username.trim().toLowerCase(),
        email: email,
        role: role,
        phone: phone,
        department: department,
      );
      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(user.toFirestore());
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  /// Signs the current user out.
  Future<void> logout() => _auth.signOut();

  /// Returns the currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  /// Re-fetches the current user's Firestore profile.
  Future<UserModel?> fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(user.uid, doc.data()!);
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Username not found.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid username or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Authentication failed ($code).';
    }
  }
}

  /// Registers a new user via the backend.
  ///
  /// Sends name, email, password, role to POST /api/register.
  /// The user is persisted in MSSQL.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role.toLowerCase(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      return UserModel(
        id: data['id'],
        name: data['name'],
        email: data['email'],
        role: data['role'],
        password: password,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final detail = e.response?.data['detail'] ?? 'Registration failed.';
        throw Exception(detail);
      }
      throw Exception('Cannot reach server. Is the backend running?');
    }
  }
}
