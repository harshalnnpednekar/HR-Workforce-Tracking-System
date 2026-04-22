import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticate({
    String reason = 'Verify identity to continue',
  }) async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      final canAuth = canCheckBiometrics || isDeviceSupported;
      if (!canAuth) {
        // If lock screen auth is unavailable, allow app flow.
        return true;
      }

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
