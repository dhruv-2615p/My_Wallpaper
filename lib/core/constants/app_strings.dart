/// App-wide string constants.
class AppStrings {
  AppStrings._();

  static const String appName = 'GyroWall';
  static const String appTagline = 'Your wallpaper, alive';

  // Onboarding
  static const String onboardingTitle1 = 'Your Wallpaper, Alive';
  static const String onboardingDesc1 =
      'Experience your wallpapers with real-time gyroscope 3D parallax effects.';
  static const String onboardingTitle2 = 'Add Stunning Effects';
  static const String onboardingDesc2 =
      'Water ripples, snow, rain, fireflies — bring your wallpaper to life.';
  static const String onboardingTitle3 = 'Set & Go';
  static const String onboardingDesc3 =
      'Set it as your wallpaper in one tap. Home screen, lock screen, or both.';

  // Bottom Nav
  static const String navHome = 'Home';
  static const String navGallery = 'Gallery';
  static const String navMyWallpapers = 'My Pics';
  static const String navFavorites = 'Favorites';
  static const String navSettings = 'Settings';

  // Errors / Info
  static const String noInternet = 'No internet connection';
  static const String noGyroscope =
      'Gyroscope not detected — using touch drag fallback';
  static const String apiKeyMissing =
      'Enter your free Pexels API key in Settings to browse wallpapers';
  static const String iosWallpaperNote =
      'iOS doesn\'t allow apps to set wallpapers directly. Save to Photos and set manually.';
  static const String imageLoadFailed = 'Failed to load image. Tap to retry.';

  // Settings
  static const String settingsTitle = 'Settings';
  static const String pexelsApiKeyLabel = 'Pexels API Key';
  static const String gyroSensitivityLabel = 'Default Gyro Sensitivity';
  static const String themeLabel = 'Theme';
  static const String clearCacheLabel = 'Clear Cache';
  static const String aboutLabel = 'About';
  static const String sensorStatusLabel = 'Sensor Status';

  // Wallpaper set options
  static const String setHomeScreen = 'Home Screen';
  static const String setLockScreen = 'Lock Screen';
  static const String setBothScreens = 'Both Screens';
  static const String previewOnly = 'Preview Only';
}
