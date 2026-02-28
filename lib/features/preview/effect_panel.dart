import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../models/effect_settings.dart';
import '../../providers/effect_provider.dart';
import '../../core/constants/app_colors.dart';

/// Draggable bottom-sheet panel to tune all live effects.
class EffectPanel extends ConsumerStatefulWidget {
  const EffectPanel({super.key});

  @override
  ConsumerState<EffectPanel> createState() => _EffectPanelState();
}

class _EffectPanelState extends ConsumerState<EffectPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    'Parallax',
    'Water',
    'Particles',
    'Overlay',
    'Blur',
    'Presets'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 8) return Color(int.parse('0x$hex'));
    return Color(int.parse('0xFF$hex'));
  }

  String _toHex(Color c) {
    final v = (c.a * 255).round().toRadixString(16).padLeft(2, '0') +
        (c.r * 255).round().toRadixString(16).padLeft(2, '0') +
        (c.g * 255).round().toRadixString(16).padLeft(2, '0') +
        (c.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${v.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final fx = ref.watch(effectSettingsProvider);
    final notifier = ref.read(effectSettingsProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── Parallax Tab ──
                    _TabContent(
                      controller: scrollController,
                      children: [
                        SwitchListTile(
                          title: const Text('Enable Gyro Parallax'),
                          value: fx.isGyroEnabled,
                          onChanged: notifier.toggleGyro,
                        ),
                        ListTile(
                          title: const Text('Sensitivity'),
                          subtitle: Slider(
                            value: fx.gyroSensitivity,
                            min: 0.5,
                            max: 5.0,
                            divisions: 18,
                            label: fx.gyroSensitivity.toStringAsFixed(1),
                            onChanged: notifier.setGyroSensitivity,
                          ),
                        ),
                      ],
                    ),

                    // ── Water Tab ──
                    _TabContent(
                      controller: scrollController,
                      children: [
                        SwitchListTile(
                          title: const Text('Enable Water Effect'),
                          value: fx.isWaterEnabled,
                          onChanged: notifier.toggleWater,
                        ),
                        ListTile(
                          title: const Text('Water Level'),
                          subtitle: Slider(
                            value: fx.waterLevel,
                            min: 0.0,
                            max: 0.5,
                            divisions: 20,
                            label: '${(fx.waterLevel * 100).round()}%',
                            onChanged: notifier.setWaterLevel,
                          ),
                        ),
                        ListTile(
                          title: const Text('Ice Cubes'),
                          subtitle: Slider(
                            value: fx.iceCount.toDouble(),
                            min: 0,
                            max: 5,
                            divisions: 5,
                            label: fx.iceCount.toString(),
                            onChanged: (v) =>
                                notifier.setIceCount(v.round()),
                          ),
                        ),
                        ListTile(
                          title: const Text('Water Color'),
                          trailing: GestureDetector(
                            onTap: () => _pickColor(
                              _parseHex(fx.waterColor),
                              (c) => notifier.setWaterColor(_toHex(c)),
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: _parseHex(fx.waterColor),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Particles Tab ──
                    _TabContent(
                      controller: scrollController,
                      children: [
                        SwitchListTile(
                          title: const Text('Enable Particles'),
                          value: fx.isParticlesEnabled,
                          onChanged: notifier.toggleParticles,
                        ),
                        ListTile(
                          title: const Text('Type'),
                          trailing: DropdownButton<int>(
                            value: fx.particleTypeIndex,
                            items: ParticleType.values.map((t) {
                              return DropdownMenuItem(
                                value: t.index,
                                child: Text(t.name[0].toUpperCase() +
                                    t.name.substring(1)),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) notifier.setParticleType(v);
                            },
                          ),
                        ),
                        ListTile(
                          title: const Text('Count'),
                          subtitle: Slider(
                            value: fx.particleCount.toDouble(),
                            min: 10,
                            max: 150,
                            divisions: 14,
                            label: fx.particleCount.toString(),
                            onChanged: (v) =>
                                notifier.setParticleCount(v.round()),
                          ),
                        ),
                      ],
                    ),

                    // ── Overlay Tab ──
                    _TabContent(
                      controller: scrollController,
                      children: [
                        SwitchListTile(
                          title: const Text('Enable Color Overlay'),
                          value: fx.isColorOverlayEnabled,
                          onChanged: notifier.toggleColorOverlay,
                        ),
                        ListTile(
                          title: const Text('Opacity'),
                          subtitle: Slider(
                            value: fx.colorOverlayOpacity,
                            min: 0.05,
                            max: 0.6,
                            divisions: 22,
                            label: fx.colorOverlayOpacity.toStringAsFixed(2),
                            onChanged: notifier.setColorOverlayOpacity,
                          ),
                        ),
                        ListTile(
                          title: const Text('Color'),
                          trailing: GestureDetector(
                            onTap: () => _pickColor(
                              _parseHex(fx.colorOverlayHex),
                              (c) => notifier.setColorOverlayHex(_toHex(c)),
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: _parseHex(fx.colorOverlayHex),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Presets',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _colorPreset(
                                'Midnight', AppColors.midnightBlue, notifier),
                            _colorPreset(
                                'Rose Gold', AppColors.roseGold, notifier),
                            _colorPreset(
                                'Emerald', AppColors.emerald, notifier),
                            _colorPreset(
                                'Sunset', AppColors.sunsetOrange, notifier),
                            _colorPreset(
                                'Frost', AppColors.frostedWhite, notifier),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                    // ── Blur Tab ──
                    _TabContent(
                      controller: scrollController,
                      children: [
                        SwitchListTile(
                          title: const Text('Enable Blur'),
                          value: fx.isBlurEnabled,
                          onChanged: notifier.toggleBlur,
                        ),
                        ListTile(
                          title: const Text('Blur Amount'),
                          subtitle: Slider(
                            value: fx.blurAmount,
                            min: 0,
                            max: 20,
                            divisions: 40,
                            label: fx.blurAmount.toStringAsFixed(1),
                            onChanged: notifier.setBlurAmount,
                          ),
                        ),
                      ],
                    ),

                    // ── Presets Tab ──
                    _TabContent(
                      controller: scrollController,
                      children: EffectSettings.builtInPresets.map((preset) {
                        return ListTile(
                          title: Text(preset.name),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => notifier.applyPreset(preset),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _colorPreset(String label, Color color, EffectNotifier notifier) {
    return GestureDetector(
      onTap: () => notifier.setColorOverlayHex(_toHex(color)),
      child: Chip(
        avatar: CircleAvatar(backgroundColor: color, radius: 10),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  void _pickColor(Color initial, ValueChanged<Color> onPicked) {
    Color picked = initial;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initial,
            onColorChanged: (c) => picked = c,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onPicked(picked);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  final ScrollController controller;
  final List<Widget> children;

  const _TabContent({required this.controller, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: children,
    );
  }
}
