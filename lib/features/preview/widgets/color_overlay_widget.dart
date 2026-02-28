import 'package:flutter/material.dart';

/// A simple colored glass overlay with configurable opacity and blend mode.
class ColorOverlayWidget extends StatelessWidget {
  final Color color;
  final double opacity;
  final BlendMode blendMode;

  const ColorOverlayWidget({
    super.key,
    required this.color,
    this.opacity = 0.15,
    this.blendMode = BlendMode.srcOver,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity.clamp(0.0, 1.0)),
          backgroundBlendMode: blendMode,
        ),
      ),
    );
  }
}
