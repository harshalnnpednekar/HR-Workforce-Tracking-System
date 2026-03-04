import 'package:dio/dio.dart';
import 'user_model.dart';

/// Repository that handles authentication via the FastAPI backend.
///
/// All requests go to the MSSQL-backed API running at [_baseUrl].
/// Falls back to a clear error message if the server is unreachable.
class AuthRepository {
  static const String _baseUrl = 'http://localhost:8000/api';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Authenticates an existing user via the backend.
  ///
  /// Sends email + password to POST /api/login.
  /// Throws on invalid credentials or server errors.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
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
        final detail = e.response?.data['detail'] ?? 'Login failed.';
        throw Exception(detail);
      }
      throw Exception('Cannot reach server. Is the backend running?');
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
