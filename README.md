# GyroWall — Live Parallax Wallpaper App

> **"Your wallpaper, alive."**

GyroWall is a feature-rich mobile wallpaper application that turns static images and videos into immersive, living wallpapers using real-time gyroscope-driven 3D parallax effects and layered visual overlays. Users can browse a curated gallery of high-quality photos (powered by the Pexels API), pick their own images/videos from the device, apply stunning real-time effects, and set the result as their wallpaper — including native Android live wallpapers with continuous gyroscope parallax on the home screen.

---

## Table of Contents

1. [App Overview](#app-overview)
2. [Core Features](#core-features)
3. [Screens & Navigation](#screens--navigation)
4. [Effect System (Real-Time Layers)](#effect-system-real-time-layers)
5. [Data Models](#data-models)
6. [State Management](#state-management)
7. [Services & Backend](#services--backend)
8. [API Integration](#api-integration)
9. [Local Storage](#local-storage)
10. [Theming & Design System](#theming--design-system)
11. [Project Architecture](#project-architecture)
12. [Complete File Structure](#complete-file-structure)
13. [Tech Stack & Dependencies](#tech-stack--dependencies)
14. [User Flows](#user-flows)
15. [Effect Presets Reference](#effect-presets-reference)

---

## App Overview

| Property | Value |
|---|---|
| **App Name** | GyroWall |
| **Tagline** | "Your wallpaper, alive" |
| **Platform** | Android (primary), iOS (limited — no wallpaper-setting API) |
| **Framework** | Flutter 3.6+ / Dart |
| **State Management** | Riverpod (flutter_riverpod) |
| **Local DB** | Hive + SharedPreferences |
| **Image API** | Pexels (free, API key required) |
| **Min SDK** | Dart SDK ^3.6.0 |

---

## Core Features

### 1. Gyroscope-Driven 3D Parallax
- Real-time gyroscope sensor data moves the wallpaper image in response to device tilt
- Low-pass filtered sensor data (alpha = 0.15) for smooth, lag-free motion
- Adjustable sensitivity from 0.5× to 5.0× (18 discrete steps)
- Automatic fallback to accelerometer/touch-drag if gyroscope hardware is not detected
- Works both in the preview screen and as a native Android live wallpaper

### 2. Water Effect Overlay
- Simulated water surface rendered on top of the wallpaper
- Adjustable water level (0% – 50% of screen height)
- Configurable water color with full color picker (hex color with alpha)
- Floating ice cubes (0–5 count, configurable)
- Reacts to gyroscope tilt for realistic wave motion

### 3. Particle System Overlay
Six particle effect types available:
| Type | Description |
|---|---|
| **Snow** | Falling snowflakes |
| **Rain** | Vertical rain streaks |
| **Fireflies** | Floating glowing dots |
| **Autumn Leaves** | Drifting leaf particles |
| **Bubbles** | Rising bubbles |
| **Stars** | Twinkling star particles |

- Particle count: 10–150 (adjustable)
- Each type has unique movement physics

### 4. Color Overlay
- Semi-transparent color layer on top of the wallpaper
- Opacity range: 5% – 60%
- Full color picker or quick-select preset colors:
  - **Midnight Blue** (#191970)
  - **Rose Gold** (#B76E79)
  - **Emerald** (#50C878)
  - **Sunset Orange** (#FD5E53)
  - **Frosted White** (#FFFFFF)

### 5. Blur Overlay
- Gaussian blur layer over the wallpaper
- Adjustable blur amount

### 6. Wallpaper Setting (Android)
Three modes:
- **Static Wallpaper** — Captures the current preview (with all effect layers baked in) and sets it as home screen, lock screen, or both
- **Live Wallpaper (Gyro Parallax)** — Sets a native Android live wallpaper service that continuously reads the gyroscope and moves the image with all configured effects (water, particles, overlay, blur) rendered natively
- **Video Live Wallpaper** — Sets a looping local video file as a live wallpaper with optional effect overlays

### 7. Pexels Gallery
- Browse curated high-quality photos from the Pexels API
- Search wallpapers by keyword with debounced input (500ms)
- Infinite scroll with pagination (30 items per page)
- Masonry grid layout (2-column staggered grid)
- Shimmer loading placeholders
- Cached network images for performance

### 8. My Wallpapers (Local Media)
- Pick images from device gallery
- Pick videos from device gallery (MP4, WEBM, MOV, AVI, MKV supported)
- Stored locally in Hive database
- Videos tagged with `video::` prefix, images with `image::` prefix

### 9. Favorites System
- Heart/favorite any wallpaper (local or from Pexels)
- Persisted in Hive database keyed by wallpaper ID
- Toggle favorite from preview screen
- Dedicated favorites tab with grid view

### 10. Onboarding Flow
Three-page onboarding with:
- Page 1: "Your Wallpaper, Alive" — gyroscope parallax introduction
- Page 2: "Add Stunning Effects" — water, snow, rain, fireflies showcase
- Page 3: "Set & Go" — one-tap wallpaper setting
- Smooth page indicator (worm effect)
- Skip button and Get Started/Next navigation
- Onboarding completion persisted so it only shows once

### 11. Settings
- Pexels API key input (obscured text field with save)
- Link to get a free Pexels API key
- Default gyro sensitivity slider (0.5–5.0×)
- Theme selector: Dark / Light / System
- Sensor status indicator (gyroscope detected or not)
- About section with app version and licenses page

---

## Screens & Navigation

### Navigation Structure
The app uses a bottom navigation bar with 5 tabs inside a shell (`HomeScreen`), plus push-navigated screens:

```
App Entry
├── OnboardingScreen (shown once, first launch)
└── HomeScreen (main shell with IndexedStack)
    ├── Tab 0: Home (HomeContent)
    │   ├── SliverAppBar with search icon
    │   ├── FeaturedBanner (hero carousel/banner)
    │   ├── CategoryChips (horizontal chip filter)
    │   └── GalleryScreen (embedded, curated grid)
    ├── Tab 1: Gallery (GalleryScreen)
    │   └── Masonry grid of curated wallpapers
    ├── Tab 2: My Pics (MyWallpapersScreen)
    │   ├── Grid of user-picked images/videos
    │   └── FAB → Add Image / Add Video picker
    ├── Tab 3: Favorites (FavoritesScreen)
    │   └── Grid of favorited wallpapers
    └── Tab 4: Settings (SettingsScreen)

Push Routes:
├── /search → SearchScreen (keyword search with results grid)
└── /preview → PreviewScreen (full-screen wallpaper preview + effects)
    └── EffectPanel (draggable bottom sheet with tabbed controls)
```

### Route Definitions
| Route | Screen | Arguments |
|---|---|---|
| `/onboarding` | OnboardingScreen | None |
| `/` (home) | HomeScreen | None |
| `/search` | SearchScreen | None |
| `/preview` | PreviewScreen | `WallpaperModel` (required) |
| `/settings` | SettingsScreen | None |

### Bottom Navigation Tabs
| Index | Label | Icon |
|---|---|---|
| 0 | Home | `home_rounded` |
| 1 | Gallery | `photo_library_rounded` |
| 2 | My Pics | `add_photo_alternate_rounded` |
| 3 | Favorites | `favorite_rounded` |
| 4 | Settings | `settings_rounded` |

---

## Effect System (Real-Time Layers)

The preview screen renders effects as stacked overlay layers inside a `RepaintBoundary` for wallpaper capture:

```
Stack (StackFit.expand)
│
├── Layer 0: Base Image/Video
│   ├── GyroParallaxLayer (for images) — translates image based on gyro data
│   └── VideoPlayerLayer (for videos) — looping video with optional gyro sensitivity
│
├── Layer 1: WaterOverlayWidget (conditional: isWaterEnabled)
│   ├── Water surface simulation
│   ├── Configurable water level, color, alpha
│   └── Floating ice cubes (0–5)
│
├── Layer 2: ParticleOverlay (conditional: isParticlesEnabled)
│   ├── Particle type (snow, rain, fireflies, autumn leaves, bubbles, stars)
│   └── Particle count (10–150)
│
├── Layer 3: ColorOverlayWidget (conditional: isColorOverlayEnabled)
│   ├── Solid color with adjustable opacity
│   └── Hex color with alpha channel
│
└── Layer 4: BlurOverlayWidget (conditional: isBlurEnabled)
    └── Gaussian blur with adjustable sigma
```

### Effect Panel (Draggable Bottom Sheet)
The effect panel is a `DraggableScrollableSheet` with 6 tabbed sections:

| Tab | Controls |
|---|---|
| **Parallax** | Enable/disable gyro toggle, sensitivity slider (0.5–5.0) |
| **Water** | Enable toggle, water level slider (0–50%), ice cube count (0–5), water color picker |
| **Particles** | Enable toggle, type dropdown (6 types), count slider (10–150) |
| **Overlay** | Enable toggle, opacity slider (5–60%), color picker, preset color swatches |
| **Blur** | Enable toggle, blur amount slider |
| **Presets** | Built-in preset buttons that apply pre-configured effect combinations |

---

## Data Models

### WallpaperModel (Hive TypeId: 0)
```
Fields:
├── id: String              — Unique identifier (Pexels photo ID or path hash)
├── url: String             — Full-resolution image URL
├── thumbUrl: String        — Thumbnail URL for grid display
├── photographer: String    — Photographer name (from Pexels)
├── photographerUrl: String — Photographer profile URL
├── width: int              — Image width in pixels
├── height: int             — Image height in pixels
├── localPath: String?      — Local file path (non-null for user-picked images)
├── avgColor: String        — Average color hex string (from Pexels API)

Computed:
├── isLocal: bool           — true if localPath is non-null and non-empty
├── isVideo: bool           — true if localPath ends with .mp4/.webm/.mov/.avi/.mkv

Factory Constructors:
├── fromPexelsJson(json)    — Parse from Pexels API response
├── fromLocal(path)         — Create from local image path
├── fromLocalVideo(path)    — Create from local video path (id prefixed with "video_")
```

### EffectSettings (Hive TypeId: 1)
```
Fields:
├── name: String                  — Preset name (default: "Custom")
├── gyroSensitivity: double       — 0.5–5.0, default 1.0
├── waterLevel: double            — 0.0–0.5, default 0.2
├── waterColor: String            — Hex with alpha, default "#4400BFFF"
├── particleTypeIndex: int        — Index into ParticleType enum
├── particleCount: int            — 10–150, default 50
├── colorOverlayOpacity: double   — 0.05–0.60, default 0.15
├── colorOverlayHex: String       — Hex color, default "#191970" (Midnight Blue)
├── blurAmount: double            — Gaussian sigma, default 0.0
├── isGyroEnabled: bool           — default true
├── isWaterEnabled: bool          — default false
├── isParticlesEnabled: bool      — default false
├── isColorOverlayEnabled: bool   — default false
├── isBlurEnabled: bool           — default false
├── iceCount: int                 — 0–5, default 3
```

### ParticleType (Hive TypeId: 2, Enum)
```
Values: snow, rain, fireflies, autumnLeaves, bubbles, stars
```

---

## State Management

Built entirely on **Riverpod** (`flutter_riverpod`):

### Providers

| Provider | Type | Purpose |
|---|---|---|
| `storageServiceProvider` | `Provider<StorageService>` | Global access to initialized storage (overridden at app launch) |
| `pexelsServiceProvider` | `Provider<PexelsService>` | Pexels API client (reads API key from storage) |
| `sensorServiceProvider` | `Provider<SensorService>` | Singleton gyroscope/accelerometer service |
| `gyroStreamProvider` | `StreamProvider<Map<String, double>>` | Smoothed gyroscope {x, y, z} stream |
| `accelStreamProvider` | `StreamProvider<Map<String, double>>` | Smoothed accelerometer {x, y, z} stream |
| `effectSettingsProvider` | `StateNotifierProvider<EffectNotifier, EffectSettings>` | Current active effect settings (in-memory, real-time) |
| `favoritesProvider` | `StateNotifierProvider<FavoritesNotifier, List<WallpaperModel>>` | Favorites list backed by Hive |
| `wallpaperListProvider` | `StateNotifierProvider.family<..., String>` | Paginated wallpaper list, keyed by search query (empty string = curated) |

### EffectNotifier Methods
```
setGyroSensitivity(double)    toggleGyro(bool)
toggleWater(bool)             setWaterLevel(double)
setWaterColor(String hex)     toggleParticles(bool)
setParticleType(int index)    setParticleCount(int)
toggleColorOverlay(bool)      setColorOverlayOpacity(double)
setColorOverlayHex(String)    toggleBlur(bool)
setBlurAmount(double)         setIceCount(int)
applyPreset(EffectSettings)   update(Function)
```

---

## Services & Backend

### PexelsService
- Wraps Pexels REST API with Authorization header
- `fetchCurated(page)` — Get curated wallpapers, paginated
- `search(query, page)` — Search by keyword, paginated
- Returns `List<WallpaperModel>` parsed from JSON
- 30 results per page

### SensorService (Singleton)
- Manages gyroscope and accelerometer streams via `sensors_plus`
- Low-pass filter (alpha = 0.15) for smooth sensor data
- Game-interval sampling rate
- `checkGyroscope()` — Proactive hardware detection with 2-second timeout
- `isGyroscopeAvailable` — Boolean flag for fallback logic
- Emits smoothed `{x, y, z}` maps via `gyroStream` and `accelStream`

### StorageService
- Unified local storage layer combining Hive + SharedPreferences
- Must be initialized before `runApp()` via `await storage.init()`
- **Hive Boxes:**
  - `favorites` — `Box<WallpaperModel>` for favorited wallpapers
  - `presets` — `Box<EffectSettings>` for saved effect presets
  - `myWallpapers` — `Box` for local image/video paths (raw strings with `image::`/`video::` prefixes)
- **SharedPreferences Keys:**
  - `pexels_api_key` — User's Pexels API key
  - `onboarding_complete` — Boolean, whether onboarding has been shown
  - `theme_mode` — String: "dark", "light", or "system"
  - `default_gyro_sensitivity` — Double, default parallax sensitivity

### WallpaperService
- `setWallpaper(filePath, location)` — Set static wallpaper via `async_wallpaper` plugin (home/lock/both)
- `setLiveWallpaper(imagePath, EffectSettings)` — Launch native Android live wallpaper picker via MethodChannel (`com.example.my_flutter_app/live_wallpaper`), passes all effect parameters to native `GyroLiveWallpaperService`
- `setVideoLiveWallpaper(videoPath, EffectSettings?)` — Launch video live wallpaper picker via MethodChannel, passes video path + optional effects to native `VideoLiveWallpaperService`

### ImageUtils
- `captureWidgetAsBytes(GlobalKey)` — Captures a RepaintBoundary widget as PNG bytes
- `saveBytesToTempFile(bytes)` — Saves bytes to a temporary file
- `saveImageForLiveWallpaper(imageUrl)` — Downloads or copies image to a persistent path for the live wallpaper service

### PermissionHelper
- `requestStoragePermission()` — Requests storage/media permission via `permission_handler`

---

## API Integration

### Pexels API
| Endpoint | URL | Purpose |
|---|---|---|
| Curated | `https://api.pexels.com/v1/curated?per_page=30&page={n}` | Browse curated photos |
| Search | `https://api.pexels.com/v1/search?query={q}&per_page=30&page={n}` | Keyword search |

**Authentication:** API key passed as `Authorization` header. User must enter their own free key in Settings.

**Response Parsing:** Each photo object maps to `WallpaperModel` via `fromPexelsJson()`:
- `src.original` → `url` (full-res)
- `src.medium` → `thumbUrl` (grid display)
- `photographer`, `photographer_url`, `width`, `height`, `avg_color` extracted directly

---

## Local Storage

### Hive Boxes
| Box Name | Type | Content |
|---|---|---|
| `favorites` | `Box<WallpaperModel>` | Keyed by wallpaper ID |
| `presets` | `Box<EffectSettings>` | Keyed by preset name |
| `myWallpapers` | `Box` (dynamic) | Raw strings: `image::/path` or `video::/path` |

### SharedPreferences Keys
| Key | Type | Default | Description |
|---|---|---|---|
| `pexels_api_key` | String | `""` | Pexels API key |
| `onboarding_complete` | bool | `false` | Onboarding shown flag |
| `theme_mode` | String | `"dark"` | Theme preference |
| `default_gyro_sensitivity` | double | `1.0` | Default parallax sensitivity |

---

## Theming & Design System

### Color Palette

#### Dark Theme (Default)
| Token | Hex | Usage |
|---|---|---|
| `darkBackground` | `#0D0D0D` | Scaffold background |
| `darkSurface` | `#1A1A1A` | AppBar, nav bar, cards |
| `darkCard` | `#232323` | Card backgrounds |
| `darkText` | `#F5F5F5` | Primary text color |

#### Light Theme
| Token | Hex | Usage |
|---|---|---|
| `lightBackground` | `#F2F2F2` | Scaffold background |
| `lightSurface` | `#FFFFFF` | AppBar, nav bar |
| `lightCard` | `#FFFFFF` | Card backgrounds |
| `lightText` | `#1A1A1A` | Primary text color |

#### Brand Colors
| Token | Hex | Usage |
|---|---|---|
| `primary` | `#6C63FF` | Primary accent (indigo/purple) |
| `secondary` | `#00BCD4` | Secondary accent (cyan) |
| `secondaryLight` | `#0097A7` | Secondary accent (light theme) |
| `error` | `#CF6679` | Error states |

### Typography
- Material 3 text theme
- `headlineLarge` — Bold (w700)
- `headlineMedium` — Semi-bold (w600)
- `bodyLarge` / `bodyMedium` — Regular weight

### Component Styling
- Cards: 16px border radius
- Buttons: 12px border radius, primary color background
- Bottom sheet: 20px top border radius with drag handle
- Shimmer loading: Base `#2A2A2A`, Highlight `#3A3A3A`

---

## Project Architecture

```
lib/
├── main.dart                          # Entry point: Hive init, sensor check, ProviderScope
├── app.dart                           # Root MaterialApp with theme + routing
│
├── core/                              # App-wide infrastructure
│   ├── constants/
│   │   ├── api_constants.dart         # Pexels API URLs and config
│   │   ├── app_colors.dart            # Color palette (dark, light, brand, preset colors)
│   │   └── app_strings.dart           # All UI strings and labels
│   ├── router/
│   │   └── app_router.dart            # Named route definitions and onGenerateRoute
│   ├── theme/
│   │   └── app_theme.dart             # Dark + Light ThemeData (Material 3)
│   └── utils/
│       ├── image_utils.dart           # Widget capture, file saving, image download
│       └── permission_helper.dart     # Storage permission requests
│
├── models/                            # Hive-persisted data classes
│   ├── wallpaper_model.dart           # WallpaperModel (TypeId: 0)
│   ├── wallpaper_model.g.dart         # Generated Hive adapter
│   ├── effect_settings.dart           # EffectSettings (TypeId: 1) + ParticleType enum (TypeId: 2)
│   └── effect_settings.g.dart         # Generated Hive adapter
│
├── services/                          # Business logic / external interfaces
│   ├── pexels_service.dart            # Pexels REST API client
│   ├── sensor_service.dart            # Gyroscope + accelerometer with low-pass filter
│   ├── storage_service.dart           # Hive + SharedPreferences unified storage
│   └── wallpaper_service.dart         # Static/live/video wallpaper setting (Android)
│
├── providers/                         # Riverpod state management
│   ├── effect_provider.dart           # EffectNotifier + effectSettingsProvider
│   ├── favorites_provider.dart        # FavoritesNotifier + favoritesProvider
│   ├── sensor_provider.dart           # Sensor streams + service providers
│   └── wallpaper_provider.dart        # WallpaperNotifier + wallpaperListProvider (family)
│
├── features/                          # Feature-based screen modules
│   ├── onboarding/
│   │   └── onboarding_screen.dart     # 3-page intro with page indicator
│   ├── home/
│   │   ├── home_screen.dart           # Shell with IndexedStack + BottomNavBar
│   │   └── widgets/
│   │       ├── featured_banner.dart   # Hero banner/carousel
│   │       └── category_chips.dart    # Horizontal category filter chips
│   ├── gallery/
│   │   ├── gallery_screen.dart        # Masonry grid of curated wallpapers
│   │   ├── search_screen.dart         # Keyword search with debounced input
│   │   └── widgets/
│   │       ├── wallpaper_card.dart    # Grid card with cached image + info
│   │       └── loading_shimmer.dart   # Shimmer placeholder
│   ├── preview/
│   │   ├── preview_screen.dart        # Full-screen preview with layered effects
│   │   ├── effect_panel.dart          # Draggable bottom sheet with 6 tabbed sections
│   │   └── widgets/
│   │       ├── gyro_parallax_layer.dart   # Image layer that moves with gyro
│   │       ├── video_player_layer.dart    # Looping video player
│   │       ├── water_overlay_widget.dart  # Water surface + ice cubes
│   │       ├── particle_overlay.dart      # Animated particle system
│   │       ├── color_overlay_widget.dart  # Color tint overlay
│   │       └── blur_overlay_widget.dart   # Gaussian blur overlay
│   ├── my_wallpapers/
│   │   ├── my_wallpapers_screen.dart  # User-picked images/videos grid
│   │   └── favorites_screen.dart      # Favorited wallpapers grid
│   └── settings/
│       └── settings_screen.dart       # API key, sensitivity, theme, sensor status
│
└── shared/                            # Reusable UI components
    ├── widgets/
    │   ├── bottom_nav_bar.dart        # 5-tab bottom navigation bar
    │   ├── custom_app_bar.dart        # Custom styled app bar
    │   └── loading_button.dart        # Button with loading state
    └── extensions/
        └── context_extensions.dart    # BuildContext extensions (showSnack, etc.)
```

---

## Complete File Structure

```
my_flutter_app/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
│
├── assets/
│   ├── images/                    # Static images (e.g., onboarding illustrations)
│   └── animations/                # Lottie or other animation files
│
├── lib/                           # (See Project Architecture above for full details)
│
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/                   # Native Android code (Live wallpaper services, MethodChannel)
│   ├── build.gradle
│   ├── settings.gradle
│   └── gradle/
│
├── ios/
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   └── Info.plist
│   └── Runner.xcodeproj/
│
├── web/
│   ├── index.html
│   └── manifest.json
│
├── linux/
├── macos/
├── windows/
│
└── test/
    └── widget_test.dart
```

---

## Tech Stack & Dependencies

### Flutter / Dart
| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK | UI framework |
| `flutter_riverpod` | ^2.5.1 | State management (providers, notifiers) |
| `sensors_plus` | ^6.1.1 | Gyroscope & accelerometer data |
| `water_fx` | ^1.0.15 | Water surface physics effect |
| `async_wallpaper` | ^2.0.0 | Set static wallpapers (Android) |
| `image_picker` | ^1.1.2 | Pick images/videos from gallery |
| `cached_network_image` | ^3.4.1 | Cached network image loading |
| `image` | ^4.2.0 | Image processing utilities |
| `http` | ^1.2.2 | HTTP client for Pexels API |
| `hive_flutter` | ^1.1.0 | Local NoSQL database |
| `hive` | ^2.2.3 | Hive core |
| `shared_preferences` | ^2.3.2 | Key-value persistent storage |
| `permission_handler` | ^11.3.1 | Runtime permission management |
| `flutter_staggered_grid_view` | ^0.7.0 | Masonry grid layout |
| `flutter_colorpicker` | ^1.1.0 | Color picker dialog for effects |
| `shimmer` | ^3.0.0 | Shimmer loading placeholder |
| `smooth_page_indicator` | ^1.2.0+1 | Page indicator for onboarding |
| `video_player` | ^2.9.2 | Video playback for video wallpapers |
| `path_provider` | ^2.1.4 | App directory paths |
| `uuid` | ^4.4.2 | UUID generation |
| `intl` | ^0.19.0 | Internationalization utilities |

### Dev Dependencies
| Package | Version | Purpose |
|---|---|---|
| `flutter_lints` | ^5.0.0 | Linting rules |
| `build_runner` | ^2.4.11 | Code generation runner |
| `hive_generator` | ^2.0.1 | Hive model adapter generation |

### Native (Android)
- Custom `MethodChannel` at `com.example.my_flutter_app/live_wallpaper`
- Native `GyroLiveWallpaperService` — Android live wallpaper service with gyroscope parallax + effects
- Native `VideoLiveWallpaperService` — Android live wallpaper service for looping video playback + effects

---

## User Flows

### Flow 1: First Launch
```
App Launch → Hive Init → Sensor Check → OnboardingScreen (3 pages)
→ User taps "Get Started" → onboarding_complete = true → HomeScreen
```

### Flow 2: Browse & Set Wallpaper
```
Home Tab → Sees curated gallery → Taps wallpaper card
→ PreviewScreen (full-screen with parallax)
→ Taps "Effects" → EffectPanel opens (adjust parallax, water, particles, overlay, blur)
→ Taps "Set" → Bottom sheet: choose Live Wallpaper / Home / Lock / Both
→ Wallpaper set confirmation
```

### Flow 3: Search Wallpapers
```
Home Tab → Taps search icon → SearchScreen
→ Types query (debounced 500ms) → Masonry grid fills with results
→ Taps result → PreviewScreen → (same as Flow 2)
```

### Flow 4: Use Own Image/Video
```
My Pics Tab → Taps FAB (+) → Bottom sheet: Add Image / Add Video
→ Image Picker opens → Selects file → Added to grid
→ Taps item → PreviewScreen with effects
→ For video: Video Live Wallpaper option available
```

### Flow 5: Manage Favorites
```
PreviewScreen → Taps heart icon → Toggled in Hive
→ Favorites Tab → Grid of all favorited wallpapers
→ Taps any → PreviewScreen
```

### Flow 6: Settings
```
Settings Tab → Enter Pexels API key → Save
→ Adjust default gyro sensitivity
→ Switch theme (Dark/Light/System)
→ Check sensor status
```

---

## Effect Presets Reference

Built-in presets that users can apply with one tap:

| Preset | Gyro | Sensitivity | Water | Water Level | Particles | Type | Count | Overlay | Overlay Color | Blur |
|---|---|---|---|---|---|---|---|---|---|---|
| **Pure Parallax** | ON | 3.0 | OFF | — | OFF | — | — | OFF | — | OFF |
| **Ocean Calm** | ON | 1.5 | ON | 25% | OFF | — | — | ON | Midnight Blue 10% | OFF |
| **Winter Night** | ON | 1.0 | OFF | — | ON | Snow | 60 | ON | Midnight Blue 20% | OFF |
| **Rainy Mood** | ON | 1.0 | OFF | — | ON | Rain | 80 | ON | Grey 15% | ON (3.0) |
| **Firefly Forest** | ON | 1.0 | OFF | — | ON | Fireflies | 30 | ON | Forest Green 10% | ON (1.5) |
| **Bare** | OFF | 1.0 | OFF | — | OFF | — | — | OFF | — | OFF |

---

## Key Technical Details for Frontend Generation

### UI Patterns Used
- **IndexedStack** for tab persistence (no rebuild when switching tabs)
- **DraggableScrollableSheet** for the effects panel (55% initial, 30% min, 85% max)
- **MasonryGridView** (staggered grid) for wallpaper galleries
- **CustomScrollView + Slivers** for the home screen (floating SliverAppBar)
- **RepaintBoundary** for capturing the preview as an image
- **ModalBottomSheet** for wallpaper-set options and media picker options
- **StreamProvider** for real-time sensor data
- **Family providers** for query-keyed paginated lists

### Design Guidelines
- Material 3 design system
- Dark theme is the default, with full light theme support
- Primary accent: Indigo/Purple (#6C63FF)
- Cards have 16px rounded corners
- Buttons have 12px rounded corners
- Bottom sheets have 20px top rounded corners with a centered 40x4px drag handle
- The preview screen is full-screen black background with gradient overlays for controls
- Loading states use shimmer placeholders (not spinners)
- Error/empty states show centered icon + message layout

### Responsive Considerations
- 2-column grid layout for wallpapers
- `SafeArea` used on all screens
- Adaptive to different screen sizes via Flutter's layout system

---

*Built with Flutter | Powered by Pexels API | Gyroscope-driven live wallpapers*
