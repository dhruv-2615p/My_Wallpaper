import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../models/effect_settings.dart';

/// Renders animated particles (snow, rain, fireflies, etc.) over the wallpaper.
class ParticleOverlay extends StatefulWidget {
  final ParticleType type;
  final int count;

  const ParticleOverlay({
    super.key,
    this.type = ParticleType.snow,
    this.count = 50,
  });

  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<_Particle> _particles = [];
  final Random _rng = Random();
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  double _gyroYDrift = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _initParticles();

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((e) {
      _gyroYDrift = e.y * 0.5;
    }, onError: (_) {});
  }

  void _initParticles() {
    _particles.clear();
    for (int i = 0; i < widget.count; i++) {
      _particles.add(_Particle.random(_rng, widget.type));
    }
  }

  @override
  void didUpdateWidget(ParticleOverlay old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count || old.type != widget.type) {
      _initParticles();
    }
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ParticlePainter(
              particles: _particles,
              type: widget.type,
              gyroDrift: _gyroYDrift,
              rng: _rng,
            ),
          );
        },
      ),
    );
  }
}

// ── Particle model ──

class _Particle {
  double x; // 0–1 normalised
  double y; // 0–1 normalised
  double speed;
  double size;
  double opacity;
  double angle; // radians – for rain streak / leaf rotation

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.angle,
  });

  factory _Particle.random(Random rng, ParticleType type) {
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      speed: 0.001 + rng.nextDouble() * 0.003,
      size: _sizeForType(rng, type),
      opacity: 0.3 + rng.nextDouble() * 0.7,
      angle: rng.nextDouble() * 2 * pi,
    );
  }

  static double _sizeForType(Random rng, ParticleType type) {
    switch (type) {
      case ParticleType.snow:
        return 2 + rng.nextDouble() * 4;
      case ParticleType.rain:
        return 1 + rng.nextDouble() * 2;
      case ParticleType.fireflies:
        return 2 + rng.nextDouble() * 3;
      case ParticleType.autumnLeaves:
        return 6 + rng.nextDouble() * 6;
      case ParticleType.bubbles:
        return 4 + rng.nextDouble() * 8;
      case ParticleType.stars:
        return 1 + rng.nextDouble() * 2.5;
    }
  }
}

// ── Painter ──

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final ParticleType type;
  final double gyroDrift;
  final Random rng;

  _ParticlePainter({
    required this.particles,
    required this.type,
    required this.gyroDrift,
    required this.rng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      _move(p, size);
      _draw(canvas, size, p);
    }
  }

  void _move(_Particle p, Size size) {
    switch (type) {
      case ParticleType.snow:
        p.y += p.speed;
        p.x += gyroDrift * 0.001 + sin(p.angle) * 0.0005;
        p.angle += 0.02;
        break;
      case ParticleType.rain:
        p.y += p.speed * 3;
        p.x += 0.001; // diagonal
        break;
      case ParticleType.fireflies:
        p.x += sin(p.angle) * 0.001;
        p.y += cos(p.angle) * 0.001;
        p.angle += 0.03;
        p.opacity = 0.3 + (sin(p.angle * 2) + 1) * 0.35;
        break;
      case ParticleType.autumnLeaves:
        p.y += p.speed * 0.8;
        p.x += sin(p.angle) * 0.002 + gyroDrift * 0.001;
        p.angle += 0.01;
        break;
      case ParticleType.bubbles:
        p.y -= p.speed; // float up
        p.x += sin(p.angle) * 0.0005;
        p.angle += 0.02;
        break;
      case ParticleType.stars:
        p.opacity = 0.3 + (sin(p.angle) + 1) * 0.35;
        p.angle += 0.04;
        break;
    }

    // Wrap around
    if (p.y > 1.05) {
      p.y = -0.05;
      p.x = rng.nextDouble();
    }
    if (p.y < -0.05) {
      p.y = 1.05;
      p.x = rng.nextDouble();
    }
    if (p.x > 1.05) p.x = -0.05;
    if (p.x < -0.05) p.x = 1.05;
  }

  void _draw(Canvas canvas, Size size, _Particle p) {
    final px = p.x * size.width;
    final py = p.y * size.height;

    switch (type) {
      case ParticleType.snow:
        canvas.drawCircle(
          Offset(px, py),
          p.size,
          Paint()..color = Colors.white.withValues(alpha: p.opacity),
        );
        break;
      case ParticleType.rain:
        final paint = Paint()
          ..color = Colors.white.withValues(alpha: p.opacity * 0.6)
          ..strokeWidth = p.size;
        canvas.drawLine(
          Offset(px, py),
          Offset(px + 2, py + 12),
          paint,
        );
        break;
      case ParticleType.fireflies:
        canvas.drawCircle(
          Offset(px, py),
          p.size,
          Paint()
            ..color = Colors.yellowAccent.withValues(alpha: p.opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        break;
      case ParticleType.autumnLeaves:
        final text = TextPainter(
          text: TextSpan(
            text: '🍂',
            style: TextStyle(fontSize: p.size * 2),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(p.angle);
        text.paint(canvas, Offset(-p.size, -p.size));
        canvas.restore();
        break;
      case ParticleType.bubbles:
        canvas.drawCircle(
          Offset(px, py),
          p.size,
          Paint()
            ..color = Colors.lightBlueAccent.withValues(alpha: p.opacity * 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        break;
      case ParticleType.stars:
        canvas.drawCircle(
          Offset(px, py),
          p.size,
          Paint()
            ..color = Colors.white.withValues(alpha: p.opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
