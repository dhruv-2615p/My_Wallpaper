import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import '../models/effect_settings.dart';

/// Encapsulates wallpaper-setting logic using async_wallpaper.
class WallpaperService {
  WallpaperService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.my_flutter_app/live_wallpaper');

  /// Location constants matching AsyncWallpaper.
  static const int homeScreen  = AsyncWallpaper.HOME_SCREEN;
  static const int lockScreen  = AsyncWallpaper.LOCK_SCREEN;
  static const int bothScreens = AsyncWallpaper.BOTH_SCREENS;

  /// Set a static wallpaper from a local file path.
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

  /// Set a live wallpaper with gyroscope parallax + all effects (Android only).
  ///
  /// Passes every field from [fx] to the native service, then opens the
  /// system live-wallpaper picker pre-pointed at [GyroLiveWallpaperService].
  static Future<bool> setLiveWallpaper(
    String imagePath,
    EffectSettings fx,
  ) async {
    try {
      final result = await _channel.invokeMethod<bool>('setLiveWallpaper', {
        'imagePath':            imagePath,
        'sensitivity':          fx.gyroSensitivity,
        'isGyroEnabled':        fx.isGyroEnabled,
        'isWaterEnabled':       fx.isWaterEnabled,
        'waterLevel':           fx.waterLevel,
        'waterColorHex':        fx.waterColor,
        'isColorOverlayEnabled': fx.isColorOverlayEnabled,
        'colorOverlayHex':      fx.colorOverlayHex,
        'colorOverlayOpacity':  fx.colorOverlayOpacity,
        'isBlurEnabled':        fx.isBlurEnabled,
        'blurAmount':           fx.blurAmount,
        'isParticlesEnabled':   fx.isParticlesEnabled,
        'particleTypeIndex':    fx.particleTypeIndex,
        'particleCount':        fx.particleCount,
      });
      debugPrint('WallpaperService.setLiveWallpaper result: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('WallpaperService.setLiveWallpaper error: $e');
      return false;
    }
  }

  /// Set a video live wallpaper (Android only).
  ///
  /// [videoPath] must be an absolute path to a local video file (MP4/WEBM).
  /// Opens the system live-wallpaper picker pre-pointed at [VideoLiveWallpaperService].
  static Future<bool> setVideoLiveWallpaper(String videoPath) async {
    try {
      final result = await _channel.invokeMethod<bool>('setVideoLiveWallpaper', {
        'videoPath': videoPath,
      });
      debugPrint('WallpaperService.setVideoLiveWallpaper result: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('WallpaperService.setVideoLiveWallpaper error: $e');
      return false;
    }
  }
}


