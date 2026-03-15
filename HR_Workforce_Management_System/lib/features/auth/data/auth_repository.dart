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
    final identifier = username.trim();
    final email = await _resolveLoginEmail(identifier);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _loadUserProfile(
        user: cred.user!,
        loginIdentifier: identifier,
        signedInEmail: email,
      );
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
    try {
      return await _loadUserProfile(user: user);
    } on Exception {
      return null;
    }
  }

  Future<String> _resolveLoginEmail(String identifier) async {
    final cleaned = identifier.trim();
    if (cleaned.contains('@')) {
      return cleaned.toLowerCase();
    }

    final users = _firestore.collection('users');
    final directUsername = await users
        .where('username', isEqualTo: cleaned)
        .limit(1)
        .get();
    if (directUsername.docs.isNotEmpty) {
      final data = directUsername.docs.first.data();
      final email = (data['email'] as String?)?.trim();
      if (email != null && email.isNotEmpty) {
        return email.toLowerCase();
      }
    }

    final lowerUsername = cleaned.toLowerCase();
    if (lowerUsername != cleaned) {
      final normalizedUsername = await users
          .where('username', isEqualTo: lowerUsername)
          .limit(1)
          .get();
      if (normalizedUsername.docs.isNotEmpty) {
        final data = normalizedUsername.docs.first.data();
        final email = (data['email'] as String?)?.trim();
        if (email != null && email.isNotEmpty) {
          return email.toLowerCase();
        }
      }
    }

    return '$lowerUsername@hrapp.internal';
  }

  Future<UserModel> _loadUserProfile({
    required User user,
    String? loginIdentifier,
    String? signedInEmail,
  }) async {
    final users = _firestore.collection('users');

    final uidDoc = await users.doc(user.uid).get();
    if (uidDoc.exists) {
      return UserModel.fromFirestore(uidDoc.id, uidDoc.data()!);
    }

    final email = (signedInEmail ?? user.email)?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      final emailDoc = await users
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (emailDoc.docs.isNotEmpty) {
        final doc = emailDoc.docs.first;
        return UserModel.fromFirestore(doc.id, doc.data());
      }
    }

    final identifier = loginIdentifier?.trim();
    if (identifier != null && identifier.isNotEmpty) {
      final usernameDoc = await users
          .where('username', isEqualTo: identifier)
          .limit(1)
          .get();
      if (usernameDoc.docs.isNotEmpty) {
        final doc = usernameDoc.docs.first;
        return UserModel.fromFirestore(doc.id, doc.data());
      }

      final lower = identifier.toLowerCase();
      if (lower != identifier) {
        final normalizedDoc = await users
            .where('username', isEqualTo: lower)
            .limit(1)
            .get();
        if (normalizedDoc.docs.isNotEmpty) {
          final doc = normalizedDoc.docs.first;
          return UserModel.fromFirestore(doc.id, doc.data());
        }
      }
    }

    throw Exception('User profile not found in database.');
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
