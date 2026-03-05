import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/employee/presentation/screens/employee_dashboard_screen.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final isLoginPage = state.matchedLocation == '/login';

      // If not signed in, go to login
      if (firebaseUser == null) {
        return isLoginPage ? null : '/login';
      }

      // If signed in and on login page, redirect to the appropriate dashboard
      if (isLoginPage && authState.user != null) {
        return authState.user!.role == 'admin'
            ? '/admin-dashboard'
            : '/employee-dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/employee-dashboard',
        builder: (context, state) => const EmployeeDashboardScreen(),
      ),
    ],
  );
});
