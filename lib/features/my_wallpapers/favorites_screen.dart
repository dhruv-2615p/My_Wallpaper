import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/router/app_router.dart';
import '../../providers/favorites_provider.dart';
import '../gallery/widgets/wallpaper_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favs.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No favorites yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.65,
              ),
              itemCount: favs.length,
              itemBuilder: (context, index) {
                final w = favs[index];
                return WallpaperCard(
                  wallpaper: w,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRouter.preview,
                    arguments: w,
                  ),
                );
              },
            ),
    );
  }
}
