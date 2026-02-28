import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/wallpaper_model.dart';

/// Handles all Pexels API interactions.
class PexelsService {
  final String _apiKey;

  PexelsService(this._apiKey);

  Map<String, String> get _headers => {
        'Authorization': _apiKey,
      };

  bool get hasApiKey => _apiKey.isNotEmpty;

  /// Fetch curated wallpapers.
  Future<List<WallpaperModel>> fetchCurated({int page = 1}) async {
    if (!hasApiKey) return [];
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.curated(page: page)),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return _parsePhotos(response.body);
      }
      debugPrint('Pexels curated error: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Pexels curated exception: $e');
      return [];
    }
  }

  /// Search wallpapers by query.
  Future<List<WallpaperModel>> search(String query, {int page = 1}) async {
    if (!hasApiKey || query.trim().isEmpty) return [];
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.search(query, page: page)),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return _parsePhotos(response.body);
      }
      debugPrint('Pexels search error: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Pexels search exception: $e');
      return [];
    }
  }

  List<WallpaperModel> _parsePhotos(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final photos = json['photos'] as List<dynamic>? ?? [];
    return photos
        .map((p) => WallpaperModel.fromPexelsJson(p as Map<String, dynamic>))
        .toList();
  }
}
