import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Realistic still-water overlay with floating ice cubes, controlled by
/// device gravity (accelerometer).
///
/// Physics:
///  – Phone **vertical** → water flat & horizontal.
///  – Phone **tilted left/right** → water surface tilts like a real glass.
///  – Ice cubes slide DOWN the tilted surface (opposite to water pooling).
///
/// Rendering:
///  – Catmull-Rom → cubic-bezier surface curve (smooth & curvy, not straight).
///  – Multi-layer gradient with high-opacity floor for visible, rich colour.
///  – Ice collision repulsion so cubes never merge.
class WaterOverlayWidget extends StatefulWidget {
  final double waterLevel; // 0.0 – 0.5 (fraction from bottom)
  final Color waterColor;
  final int iceCount; // 0–5

  const WaterOverlayWidget({
    super.key,
    this.waterLevel = 0.25,
    this.waterColor = const Color(0x9900BFFF),
    this.iceCount = 3,
  });

  @override
  State<WaterOverlayWidget> createState() => _WaterOverlayWidgetState();
}

class _WaterOverlayWidgetState extends State<WaterOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // Low-pass filtered accelerometer.
  double _accelX = 0.0;
  double _accelY = 9.8;
  // Faster alpha → quicker tilt response (was 0.06, now 0.14).
  static const double _alpha = 0.14;

  late List<_IceCube> _ices;
  final _rng = Random(42);

  @override
  void initState() {
    super.initState();
    _buildIces();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((e) {
      _accelX += _alpha * (e.x - _accelX);
      _accelY += _alpha * (e.y - _accelY);
    }, onError: (_) {});
  }

  void _buildIces() {
    final count = widget.iceCount.clamp(0, 5);
    _ices = List.generate(count, (i) {
      final sizeClass = i % 3;
      final baseW = <double>[30, 48, 68][sizeClass];
      final baseH = <double>[20, 30, 42][sizeClass];
      return _IceCube(
        // Evenly distributed so they never start merged.
        xFrac: count == 1
            ? 0.5
            : 0.12 + (i / (count - 1)) * 0.76,
        width: baseW + _rng.nextDouble() * 10,
        height: baseH + _rng.nextDouble() * 6,
        bobPhase: _rng.nextDouble() * 2 * pi,
        bobSpeed: 0.25 + _rng.nextDouble() * 0.3,
        bobAmp: 1.0 + _rng.nextDouble() * 1.5,
        cornerOffsets: List.generate(
            8,
            (_) => Offset(
                  (_rng.nextDouble() - 0.5) * 8,
                  (_rng.nextDouble() - 0.5) * 5,
                )),
        crackSeed: _rng.nextInt(10000),
      );
    });
  }

  @override
  void didUpdateWidget(covariant WaterOverlayWidget old) {
    super.didUpdateWidget(old);
    if (old.iceCount != widget.iceCount) _buildIces();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        // Normalised tilt: –1 (full left) … 0 (upright) … +1 (full right).
        final tilt = (_accelX / 9.81).clamp(-1.0, 1.0);

        // ── Ice drift: OPPOSITE to water tilt ──────────────────────────
        // When phone tilts left (tilt<0), water pools left, surface slopes
        // downward to the right → ice slides RIGHT (positive direction).
        for (final ice in _ices) {
          ice.vx -= tilt * 0.001; // REVERSED direction
          ice.vx *= 0.975;
          ice.xFrac += ice.vx;
          if (ice.xFrac < 0.06) {
            ice.xFrac = 0.06;
            ice.vx = ice.vx.abs() * 0.15;
          } else if (ice.xFrac > 0.94) {
            ice.xFrac = 0.94;
            ice.vx = -ice.vx.abs() * 0.15;
          }
        }

        // ── Ice-ice repulsion: prevent merging ─────────────────────────
        for (int a = 0; a < _ices.length; a++) {
          for (int b = a + 1; b < _ices.length; b++) {
            final diff = _ices[a].xFrac - _ices[b].xFrac;
            const minSep = 0.16;
            if (diff.abs() < minSep) {
              final push = (minSep - diff.abs()) * 0.04;
              if (diff >= 0) {
                _ices[a].xFrac += push;
                _ices[b].xFrac -= push;
              } else {
                _ices[a].xFrac -= push;
                _ices[b].xFrac += push;
              }
            }
          }
        }

        return RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _WaterIcePainter(
              time: _anim.value,
              waterLevel: widget.waterLevel,
              tilt: tilt,
              color: widget.waterColor,
              ices: _ices,
            ),
          ),
        );
      },
    );
  }
}

