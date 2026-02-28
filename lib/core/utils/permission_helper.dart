import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Utility class to handle runtime permissions.
class PermissionHelper {
  PermissionHelper._();

  /// Request storage permission (photos/media) for reading images.
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ uses READ_MEDIA_IMAGES
      if (await Permission.photos.request().isGranted) return true;
      // Fallback for older Android
      if (await Permission.storage.request().isGranted) return true;
      return false;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }
    return true;
  }

  /// Request camera permission.
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Open device settings if permissions are permanently denied.
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
