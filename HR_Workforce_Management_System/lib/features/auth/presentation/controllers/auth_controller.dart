import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/user_model.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({this.isLoading = false, this.user, this.errorMessage});

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

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController();
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  final _repo = AuthRepository();

  /// Signs in with [username] + [password].
  /// Returns the user's role ('admin' / 'employee') on success, null on failure.
  Future<String?> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.login(username: username, password: password);
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

  /// Signs out the current user and clears state.
  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  /// Re-fetches the Firebase user profile (e.g. on app restart).
  Future<void> restoreSession() async {
    final user = await _repo.fetchCurrentUser();
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }
}
