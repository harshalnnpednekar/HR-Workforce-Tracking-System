import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/login_controller.dart';

/// LoginScreen is the entry point for user authentication.
///
/// It provides a responsive login form with email and password
/// fields, form validation, and role-based navigation after
/// a mock authentication call.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles login button press: validates the form, calls the
  /// [LoginController], and navigates based on the returned role.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors above.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final role = await ref
        .read(loginControllerProvider.notifier)
        .authenticate(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

    if (!mounted) return;

    if (role == 'admin') {
      context.go('/admin-dashboard');
    } else {
      context.go('/employee-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loginControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400.0),
              child: Card(
                elevation: 8,
                shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28.0,
                    vertical: 36.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- Header Icon ---
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            size: 48,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- Welcome Text ---
                        Text(
                          'Smart Workforce Portal',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 32),

                        // --- Email Field ---
                        _LoginTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'you@example.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required.';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // --- Password Field ---
                        _LoginTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password is required.';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // --- Login Button ---
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A reusable private widget that reduces boilerplate for the
/// [TextFormField] inputs on the login screen.
class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
