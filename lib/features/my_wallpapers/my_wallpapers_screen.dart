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
    StateNotifierProvider<_MyWallpapersNotifier, List<String>>((ref) {
  return _MyWallpapersNotifier(ref.watch(_localStorageProvider));
});

class _MyWallpapersNotifier extends StateNotifier<List<String>> {
  final StorageService _storage;

  _MyWallpapersNotifier(this._storage) : super(_storage.getMyWallpaperPaths());

  Future<void> add(String path) async {
    await _storage.addMyWallpaper(path);
    state = _storage.getMyWallpaperPaths();
  }

  Future<void> removeAt(int index) async {
    await _storage.removeMyWallpaper(index);
    state = _storage.getMyWallpaperPaths();
  }
}

class MyWallpapersScreen extends ConsumerWidget {
  const MyWallpapersScreen({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final granted = await PermissionHelper.requestStoragePermission();
    if (!granted) {
      if (context.mounted) context.showSnack('Storage permission denied');
      return;
    }
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      await ref.read(_myWallpapersProvider.notifier).add(picked.path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paths = ref.watch(_myWallpapersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallpapers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pick(context, ref),
        child: const Icon(Icons.add_photo_alternate_rounded),
      ),
      body: paths.isEmpty
          ? const Center(
              child: Text(
                'Tap + to add your own images',
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
                final path = paths[index];
                final model = WallpaperModel.fromLocal(path);
                return Dismissible(
                  key: ValueKey(path),
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
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.preview,
                      arguments: model,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(path),
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
