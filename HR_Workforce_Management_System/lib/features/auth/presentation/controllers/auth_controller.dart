import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/user_model.dart';

/// Holds the complete authentication state: loading flag, current user, and
/// an optional error message.
class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Global Riverpod provider for [AuthController].
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});

/// Manages authentication state for both login and registration flows.
///
/// On success the [AuthState.user] is populated; on failure
/// [AuthState.errorMessage] is set so the UI can display feedback.
class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  final _repo = AuthRepository();

  /// Authenticates a user with [email] and [password].
  ///
  /// Returns the user's role string on success, or `null` on failure.
  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.login(email: email, password: password);
      state = state.copyWith(isLoading: false, user: user);
      return user.role;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// Registers a new user and adds them to the mock database.
  ///
  /// Returns the user's role string on success, or `null` on failure.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      state = state.copyWith(isLoading: false, user: user);
      return user.role;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// Clears the authenticated user (logout).
  void logout() {
    state = const AuthState();
  }
}
