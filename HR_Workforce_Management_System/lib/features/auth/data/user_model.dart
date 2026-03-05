/// Data model representing an HR system user.
///
/// [id] is the Firebase Auth UID.
/// [role] is either 'admin' or 'employee'.
class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String role;
  final String? phone;
  final String? designationId;
  final String? department;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    this.phone,
    this.designationId,
    this.department,
    this.isActive = true,
  });

  factory UserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserModel(
      id: uid,
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'employee',
      phone: data['phone'],
      designationId: data['designationId'],
      department: data['department'],
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'username': username,
    'email': email,
    'role': role,
    'phone': phone,
    'designationId': designationId,
    'department': department,
    'isActive': isActive,
  };

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? role,
    String? phone,
    String? designationId,
    String? department,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      designationId: designationId ?? this.designationId,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
    );
  }
}
