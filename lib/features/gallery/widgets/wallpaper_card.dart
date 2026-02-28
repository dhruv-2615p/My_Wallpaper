import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/wallpaper_model.dart';
import '../../../providers/favorites_provider.dart';
import '../../../core/constants/app_colors.dart';

class WallpaperCard extends ConsumerWidget {
  final WallpaperModel wallpaper;
  final VoidCallback onTap;

  const WallpaperCard({
    super.key,
    required this.wallpaper,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav =
        ref.watch(favoritesProvider.notifier).isFavorite(wallpaper.id);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Image
            AspectRatio(
              aspectRatio: wallpaper.width > 0 && wallpaper.height > 0
                  ? wallpaper.width / wallpaper.height
                  : 0.67,
              child: wallpaper.isLocal
                  ? Image.file(
                      File(wallpaper.localPath!),
                      fit: BoxFit.cover,
                    )
                  : CachedNetworkImage(
                      imageUrl: wallpaper.thumbUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.shimmerBase,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.shimmerBase,
                        child:
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
            ),

            // Favorite heart
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () =>
                    ref.read(favoritesProvider.notifier).toggle(wallpaper),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black45,
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: isFav ? Colors.redAccent : Colors.white,
                  ),
                ),
              ),
            ),

            // Photographer label
            if (wallpaper.photographer.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Text(
                    wallpaper.photographer,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
