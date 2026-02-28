import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallpaper_model.dart';
import '../models/effect_settings.dart';

/// Unified local-storage layer backed by Hive + SharedPreferences.
class StorageService {
  static const String _favoritesBoxName = 'favorites';
  static const String _presetsBoxName = 'presets';
  static const String _myWallpapersBoxName = 'myWallpapers';

  // SharedPreferences keys
  static const String keyApiKey = 'pexels_api_key';
  static const String keyOnboardingDone = 'onboarding_complete';
  static const String keyThemeMode = 'theme_mode'; // 'dark', 'light', 'system'
  static const String keyGyroSensitivity = 'default_gyro_sensitivity';

  late final Box<WallpaperModel> _favoritesBox;
  late final Box<EffectSettings> _presetsBox;
  late final Box _myWallpapersBox;
  late final SharedPreferences _prefs;

  /// Call once before runApp.
  Future<void> init() async {
    _favoritesBox = await Hive.openBox<WallpaperModel>(_favoritesBoxName);
    _presetsBox = await Hive.openBox<EffectSettings>(_presetsBoxName);
    _myWallpapersBox = await Hive.openBox(_myWallpapersBoxName);
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Favorites ──

  List<WallpaperModel> getFavorites() => _favoritesBox.values.toList();

  Future<void> addFavorite(WallpaperModel w) => _favoritesBox.put(w.id, w);

  Future<void> removeFavorite(String id) => _favoritesBox.delete(id);

  bool isFavorite(String id) => _favoritesBox.containsKey(id);

  // ── My Wallpapers (local paths) ──

  List<String> getMyWallpaperPaths() =>
      _myWallpapersBox.values.cast<String>().toList();

  Future<void> addMyWallpaper(String path) => _myWallpapersBox.add(path);

  Future<void> removeMyWallpaper(int index) => _myWallpapersBox.deleteAt(index);

  // ── Presets ──

  List<EffectSettings> getPresets() => _presetsBox.values.toList();

  Future<void> savePreset(EffectSettings preset) =>
      _presetsBox.put(preset.name, preset);

  Future<void> deletePreset(String name) => _presetsBox.delete(name);

  // ── SharedPreferences helpers ──

  String get pexelsApiKey => _prefs.getString(keyApiKey) ?? '';

  Future<void> setPexelsApiKey(String key) => _prefs.setString(keyApiKey, key);

  bool get isOnboardingDone => _prefs.getBool(keyOnboardingDone) ?? false;

  Future<void> setOnboardingDone() => _prefs.setBool(keyOnboardingDone, true);

  String get themeMode => _prefs.getString(keyThemeMode) ?? 'dark';

  Future<void> setThemeMode(String mode) =>
      _prefs.setString(keyThemeMode, mode);

  double get defaultGyroSensitivity =>
      _prefs.getDouble(keyGyroSensitivity) ?? 1.0;

  Future<void> setDefaultGyroSensitivity(double v) =>
      _prefs.setDouble(keyGyroSensitivity, v);
}
