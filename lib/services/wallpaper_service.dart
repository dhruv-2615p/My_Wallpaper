import 'package:flutter/foundation.dart';
import 'package:async_wallpaper/async_wallpaper.dart';

/// Encapsulates wallpaper-setting logic using async_wallpaper.
class WallpaperService {
  WallpaperService._();

  /// Location constants matching AsyncWallpaper.
  static const int homeScreen = AsyncWallpaper.HOME_SCREEN;
  static const int lockScreen = AsyncWallpaper.LOCK_SCREEN;
  static const int bothScreens = AsyncWallpaper.BOTH_SCREENS;

  /// Set wallpaper from a local file path.
  ///
  /// [filePath] must point to a valid PNG/JPG file.
  /// [location] is one of [homeScreen], [lockScreen], [bothScreens].
  static Future<bool> setWallpaper(String filePath, int location) async {
    try {
      final result = await AsyncWallpaper.setWallpaperFromFile(
        filePath: filePath,
        wallpaperLocation: location,
        goToHome: false,
      );
      debugPrint('WallpaperService.setWallpaper result: $result');
      return result;
    } catch (e) {
      debugPrint('WallpaperService.setWallpaper error: $e');
      return false;
    }
  }
}
