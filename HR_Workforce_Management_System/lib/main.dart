import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  /// Entry point of the application.
  /// Initializes ProviderScope for Riverpod state management.
  runApp(const ProviderScope(child: SmartWorkforceApp()));
}

/// The root widget of the Smart Workforce Visibility and Task Management App.
class SmartWorkforceApp extends ConsumerWidget {
  const SmartWorkforceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Smart Workforce CHeck Visibility',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
