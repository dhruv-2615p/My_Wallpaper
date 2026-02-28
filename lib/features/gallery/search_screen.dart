import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../providers/wallpaper_provider.dart';
import '../../core/router/app_router.dart';
import 'widgets/wallpaper_card.dart';
import 'widgets/loading_shimmer.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_query.isEmpty) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(wallpaperListProvider(_query).notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _query = value.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallpapers =
        _query.isEmpty ? <dynamic>[] : ref.watch(wallpaperListProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _textController,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search wallpapers…',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _query.isEmpty
          ? const Center(
              child: Text(
                'Type to search Pexels wallpapers',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : wallpapers.isEmpty
              ? const Center(child: LoadingShimmer())
              : MasonryGridView.count(
                  controller: _scrollController,
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  padding: const EdgeInsets.all(12),
                  itemCount: wallpapers.length,
                  itemBuilder: (context, index) {
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
                ),
    );
  }
}
