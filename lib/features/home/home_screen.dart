import 'package:flutter/material.dart';
import '../gallery/gallery_screen.dart';
import '../my_wallpapers/my_wallpapers_screen.dart';
import '../my_wallpapers/favorites_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/featured_banner.dart';
import 'widgets/category_chips.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../core/constants/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const <Widget>[
    _HomeContent(),
    GalleryScreen(),
    MyWallpapersScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// The "Home" tab content with banner + category chips + curated grid.
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text(
              AppStrings.appName,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => Navigator.pushNamed(context, '/search'),
              ),
            ],
          ),
          const SliverToBoxAdapter(child: FeaturedBanner()),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CategoryChips(),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GalleryScreen(embedded: true),
            ),
          ),
        ],
      ),
    );
  }
}
