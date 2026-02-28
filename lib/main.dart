import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/wallpaper_model.dart';
import 'models/effect_settings.dart';
import 'services/storage_service.dart';
import 'services/sensor_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive setup
  await Hive.initFlutter();
  Hive.registerAdapter(WallpaperModelAdapter());
  Hive.registerAdapter(EffectSettingsAdapter());
  Hive.registerAdapter(ParticleTypeAdapter());

  // Open all Hive boxes + SharedPreferences
  final storage = StorageService();
  await storage.init();

  // Check if gyroscope hardware is available
  await SensorService.instance.checkGyroscope();

  runApp(
    ProviderScope(
      overrides: [
        // Supply the already-initialised StorageService so providers can use it.
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const GyroWallApp(),
    ),
  );
}

/// Global provider so other providers can access the initialised storage.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden');
});
