import 'package:hive/hive.dart';

part 'wallpaper_model.g.dart';

@HiveType(typeId: 0)
class WallpaperModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String url; // full-res URL

  @HiveField(2)
  final String thumbUrl; // small thumbnail URL

  @HiveField(3)
  final String photographer;

  @HiveField(4)
  final String photographerUrl;

  @HiveField(5)
  final int width;

  @HiveField(6)
  final int height;

  @HiveField(7)
  final String? localPath; // non-null for user-picked images

  @HiveField(8)
  final String avgColor; // hex color from API

  WallpaperModel({
    required this.id,
    required this.url,
    required this.thumbUrl,
    this.photographer = '',
    this.photographerUrl = '',
    this.width = 0,
    this.height = 0,
    this.localPath,
    this.avgColor = '#000000',
  });

  /// Parse from Pexels API JSON.
  factory WallpaperModel.fromPexelsJson(Map<String, dynamic> json) {
    final src = json['src'] as Map<String, dynamic>;
    return WallpaperModel(
      id: json['id'].toString(),
      url: src['original'] as String? ?? src['large2x'] as String? ?? '',
      thumbUrl: src['medium'] as String? ?? src['small'] as String? ?? '',
      photographer: json['photographer'] as String? ?? '',
      photographerUrl: json['photographer_url'] as String? ?? '',
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      avgColor: json['avg_color'] as String? ?? '#000000',
    );
  }

  /// Create a local-image based model.
  factory WallpaperModel.fromLocal(String path) {
    return WallpaperModel(
      id: path.hashCode.toString(),
      url: path,
      thumbUrl: path,
      localPath: path,
    );
  }

  /// Whether this is a local file (not a network URL).
  bool get isLocal => localPath != null && localPath!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WallpaperModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
