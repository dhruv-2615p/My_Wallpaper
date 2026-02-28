import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Utility helpers for image capture and processing.
class ImageUtils {
  ImageUtils._();

  /// Capture a [RepaintBoundary] as PNG bytes.
  static Future<Uint8List?> captureWidgetAsBytes(
    GlobalKey repaintBoundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary = repaintBoundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('ImageUtils.captureWidgetAsBytes error: $e');
      return null;
    }
  }

  /// Save PNG bytes to a temporary file and return the path.
  static Future<String?> saveBytesToTempFile(Uint8List bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/gyrowall_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('ImageUtils.saveBytesToTempFile error: $e');
      return null;
    }
  }

  /// Download or copy an image to a **permanent** location the live wallpaper
  /// service can reliably read (even after temp files are purged).
  ///
  /// - If [imageUrl] starts with "http", the image is downloaded.
  /// - Otherwise it is treated as a local file path and copied.
  ///
  /// Returns the absolute path to the saved file, or null on failure.
  static Future<String?> saveImageForLiveWallpaper(String imageUrl) async {
    try {
      debugPrint('ImageUtils.saveImageForLiveWallpaper: url=$imageUrl');
      final dir = await getApplicationDocumentsDirectory();
      final destPath = '${dir.path}/gyrowall_live_wallpaper.png';
      debugPrint('ImageUtils.saveImageForLiveWallpaper: destPath=$destPath');

      if (imageUrl.startsWith('http')) {
        final response = await http
            .get(Uri.parse(imageUrl))
            .timeout(const Duration(seconds: 30));
        debugPrint(
            'ImageUtils.saveImageForLiveWallpaper: http status=${response.statusCode}');
        if (response.statusCode != 200) {
          debugPrint(
              'ImageUtils.saveImageForLiveWallpaper: bad status ${response.statusCode}');
          return null;
        }
        final file = File(destPath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('ImageUtils.saveImageForLiveWallpaper: saved ${response.bodyBytes.length} bytes');
        return destPath;
      } else {
        final src = File(imageUrl);
        if (!src.existsSync()) {
          debugPrint('ImageUtils.saveImageForLiveWallpaper: local file not found: $imageUrl');
          return null;
        }
        await src.copy(destPath);
        debugPrint('ImageUtils.saveImageForLiveWallpaper: copied local file to $destPath');
        return destPath;
      }
    } catch (e, st) {
      debugPrint('ImageUtils.saveImageForLiveWallpaper error: $e\n$st');
      return null;
    }
  }
}
