import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
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
}
