import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/effect_settings.dart';

/// Manages the current active effect settings (in-memory, real-time).
class EffectNotifier extends StateNotifier<EffectSettings> {
  EffectNotifier() : super(EffectSettings());

  void update(EffectSettings Function(EffectSettings) updater) {
    state = updater(state);
  }

  void setGyroSensitivity(double v) =>
      state = state.copyWith(gyroSensitivity: v);

  void toggleGyro(bool v) => state = state.copyWith(isGyroEnabled: v);

  void toggleWater(bool v) => state = state.copyWith(isWaterEnabled: v);

  void setWaterLevel(double v) => state = state.copyWith(waterLevel: v);

  void setWaterColor(String hex) => state = state.copyWith(waterColor: hex);

  void toggleParticles(bool v) => state = state.copyWith(isParticlesEnabled: v);

  void setParticleType(int idx) =>
      state = state.copyWith(particleTypeIndex: idx);

  void setParticleCount(int c) => state = state.copyWith(particleCount: c);

  void toggleColorOverlay(bool v) =>
      state = state.copyWith(isColorOverlayEnabled: v);

  void setColorOverlayOpacity(double v) =>
      state = state.copyWith(colorOverlayOpacity: v);

  void setColorOverlayHex(String hex) =>
      state = state.copyWith(colorOverlayHex: hex);

  void toggleBlur(bool v) => state = state.copyWith(isBlurEnabled: v);

  void setBlurAmount(double v) => state = state.copyWith(blurAmount: v);

  void applyPreset(EffectSettings preset) => state = preset;
}

final effectSettingsProvider =
    StateNotifierProvider<EffectNotifier, EffectSettings>((ref) {
  return EffectNotifier();
});
