import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Water physics overlay that draws animated sine waves influenced by accelerometer tilt.
class WaterOverlayWidget extends StatefulWidget {
  final double waterLevel; // 0.0 – 0.5 (fraction of screen height)
  final Color waterColor;
  final double waveSpeed; // multiplier: 0.5 slow, 1.0 normal, 2.0 fast
  final double waveAmplitude; // base amplitude in px

  const WaterOverlayWidget({
    super.key,
    this.waterLevel = 0.2,
    this.waterColor = const Color(0x4400BFFF),
    this.waveSpeed = 1.0,
    this.waveAmplitude = 8.0,
  });

  @override
  State<WaterOverlayWidget> createState() => _WaterOverlayWidgetState();
}

class _WaterOverlayWidgetState extends State<WaterOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _tiltX = 0;
  double _tiltY = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((e) {
      _tiltX = e.x;
      _tiltY = e.y;
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _WaterPainter(
              phase: _animController.value * 2 * pi * widget.waveSpeed +
                  _tiltX * 0.3,
              waterLevelFraction: widget.waterLevel,
              amplitude: widget.waveAmplitude + _tiltY.abs() * 2,
              color: widget.waterColor,
            ),
          ),
        );
      },
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double phase;
  final double waterLevelFraction;
  final double amplitude;
  final Color color;

  _WaterPainter({
    required this.phase,
    required this.waterLevelFraction,
    required this.amplitude,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final waterY = size.height * (1 - waterLevelFraction);
    final path = Path();
    const frequency = 0.02;

    path.moveTo(0, waterY + sin(phase) * amplitude);
    for (double x = 0; x <= size.width; x += 2) {
      final y = waterY + sin(phase + x * frequency) * amplitude;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          color.withValues(alpha: color.a * 0.5),
        ],
      ).createShader(
          Rect.fromLTWH(0, waterY, size.width, size.height - waterY));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaterPainter old) => true;
}
