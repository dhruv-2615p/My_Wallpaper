// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallpaper_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WallpaperModelAdapter extends TypeAdapter<WallpaperModel> {
  @override
  final int typeId = 0;

  @override
  WallpaperModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WallpaperModel(
      id: fields[0] as String,
      url: fields[1] as String,
      thumbUrl: fields[2] as String,
      photographer: fields[3] as String? ?? '',
      photographerUrl: fields[4] as String? ?? '',
      width: fields[5] as int? ?? 0,
      height: fields[6] as int? ?? 0,
      localPath: fields[7] as String?,
      avgColor: fields[8] as String? ?? '#000000',
    );
  }

  @override
  void write(BinaryWriter writer, WallpaperModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.thumbUrl)
      ..writeByte(3)
      ..write(obj.photographer)
      ..writeByte(4)
      ..write(obj.photographerUrl)
      ..writeByte(5)
      ..write(obj.width)
      ..writeByte(6)
      ..write(obj.height)
      ..writeByte(7)
      ..write(obj.localPath)
      ..writeByte(8)
      ..write(obj.avgColor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WallpaperModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
