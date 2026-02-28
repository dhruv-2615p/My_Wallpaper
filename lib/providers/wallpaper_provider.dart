import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallpaper_model.dart';
import '../services/pexels_service.dart';
import 'sensor_provider.dart';

/// Manages wallpaper list with pagination for a given query.
class WallpaperNotifier extends StateNotifier<List<WallpaperModel>> {
  final PexelsService _service;
  final String _query;
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  WallpaperNotifier(this._service, this._query) : super([]) {
    _loadInitial();
  }

  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> _loadInitial() async {
    _isLoading = true;
    final results = _query.isEmpty
        ? await _service.fetchCurated(page: 1)
        : await _service.search(_query, page: 1);
    state = results;
    _page = 2;
    _hasMore = results.length >= 30;
    _isLoading = false;
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    final results = _query.isEmpty
        ? await _service.fetchCurated(page: _page)
        : await _service.search(_query, page: _page);
    state = [...state, ...results];
    _page++;
    _hasMore = results.length >= 30;
    _isLoading = false;
  }

  Future<void> refresh() async {
    _page = 1;
    _hasMore = true;
    await _loadInitial();
  }
}

/// Family provider keyed by search query ('' = curated).
final wallpaperListProvider = StateNotifierProvider.family<WallpaperNotifier,
    List<WallpaperModel>, String>((ref, query) {
  final service = ref.watch(pexelsServiceProvider);
  return WallpaperNotifier(service, query);
});
