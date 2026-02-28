import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';

/// Bottom navigation bar used in the HomeScreen shell.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: AppStrings.navHome,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.photo_library_rounded),
          label: AppStrings.navGallery,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_photo_alternate_rounded),
          label: AppStrings.navMyWallpapers,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_rounded),
          label: AppStrings.navFavorites,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: AppStrings.navSettings,
        ),
      ],
    );
  }
}
