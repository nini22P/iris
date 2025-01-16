// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MediaInfoAdapter extends TypeAdapter<MediaInfo> {
  @override
  final int typeId = 1;

  @override
  MediaInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaInfo(
      position: fields[0] as Duration,
      duration: fields[1] as Duration,
    );
  }

  @override
  void write(BinaryWriter writer, MediaInfo obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.position)
      ..writeByte(1)
      ..write(obj.duration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
