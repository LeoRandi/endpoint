// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaveDataAdapter extends TypeAdapter<SaveData> {
  @override
  final int typeId = 1;

  @override
  SaveData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaveData(
      version: fields[0] as int,
      playerName: fields[1] as String,
      level: fields[2] as int,
      hp: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SaveData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.version)
      ..writeByte(1)
      ..write(obj.playerName)
      ..writeByte(2)
      ..write(obj.level)
      ..writeByte(3)
      ..write(obj.hp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
