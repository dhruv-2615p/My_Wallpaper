import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/permission_helper.dart';
import '../../models/wallpaper_model.dart';
import '../../services/storage_service.dart';
import '../../main.dart' show storageServiceProvider;
import '../../shared/extensions/context_extensions.dart';

/// Provider for the local storage service instance used by this screen.
final _localStorageProvider = Provider<StorageService>((ref) {
  return ref.watch(storageServiceProvider);
});

/// Provider for user-picked wallpaper paths.
final _myWallpapersProvider =
    StateNotifierProvider<_MyWallpapersNotifier, List<_StoredWallpaper>>((ref) {
  return _MyWallpapersNotifier(ref.watch(_localStorageProvider));
});

class _StoredWallpaper {
  static const String _imagePrefix = 'image::';
  static const String _videoPrefix = 'video::';

  final String path;
  final bool isVideo;

  const _StoredWallpaper({required this.path, required this.isVideo});

  factory _StoredWallpaper.fromRaw(String raw) {
    if (raw.startsWith(_videoPrefix)) {
      return _StoredWallpaper(
          path: raw.substring(_videoPrefix.length), isVideo: true);
    }
    if (raw.startsWith(_imagePrefix)) {
      return _StoredWallpaper(
          path: raw.substring(_imagePrefix.length), isVideo: false);
    }
    return _StoredWallpaper(path: raw, isVideo: false);
  }

  String toRaw() => isVideo ? '$_videoPrefix$path' : '$_imagePrefix$path';
}

class _MyWallpapersNotifier extends StateNotifier<List<_StoredWallpaper>> {
  final StorageService _storage;

  _MyWallpapersNotifier(this._storage)
      : super(
          _storage.getMyWallpaperPaths().map(_StoredWallpaper.fromRaw).toList(),
        );

  List<_StoredWallpaper> _readAll() {
    return _storage
        .getMyWallpaperPaths()
        .map(_StoredWallpaper.fromRaw)
        .toList();
  }

  Future<void> addImage(String path) async {
    await _storage
        .addMyWallpaper(_StoredWallpaper(path: path, isVideo: false).toRaw());
    state = _readAll();
  }

  Future<void> addVideo(String path) async {
    await _storage
        .addMyWallpaper(_StoredWallpaper(path: path, isVideo: true).toRaw());
    state = _readAll();
  }

  Future<void> removeAt(int index) async {
    await _storage.removeMyWallpaper(index);
    state = _readAll();
  }
}

class MyWallpapersScreen extends ConsumerWidget {
  const MyWallpapersScreen({super.key});

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    final granted = await PermissionHelper.requestStoragePermission();
    if (!granted) {
      if (context.mounted) context.showSnack('Storage permission denied');
      return;
    }
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      await ref.read(_myWallpapersProvider.notifier).addImage(picked.path);
    }
  }

  Future<void> _pickVideo(BuildContext context, WidgetRef ref) async {
    final granted = await PermissionHelper.requestStoragePermission();
    if (!granted) {
      if (context.mounted) context.showSnack('Storage permission denied');
      return;
    }
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      await ref.read(_myWallpapersProvider.notifier).addVideo(picked.path);
    }
  }

  Future<void> _showAddOptions(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Add Image'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_file_outlined),
              title: const Text('Add Video'),
              subtitle: const Text('For live wallpaper on Android'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTap(BuildContext context, _StoredWallpaper item) {
    final model = item.isVideo
        ? WallpaperModel.fromLocalVideo(item.path)
        : WallpaperModel.fromLocal(item.path);
    Navigator.pushNamed(
      context,
      AppRouter.preview,
      arguments: model,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paths = ref.watch(_myWallpapersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallpapers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context, ref),
        child: const Icon(Icons.add_photo_alternate_rounded),
      ),
      body: paths.isEmpty
          ? const Center(
              child: Text(
                'Tap + to add your own images or videos',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.65,
              ),
              itemCount: paths.length,
              itemBuilder: (context, index) {
                final item = paths[index];
                return Dismissible(
                  key: ValueKey(item.toRaw()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) =>
                      ref.read(_myWallpapersProvider.notifier).removeAt(index),
                  child: GestureDetector(
                    onTap: () => _onItemTap(context, item),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: item.isVideo
                          ? Container(
                              color: Colors.grey.shade900,
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            )
                          : Image.file(
                              File(item.path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade800,
                                child: const Icon(Icons.broken_image,
                                    color: Colors.grey),
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
