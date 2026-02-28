import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:video_player/video_player.dart';

/// Full-screen looping video layer with gyroscope-driven parallax,
/// matching [GyroParallaxLayer] behaviour but rendering a video.
class VideoPlayerLayer extends StatefulWidget {
  final String videoPath;
  final double sensitivity;
  final double layerDepth;

  const VideoPlayerLayer({
    super.key,
    required this.videoPath,
    this.sensitivity = 1.0,
    this.layerDepth = 0.0,
  });

  @override
  State<VideoPlayerLayer> createState() => _VideoPlayerLayerState();
}

class _VideoPlayerLayerState extends State<VideoPlayerLayer>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _initialised = false;

  // ── Gyroscope ──
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  bool _gyroAvailable = true;
  double _smoothX = 0, _smoothY = 0;
  double _dx = 0, _dy = 0;
  static const double _alpha = 0.15;

  // ── Touch-drag fallback ──
  double _touchDx = 0, _touchDy = 0;
  late final AnimationController _springController;

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

    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..setLooping(true)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialised = true);
          _controller.play();
        }
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
        onError: (_) => _gyroAvailable = false,
      );
    } catch (_) {
      _gyroAvailable = false;
    }
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _springController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialised) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalDx = _gyroAvailable ? _dx : _touchDx;
    final totalDy = _gyroAvailable ? _dy : _touchDy;

    Widget child = Transform(
      transform: Matrix4.identity()
        ..translate(totalDx, totalDy)
        ..scale(1.2), // overscale to hide edges during parallax
      alignment: Alignment.center,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );

    // Touch-drag fallback when gyro is unavailable
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
        onPanEnd: (_) => _springController.forward(from: 0),
        child: child,
      );
    }

    return ClipRect(child: child);
  }
}
