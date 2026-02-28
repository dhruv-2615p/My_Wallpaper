import 'package:hive/hive.dart';

part 'effect_settings.g.dart';

/// Types of particle effects.
@HiveType(typeId: 2)
enum ParticleType {
  @HiveField(0)
  snow,
  @HiveField(1)
  rain,
  @HiveField(2)
  fireflies,
  @HiveField(3)
  autumnLeaves,
  @HiveField(4)
  bubbles,
  @HiveField(5)
  stars,
}

/// Persisted effect preset.
@HiveType(typeId: 1)
class EffectSettings extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double gyroSensitivity;

  @HiveField(2)
  double waterLevel; // 0.0 – 0.5

  @HiveField(3)
  String waterColor; // hex string

  @HiveField(4)
  int particleTypeIndex; // index into ParticleType.values

  @HiveField(5)
  int particleCount;

  @HiveField(6)
  double colorOverlayOpacity;

  @HiveField(7)
  String colorOverlayHex;

  @HiveField(8)
  double blurAmount;

  @HiveField(9)
  bool isGyroEnabled;

  @HiveField(10)
  bool isWaterEnabled;

  @HiveField(11)
  bool isParticlesEnabled;

  @HiveField(12)
  bool isColorOverlayEnabled;

  @HiveField(13)
  bool isBlurEnabled;

  @HiveField(14)
  int iceCount; // 0–5 floating ice cubes

  EffectSettings({
    this.name = 'Custom',
    this.gyroSensitivity = 1.0,
    this.waterLevel = 0.2,
    this.waterColor = '#9900BFFF',
    this.particleTypeIndex = 0,
    this.particleCount = 50,
    this.colorOverlayOpacity = 0.15,
    this.colorOverlayHex = '#191970',
    this.blurAmount = 0.0,
    this.isGyroEnabled = true,
    this.isWaterEnabled = false,
    this.isParticlesEnabled = false,
    this.isColorOverlayEnabled = false,
    this.isBlurEnabled = false,
    this.iceCount = 3,
  });

  ParticleType get particleType => ParticleType
      .values[particleTypeIndex.clamp(0, ParticleType.values.length - 1)];

  set particleType(ParticleType type) => particleTypeIndex = type.index;

  EffectSettings copyWith({
    String? name,
    double? gyroSensitivity,
    double? waterLevel,
    String? waterColor,
    int? particleTypeIndex,
    int? particleCount,
    double? colorOverlayOpacity,
    String? colorOverlayHex,
    double? blurAmount,
    bool? isGyroEnabled,
    bool? isWaterEnabled,
    bool? isParticlesEnabled,
    bool? isColorOverlayEnabled,
    bool? isBlurEnabled,
    int? iceCount,
  }) {
    return EffectSettings(
      name: name ?? this.name,
      gyroSensitivity: gyroSensitivity ?? this.gyroSensitivity,
      waterLevel: waterLevel ?? this.waterLevel,
      waterColor: waterColor ?? this.waterColor,
      particleTypeIndex: particleTypeIndex ?? this.particleTypeIndex,
      particleCount: particleCount ?? this.particleCount,
      colorOverlayOpacity: colorOverlayOpacity ?? this.colorOverlayOpacity,
      colorOverlayHex: colorOverlayHex ?? this.colorOverlayHex,
      blurAmount: blurAmount ?? this.blurAmount,
      isGyroEnabled: isGyroEnabled ?? this.isGyroEnabled,
      isWaterEnabled: isWaterEnabled ?? this.isWaterEnabled,
      isParticlesEnabled: isParticlesEnabled ?? this.isParticlesEnabled,
      isColorOverlayEnabled:
          isColorOverlayEnabled ?? this.isColorOverlayEnabled,
      isBlurEnabled: isBlurEnabled ?? this.isBlurEnabled,
      iceCount: iceCount ?? this.iceCount,
    );
  }

  // ── Built-in presets ──

  static EffectSettings pureParallax() => EffectSettings(
        name: 'Pure Parallax',
        gyroSensitivity: 3.0,
        isGyroEnabled: true,
      );

  static EffectSettings oceanCalm() => EffectSettings(
        name: 'Ocean Calm',
        gyroSensitivity: 1.5,
        isGyroEnabled: true,
        isWaterEnabled: true,
        waterLevel: 0.25,
        waterColor: '#AA0088CC',
        iceCount: 3,
        isColorOverlayEnabled: true,
        colorOverlayHex: '#191970',
        colorOverlayOpacity: 0.10,
      );

  static EffectSettings winterNight() => EffectSettings(
        name: 'Winter Night',
        gyroSensitivity: 1.0,
        isGyroEnabled: true,
        isParticlesEnabled: true,
        particleTypeIndex: ParticleType.snow.index,
        particleCount: 60,
        isColorOverlayEnabled: true,
        colorOverlayHex: '#191970',
        colorOverlayOpacity: 0.20,
      );

  static EffectSettings rainyMood() => EffectSettings(
        name: 'Rainy Mood',
        isGyroEnabled: true,
        isParticlesEnabled: true,
        particleTypeIndex: ParticleType.rain.index,
        particleCount: 80,
        isBlurEnabled: true,
        blurAmount: 3.0,
        isColorOverlayEnabled: true,
        colorOverlayHex: '#808080',
        colorOverlayOpacity: 0.15,
      );

  static EffectSettings fireflyForest() => EffectSettings(
        name: 'Firefly Forest',
        isGyroEnabled: true,
        isParticlesEnabled: true,
        particleTypeIndex: ParticleType.fireflies.index,
        particleCount: 30,
        isColorOverlayEnabled: true,
        colorOverlayHex: '#228B22',
        colorOverlayOpacity: 0.10,
        isBlurEnabled: true,
        blurAmount: 1.5,
      );

  static EffectSettings bare() => EffectSettings(name: 'Bare');

  static List<EffectSettings> get builtInPresets => [
        pureParallax(),
        oceanCalm(),
        winterNight(),
        rainyMood(),
        fireflyForest(),
        bare(),
      ];
}
