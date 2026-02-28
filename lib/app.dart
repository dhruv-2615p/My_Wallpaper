import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_strings.dart';
import 'main.dart' show storageServiceProvider;

/// Root MaterialApp widget.
class GyroWallApp extends ConsumerWidget {
  const GyroWallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final themeMode = storage.themeMode;
    final isOnboardingDone = storage.isOnboardingDone;

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _resolveThemeMode(themeMode),
      initialRoute: isOnboardingDone ? AppRouter.home : AppRouter.onboarding,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }

  ThemeMode _resolveThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