// ─── Ice cube data ──────────────────────────────────────────────────────────

class _IceCube {
  double xFrac;
  final double width;
  final double height;
  final double bobPhase;
  final double bobSpeed;
  final double bobAmp;
  final List<Offset> cornerOffsets;
  final int crackSeed;
  double vx = 0;

  _IceCube({
    required this.xFrac,
    required this.width,
    required this.height,
    required this.bobPhase,
    required this.bobSpeed,
    required this.bobAmp,
    required this.cornerOffsets,
    required this.crackSeed,
  });
}

// ─── Painter ────────────────────────────────────────────────────────────────

class _WaterIcePainter extends CustomPainter {
  final double time;
  final double waterLevel;
  final double tilt;
  final Color color;
  final List<_IceCube> ices;

  _WaterIcePainter({
    required this.time,
    required this.waterLevel,
    required this.tilt,
    required this.color,
    required this.ices,
  });

  // ── Surface‐Y function ────────────────────────────────────────────────
  // Bigger amplitudes (6,3.5,1.5 px) + stronger tilt factor (0.55).
  double _surfaceY(double x, double sw, double sh, double phase) {
    final baseY = sh * (1.0 - waterLevel);
    // 0.55 of screen height at full tilt → dramatic horizontal behaviour.
    final tiltOffset = -(x / sw - 0.5) * tilt * sh * 0.55;
    // Three harmonics with different wavelengths & speeds.
    final r1 = sin(phase * 0.35 + x * 0.008) * 6.0;  // big slow swell
    final r2 = sin(phase * 0.8 + x * 0.018 + 2.0) * 3.5; // medium ripple
    final r3 = cos(phase * 1.5 + x * 0.04 - 1.0) * 1.5;  // small shimmer
    return baseY + tiltOffset + r1 + r2 + r3;
  }

  // ── Build a smooth Catmull-Rom cubic-bezier surface path ──────────────
  // Sampled at 24px intervals, converted through Catmull-Rom → cubicTo.
  // This produces CURVY organic waves, not straight line segments.
  Path _buildSurfacePath(double sw, double sh, double phase,
      {double yOffset = 0}) {
    const step = 24.0;
    final pts = <Offset>[];
    for (double x = 0; x <= sw; x += step) {
      pts.add(Offset(x, _surfaceY(x, sw, sh, phase) + yOffset));
    }
    if (pts.last.dx < sw) {
      pts.add(Offset(sw, _surfaceY(sw, sw, sh, phase) + yOffset));
    }

    final path = Path();
    path.moveTo(pts[0].dx, pts[0].dy);

    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = pts[max(0, i - 1)];
      final p1 = pts[i];
      final p2 = pts[min(pts.length - 1, i + 1)];
      final p3 = pts[min(pts.length - 1, i + 2)];

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6.0;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6.0;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6.0;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6.0;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width;
    final sh = size.height;
    final phase = time * 2 * pi;

    // Strip alpha from the user colour – we control opacity via gradient.
    final baseRGB =
        Color.fromRGBO(color.red, color.green, color.blue, 1.0);
    // Floor at 0.55 so water is ALWAYS clearly visible.
    final alphaScale = color.opacity.clamp(0.55, 1.0);

    // ── 1. Water body ───────────────────────────────────────────────────
    final surfLine = _buildSurfacePath(sw, sh, phase);
    final surfFill = Path.from(surfLine)
      ..lineTo(sw, sh)
      ..lineTo(0, sh)
      ..close();

    final topY = sh * (1 - waterLevel) - sh * 0.12;
    canvas.drawPath(
      surfFill,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(sw / 2, topY),
          Offset(sw / 2, sh),
          [
            baseRGB.withOpacity(alphaScale * 0.55),
            baseRGB.withOpacity(alphaScale * 0.72),
            baseRGB.withOpacity(alphaScale * 0.88),
            baseRGB.withOpacity(alphaScale * 0.96),
          ],
          [0.0, 0.30, 0.65, 1.0],
        ),
    );

    // ── 2. Caustics ─────────────────────────────────────────────────────
    _paintCaustics(canvas, sw, sh, phase, baseRGB, alphaScale);

    // ── 3. Deeper secondary wave ────────────────────────────────────────
    final deepLine = _buildSurfacePath(sw, sh, phase + 1.8, yOffset: 20);
    final deepFill = Path.from(deepLine)
      ..lineTo(sw, sh)
      ..lineTo(0, sh)
      ..close();
    canvas.drawPath(
      deepFill,
      Paint()..color = baseRGB.withOpacity(alphaScale * 0.15),
    );

