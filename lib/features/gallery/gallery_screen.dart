import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../providers/wallpaper_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import 'widgets/wallpaper_card.dart';
import 'widgets/loading_shimmer.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  /// If true, renders without its own Scaffold (used inside HomeContent).
  final bool embedded;

  const GalleryScreen({super.key, this.embedded = false});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(wallpaperListProvider('').notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallpapers = ref.watch(wallpaperListProvider(''));

    final body = wallpapers.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.apiKeyMissing,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        : MasonryGridView.count(
            controller: widget.embedded ? null : _scrollController,
            shrinkWrap: widget.embedded,
            physics: widget.embedded
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            padding:
                widget.embedded ? EdgeInsets.zero : const EdgeInsets.all(12),
            itemCount: wallpapers.length + 1, // +1 for loading indicator
            itemBuilder: (context, index) {
              if (index == wallpapers.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: LoadingShimmer()),
                );
              }
              final w = wallpapers[index];
              return WallpaperCard(
                wallpaper: w,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.preview,
                  arguments: w,
                ),
              );
            },
          );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRouter.search),
          ),
        ],
      ),
      body: body,
    );
  }
}
