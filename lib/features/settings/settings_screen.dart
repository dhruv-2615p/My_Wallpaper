import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/sensor_service.dart';
import '../../services/storage_service.dart';
import '../../main.dart' show storageServiceProvider;
import '../../shared/extensions/context_extensions.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _apiKeyController;
  late StorageService _storage;
  double _sensitivity = 1.0;
  String _themeMode = 'dark';

  @override
  void initState() {
    super.initState();
    _storage = ref.read(storageServiceProvider);
    _apiKeyController = TextEditingController(text: _storage.pexelsApiKey);
    _sensitivity = _storage.defaultGyroSensitivity;
    _themeMode = _storage.themeMode;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensor = SensorService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Pexels API Key ──
          _SectionHeader('Pexels API Key'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Paste your Pexels API key',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save_rounded),
                  onPressed: () async {
                    await _storage
                        .setPexelsApiKey(_apiKeyController.text.trim());
                    if (!context.mounted) return;
                    context.showSnack('API key saved');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextButton.icon(
              onPressed: () {
                // Could launch URL, but keeping it simple
                context.showSnack(
                    'Visit https://www.pexels.com/api/ for a free key');
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Get free API key'),
            ),
          ),

          const Divider(),

          // ── Gyro Sensitivity ──
          _SectionHeader('Default Gyro Sensitivity'),
          ListTile(
            title: Slider(
              value: _sensitivity,
              min: 0.5,
              max: 5.0,
              divisions: 18,
              label: '${_sensitivity.toStringAsFixed(1)}x',
              onChanged: (v) => setState(() => _sensitivity = v),
              onChangeEnd: (v) => _storage.setDefaultGyroSensitivity(v),
            ),
            trailing: Text('${_sensitivity.toStringAsFixed(1)}x'),
          ),

          const Divider(),

          // ── Theme ──
          _SectionHeader('Theme'),
          ..._buildThemeTiles(),

          const Divider(),

          // ── Sensor Status ──
          _SectionHeader('Sensor Status'),
          ListTile(
            leading: Icon(
              sensor.isGyroscopeAvailable ? Icons.sensors : Icons.sensors_off,
              color: sensor.isGyroscopeAvailable ? Colors.green : Colors.red,
            ),
            title: Text(
              sensor.isGyroscopeAvailable
                  ? 'Gyroscope available'
                  : 'Gyroscope not detected',
            ),
            subtitle: sensor.isGyroscopeAvailable
                ? null
                : const Text('Touch-drag fallback will be used'),
          ),

          const Divider(),

          // ── About ──
          _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('GyroWall'),
            subtitle: Text('v1.0.0 • Live parallax wallpaper manager'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'GyroWall',
              applicationVersion: '1.0.0',
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _buildThemeTiles() {
    return ['dark', 'light', 'system'].map((mode) {
      return RadioListTile<String>(
        title: Text(mode[0].toUpperCase() + mode.substring(1)),
        value: mode,
        groupValue: _themeMode,
        onChanged: (v) {
          if (v != null) {
            setState(() => _themeMode = v);
            _storage.setThemeMode(v);
          }
        },
      );
    }).toList();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
