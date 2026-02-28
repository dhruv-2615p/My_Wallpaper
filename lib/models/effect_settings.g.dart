// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'effect_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EffectSettingsAdapter extends TypeAdapter<EffectSettings> {
  @override
  final int typeId = 1;

  @override
  EffectSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EffectSettings(
      name: fields[0] as String? ?? 'Custom',
      gyroSensitivity: fields[1] as double? ?? 1.0,
      waterLevel: fields[2] as double? ?? 0.2,
      waterColor: fields[3] as String? ?? '#4400BFFF',
      particleTypeIndex: fields[4] as int? ?? 0,
      particleCount: fields[5] as int? ?? 50,
      colorOverlayOpacity: fields[6] as double? ?? 0.15,
      colorOverlayHex: fields[7] as String? ?? '#191970',
      blurAmount: fields[8] as double? ?? 0.0,
      isGyroEnabled: fields[9] as bool? ?? true,
      isWaterEnabled: fields[10] as bool? ?? false,
      isParticlesEnabled: fields[11] as bool? ?? false,
      isColorOverlayEnabled: fields[12] as bool? ?? false,
      isBlurEnabled: fields[13] as bool? ?? false,
      iceCount: fields[14] as int? ?? 3,
    );
  }

  @override
  void write(BinaryWriter writer, EffectSettings obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.gyroSensitivity)
      ..writeByte(2)
      ..write(obj.waterLevel)
      ..writeByte(3)
      ..write(obj.waterColor)
      ..writeByte(4)
      ..write(obj.particleTypeIndex)
      ..writeByte(5)
      ..write(obj.particleCount)
      ..writeByte(6)
      ..write(obj.colorOverlayOpacity)
      ..writeByte(7)
      ..write(obj.colorOverlayHex)
      ..writeByte(8)
      ..write(obj.blurAmount)
      ..writeByte(9)
      ..write(obj.isGyroEnabled)
      ..writeByte(10)
      ..write(obj.isWaterEnabled)
      ..writeByte(11)
      ..write(obj.isParticlesEnabled)
      ..writeByte(12)
      ..write(obj.isColorOverlayEnabled)
      ..writeByte(13)
      ..write(obj.isBlurEnabled)
      ..writeByte(14)
      ..write(obj.iceCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EffectSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ParticleTypeAdapter extends TypeAdapter<ParticleType> {
  @override
  final int typeId = 2;

  @override
  ParticleType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ParticleType.snow;
      case 1:
        return ParticleType.rain;
      case 2:
        return ParticleType.fireflies;
      case 3:
        return ParticleType.autumnLeaves;
      case 4:
        return ParticleType.bubbles;
      case 5:
        return ParticleType.stars;
      default:
        return ParticleType.snow;
    }
  }

  @override
  void write(BinaryWriter writer, ParticleType obj) {
    switch (obj) {
      case ParticleType.snow:
        writer.writeByte(0);
        break;
      case ParticleType.rain:
        writer.writeByte(1);
        break;
      case ParticleType.fireflies:
        writer.writeByte(2);
        break;
      case ParticleType.autumnLeaves:
        writer.writeByte(3);
        break;
      case ParticleType.bubbles:
        writer.writeByte(4);
        break;
      case ParticleType.stars:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticleTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