    // ── 4. Surface highlight ────────────────────────────────────────────
    canvas.drawPath(
      surfLine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..shader = ui.Gradient.linear(
          Offset(0, sh * (1 - waterLevel)),
          Offset(sw, sh * (1 - waterLevel)),
          [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.35),
            Colors.white.withOpacity(0.35),
            Colors.white.withOpacity(0.05),
          ],
          [0.0, 0.25, 0.75, 1.0],
        ),
    );
    canvas.drawPath(
      surfLine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = Colors.white.withOpacity(0.15),
    );

    // ── 5. Ice cubes ────────────────────────────────────────────────────
    for (final ice in ices) {
      _paintIce(canvas, ice, sw, sh, phase);
    }
  }

  void _paintCaustics(Canvas canvas, double sw, double sh, double phase,
      Color baseRGB, double alphaScale) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    final baseY = sh * (1 - waterLevel);
    for (int i = 0; i < 6; i++) {
      final cx =
          (sw * 0.08) + (sw * 0.84) * ((sin(phase * 0.2 + i * 1.7) + 1) / 2);
      final cy =
          baseY + 35 + (sh * 0.18) * ((cos(phase * 0.15 + i * 2.1) + 1) / 2);
      final r = 22.0 + 18.0 * sin(phase * 0.3 + i * 0.9);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2.5, height: r),
        paint,
      );
    }
  }

  void _paintIce(
      Canvas canvas, _IceCube ice, double sw, double sh, double phase) {
    final cx = ice.xFrac * sw;
    final surfY = _surfaceY(cx, sw, sh, phase);
    final bob = sin(phase * ice.bobSpeed + ice.bobPhase) * ice.bobAmp;

    // Surface slope → rotation.
    final yL = _surfaceY(cx - 8, sw, sh, phase);
    final yR = _surfaceY(cx + 8, sw, sh, phase);
    final angle = atan2(yR - yL, 16) * 0.6;

    canvas.save();
    canvas.translate(cx, surfY + bob - ice.height * 0.58);
    canvas.rotate(angle);

    final hw = ice.width / 2;
    final hh = ice.height / 2;

    // Irregular polygon.
    final o = ice.cornerOffsets;
    final icePath = Path()
      ..moveTo(-hw + o[0].dx, -hh + o[0].dy)
      ..lineTo(o[1].dx, -hh - 3 + o[1].dy)
      ..lineTo(hw + o[2].dx, -hh + o[2].dy)
      ..lineTo(hw + 3 + o[3].dx, o[3].dy)
      ..lineTo(hw + o[4].dx, hh + o[4].dy)
      ..lineTo(o[5].dx, hh + 3 + o[5].dy)
      ..lineTo(-hw + o[6].dx, hh + o[6].dy)
      ..lineTo(-hw - 3 + o[7].dx, o[7].dy)
      ..close();

    // Shadow.
    canvas.drawPath(
      icePath.shift(const Offset(1.5, 2.5)),
      Paint()
        ..color = color.withOpacity(0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Body – more opaque gradient (less ghostly).
    canvas.drawPath(
      icePath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-hw, -hh),
          Offset(hw, hh),
          [
            const Color(0xEEF0F8FF),
            const Color(0xDDE0EFF8),
            const Color(0xCCD0E8F5),
            const Color(0xBBC0E0F0),
          ],
          [0.0, 0.30, 0.60, 1.0],
        ),
    );

    // Edge outline.
    canvas.drawPath(
      icePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withOpacity(0.55),
    );

    // Crack lines.
    final crackRng = Random(ice.crackSeed);
    final crackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = Colors.white.withOpacity(0.30);
    for (int c = 0; c < 3; c++) {
      final sx = (crackRng.nextDouble() - 0.5) * ice.width * 0.6;
      final sy = (crackRng.nextDouble() - 0.5) * ice.height * 0.5;
      final ex = sx + (crackRng.nextDouble() - 0.5) * ice.width * 0.45;
      final ey = sy + (crackRng.nextDouble() - 0.5) * ice.height * 0.45;
      canvas.drawLine(Offset(sx, sy), Offset(ex, ey), crackPaint);
    }

    // Gloss highlight.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-hw * 0.2, -hh * 0.3),
        width: ice.width * 0.38,
        height: ice.height * 0.28,
      ),
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // Submerged tint on lower portion.
    canvas.save();
    canvas.clipRect(
        Rect.fromLTWH(-hw - 5, ice.height * 0.10, ice.width + 10, hh + 5));
    canvas.drawPath(
      icePath,
      Paint()..color = color.withOpacity(0.22),
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaterIcePainter old) => true;
}
