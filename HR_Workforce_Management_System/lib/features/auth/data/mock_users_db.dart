import 'user_model.dart';

/// The mutable in-memory mock database.
///
/// Pre-populated with a single admin user.  New users are dynamically
/// appended at runtime via the auth repository's `register` method.
final List<UserModel> mockDatabase = [
  const UserModel(
    id: 'admin-1',
    name: 'System Admin',
    email: 'admin@hr.com',
    role: 'admin',
    password: 'password123',
  ),
];
