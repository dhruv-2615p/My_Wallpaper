import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wallpaper_model.dart';
import '../../providers/effect_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../core/utils/image_utils.dart';
import '../../services/wallpaper_service.dart';
import '../../shared/extensions/context_extensions.dart';
import 'widgets/gyro_parallax_layer.dart';
import 'widgets/water_overlay_widget.dart';
import 'widgets/particle_overlay.dart';
import 'widgets/color_overlay_widget.dart';
import 'widgets/blur_overlay_widget.dart';
import 'effect_panel.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  final WallpaperModel wallpaper;

  const PreviewScreen({super.key, required this.wallpaper});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSettingWallpaper = false;

  Color _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 8) return Color(int.parse('0x$hex'));
    return Color(int.parse('0xFF$hex'));
  }

  Future<void> _setWallpaper(int location) async {
    setState(() => _isSettingWallpaper = true);
    try {
      final bytes = await ImageUtils.captureWidgetAsBytes(_repaintKey);
      if (bytes == null) {
        if (mounted) context.showSnack('Failed to capture wallpaper');
        return;
      }
      final path = await ImageUtils.saveBytesToTempFile(bytes);
      if (path == null) {
        if (mounted) context.showSnack('Failed to save temp file');
        return;
      }
      final ok = await WallpaperService.setWallpaper(path, location);
      if (mounted) {
        context.showSnack(ok ? 'Wallpaper set!' : 'Failed to set wallpaper');
      }
    } finally {
      if (mounted) setState(() => _isSettingWallpaper = false);
    }
  }

  void _showSetWallpaperDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Set Wallpaper',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('Home Screen'),
              onTap: () {
                Navigator.pop(context);
                _setWallpaper(WallpaperService.homeScreen);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_rounded),
              title: const Text('Lock Screen'),
              onTap: () {
                Navigator.pop(context);
                _setWallpaper(WallpaperService.lockScreen);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_android_rounded),
              title: const Text('Both Screens'),
              onTap: () {
                Navigator.pop(context);
                _setWallpaper(WallpaperService.bothScreens);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fx = ref.watch(effectSettingsProvider);
    final isFav =
        ref.watch(favoritesProvider.notifier).isFavorite(widget.wallpaper.id);
    final imageUrl = widget.wallpaper.isLocal
        ? widget.wallpaper.localPath!
        : widget.wallpaper.url;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Capture boundary for wallpaper setting
          RepaintBoundary(
            key: _repaintKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Layer 0: Base image + parallax
                GyroParallaxLayer(
                  imageUrl: imageUrl,
                  sensitivity: fx.isGyroEnabled ? fx.gyroSensitivity : 0,
                  layerDepth: 0.0,
                ),

                // Layer 1: Water
                if (fx.isWaterEnabled)
                  WaterOverlayWidget(
                    waterLevel: fx.waterLevel,
                    waterColor: _parseHex(fx.waterColor),
                  ),

                // Layer 2: Particles
                if (fx.isParticlesEnabled)
                  ParticleOverlay(
                    type: fx.particleType,
                    count: fx.particleCount,
                  ),

                // Layer 3: Color overlay
                if (fx.isColorOverlayEnabled)
                  ColorOverlayWidget(
                    color: _parseHex(fx.colorOverlayHex),
                    opacity: fx.colorOverlayOpacity,
                  ),

                // Layer 4: Blur
                if (fx.isBlurEnabled)
                  BlurOverlayWidget(blurAmount: fx.blurAmount),
              ],
            ),
          ),

          // Loading overlay
          if (_isSettingWallpaper)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    if (widget.wallpaper.photographer.isNotEmpty)
                      Text(
                        widget.wallpaper.photographer,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: Icons.auto_fix_high_rounded,
                      label: 'Effects',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const EffectPanel(),
                      ),
                    ),
                    _ActionButton(
                      icon: Icons.phone_android_rounded,
                      label: 'Set',
                      onTap: _showSetWallpaperDialog,
                    ),
                    _ActionButton(
                      icon: isFav ? Icons.favorite : Icons.favorite_border,
                      label: 'Fav',
                      color: isFav ? Colors.redAccent : Colors.white,
                      onTap: () => ref
                          .read(favoritesProvider.notifier)
                          .toggle(widget.wallpaper),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
