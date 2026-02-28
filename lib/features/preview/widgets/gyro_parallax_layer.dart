import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Gyroscope-driven 3D parallax layer that shifts an image based on device tilt.
///
/// Subscribes to [gyroscopeEventStream] and applies a low-pass filtered
/// translation. If the gyroscope is unavailable, falls back to touch-drag.
class GyroParallaxLayer extends StatefulWidget {
  final String imageUrl; // network URL or local path
  final double sensitivity; // 1.0 default, range 0.5–5.0
  final double layerDepth; // 0.0 = background, 1.0 = foreground
  final BoxFit fit;

  const GyroParallaxLayer({
    super.key,
    required this.imageUrl,
    this.sensitivity = 1.0,
    this.layerDepth = 0.0,
    this.fit = BoxFit.cover,
  });

  @override
  State<GyroParallaxLayer> createState() => _GyroParallaxLayerState();
}

class _GyroParallaxLayerState extends State<GyroParallaxLayer>
    with SingleTickerProviderStateMixin {
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  bool _gyroAvailable = true;

  // Smoothed offsets
  double _smoothX = 0;
  double _smoothY = 0;
  double _dx = 0;
  double _dy = 0;

  // Touch-drag fallback
  double _touchDx = 0;
  double _touchDy = 0;

  // Animation for smooth spring-back
  late final AnimationController _springController;

  static const double _alpha = 0.15; // low-pass filter
  double get _maxOffset => 40 * widget.sensitivity * (0.5 + widget.layerDepth);

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        final t = Curves.easeOut.transform(_springController.value);
        setState(() {
          _touchDx *= (1 - t);
          _touchDy *= (1 - t);
        });
      });

    _subscribeGyro();
  }

  void _subscribeGyro() {
    try {
      _gyroSub = gyroscopeEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (event) {
          _smoothX = _smoothX * (1 - _alpha) + event.y * _alpha;
          _smoothY = _smoothY * (1 - _alpha) + event.x * _alpha;

          final depthFactor = 0.5 + widget.layerDepth;
          setState(() {
            _dx = (_smoothX * 20 * widget.sensitivity * depthFactor)
                .clamp(-_maxOffset, _maxOffset);
            _dy = (_smoothY * 20 * widget.sensitivity * depthFactor)
                .clamp(-_maxOffset, _maxOffset);
          });
        },
        onError: (_) {
          _gyroAvailable = false;
        },
      );
    } catch (_) {
      _gyroAvailable = false;
    }
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _springController.dispose();
    super.dispose();
  }

  Widget _buildImage() {
    final isLocal = !widget.imageUrl.startsWith('http');
    return isLocal
        ? Image.file(
            File(widget.imageUrl),
            fit: widget.fit,
            width: double.infinity,
            height: double.infinity,
          )
        : Image.network(
            widget.imageUrl,
            fit: widget.fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.black,
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final totalDx = _gyroAvailable ? _dx : _touchDx;
    final totalDy = _gyroAvailable ? _dy : _touchDy;

    Widget child = Transform(
      transform: Matrix4.identity()
        ..translate(totalDx, totalDy)
        ..scale(1.2), // overscale to hide edges
      alignment: Alignment.center,
      child: _buildImage(),
    );

    // Touch drag fallback
    if (!_gyroAvailable) {
      child = GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            _touchDx =
                (_touchDx + d.delta.dx * 0.5).clamp(-_maxOffset, _maxOffset);
            _touchDy =
                (_touchDy + d.delta.dy * 0.5).clamp(-_maxOffset, _maxOffset);
          });
        },
        onPanEnd: (_) {
          _springController.forward(from: 0);
        },
        child: child,
      );
    }

    return ClipRect(child: child);
  }
}
