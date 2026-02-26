import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider that exposes the [LoginController].
final loginControllerProvider = StateNotifierProvider<LoginController, bool>((
  ref,
) {
  return LoginController();
});

/// LoginController manages the authentication UI state.
///
/// The state is a simple [bool] representing the `isLoading` status.
/// The [authenticate] method simulates a network call and returns
/// a role string based on the email input.
class LoginController extends StateNotifier<bool> {
  LoginController() : super(false);

  /// Whether an authentication request is currently in progress.
  bool get isLoading => state;

  /// Simulates an authentication request.
  ///
  /// Sets [isLoading] to `true`, waits for 2 seconds to mimic a
  /// network call, then determines the user role from the [email].
  ///
  /// Returns `'admin'` if the email contains "admin",
  /// otherwise returns `'employee'`.
  Future<String?> authenticate(String email, String password) async {
    state = true;

    // Simulate a network call
    await Future.delayed(const Duration(seconds: 2));

    state = false;

    if (email.toLowerCase().contains('admin')) {
      return 'admin';
    }
    return 'employee';
  }

  /// Simulates a logout request.
  Future<void> logout() async {
    state = true;
    await Future.delayed(const Duration(milliseconds: 500));
    state = false;
  }
}
