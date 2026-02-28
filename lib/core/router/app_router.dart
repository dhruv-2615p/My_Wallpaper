import 'package:flutter/material.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/gallery/search_screen.dart';
import '../../features/preview/preview_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../models/wallpaper_model.dart';

/// Simple named-route based router for GyroWall.
class AppRouter {
  AppRouter._();

  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String search = '/search';
  static const String preview = '/preview';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      case search:
        return MaterialPageRoute(
          builder: (_) => const SearchScreen(),
        );
      case preview:
        final wallpaper = routeSettings.arguments as WallpaperModel;
        return MaterialPageRoute(
          builder: (_) => PreviewScreen(wallpaper: wallpaper),
        );
      case settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
    }
  }
}
