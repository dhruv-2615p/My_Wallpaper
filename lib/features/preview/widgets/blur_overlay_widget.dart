import 'dart:ui';
import 'package:flutter/material.dart';

/// Frosted-glass / blur overlay. Can cover full screen or bottom portion.
class BlurOverlayWidget extends StatelessWidget {
  final double blurAmount;
  final bool bottomOnly; // if true, blur only bottom 1/3 (caption bar style)

  const BlurOverlayWidget({
    super.key,
    this.blurAmount = 5.0,
    this.bottomOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (blurAmount <= 0) return const SizedBox.shrink();

    final blurChild = BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: blurAmount,
        sigmaY: blurAmount,
      ),
      child: Container(color: Colors.transparent),
    );

    if (bottomOnly) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: 0.33,
          child: ClipRect(child: blurChild),
        ),
      );
    }

    return IgnorePointer(child: ClipRect(child: blurChild));
  }
}
