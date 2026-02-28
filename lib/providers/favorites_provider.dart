import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallpaper_model.dart';
import '../services/storage_service.dart';
import '../main.dart' show storageServiceProvider;

/// Manages the favorites list, backed by Hive.
class FavoritesNotifier extends StateNotifier<List<WallpaperModel>> {
  final StorageService _storage;

  FavoritesNotifier(this._storage) : super(_storage.getFavorites());

  bool isFavorite(String id) => _storage.isFavorite(id);

  Future<void> toggle(WallpaperModel wallpaper) async {
    if (_storage.isFavorite(wallpaper.id)) {
      await _storage.removeFavorite(wallpaper.id);
    } else {
      await _storage.addFavorite(wallpaper);
    }
    state = _storage.getFavorites();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<WallpaperModel>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return FavoritesNotifier(storage);
});
