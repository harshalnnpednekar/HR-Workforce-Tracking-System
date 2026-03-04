/// Data model representing a user in the system.
///
/// Holds the user's unique [id], display [name], login [email],
/// [role] (either 'admin' or 'employee'), and [password].
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String password;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.password,
  });

  /// Creates a copy of this [UserModel] with optional field overrides.
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      password: password ?? this.password,
    );
  }
}
