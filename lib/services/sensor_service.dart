import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Manages gyroscope and accelerometer sensor streams with low-pass filter.
class SensorService {
  SensorService._internal();
  static final SensorService instance = SensorService._internal();

  // Low-pass filter coefficient: smaller = smoother but laggier
  static const double _alpha = 0.15;

  double _smoothGyroX = 0;
  double _smoothGyroY = 0;
  double _smoothGyroZ = 0;
  double _smoothAccelX = 0;
  double _smoothAccelY = 0;
  double _smoothAccelZ = 0;

  bool _gyroAvailable = true;

  /// Whether the device has a hardware gyroscope.
  bool get isGyroscopeAvailable => _gyroAvailable;

  /// Smoothed gyroscope stream emitting {x, y, z} values.
  Stream<Map<String, double>> get gyroStream {
    return gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).handleError((error) {
      _gyroAvailable = false;
      debugPrint('SensorService: gyroscope not available, falling back');
    }).map((event) {
      _smoothGyroX = _smoothGyroX * (1 - _alpha) + event.x * _alpha;
      _smoothGyroY = _smoothGyroY * (1 - _alpha) + event.y * _alpha;
      _smoothGyroZ = _smoothGyroZ * (1 - _alpha) + event.z * _alpha;
      return {'x': _smoothGyroX, 'y': _smoothGyroY, 'z': _smoothGyroZ};
    });
  }

  /// Smoothed accelerometer stream emitting {x, y, z} values.
  Stream<Map<String, double>> get accelStream {
    return accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).map((event) {
      _smoothAccelX = _smoothAccelX * (1 - _alpha) + event.x * _alpha;
      _smoothAccelY = _smoothAccelY * (1 - _alpha) + event.y * _alpha;
      _smoothAccelZ = _smoothAccelZ * (1 - _alpha) + event.z * _alpha;
      return {'x': _smoothAccelX, 'y': _smoothAccelY, 'z': _smoothAccelZ};
    });
  }

  /// Check gyroscope availability proactively.
  Future<void> checkGyroscope() async {
    try {
      await gyroscopeEventStream().first.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          _gyroAvailable = false;
          return GyroscopeEvent(0, 0, 0, DateTime.now());
        },
      );
    } catch (_) {
      _gyroAvailable = false;
    }
  }
}
