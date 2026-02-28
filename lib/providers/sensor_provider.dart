import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pexels_service.dart';
import '../services/sensor_service.dart';
import '../main.dart' show storageServiceProvider;

// ── Core service providers ──

final pexelsServiceProvider = Provider<PexelsService>((ref) {
  final apiKey = ref.watch(storageServiceProvider).pexelsApiKey;
  return PexelsService(apiKey);
});

final sensorServiceProvider = Provider<SensorService>((ref) {
  return SensorService.instance;
});

// ── Sensor streams ──

final gyroStreamProvider = StreamProvider<Map<String, double>>((ref) {
  return ref.watch(sensorServiceProvider).gyroStream;
});

final accelStreamProvider = StreamProvider<Map<String, double>>((ref) {
  return ref.watch(sensorServiceProvider).accelStream;
});
