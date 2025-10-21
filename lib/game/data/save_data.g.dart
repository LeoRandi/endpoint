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
      maxHp: fields[4] as int,
      attack: fields[5] as int,
      defense: fields[6] as int,
      speed: fields[7] as int,
      constitution: fields[8] as int,
      flow: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SaveData obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.version)
      ..writeByte(1)
      ..write(obj.playerName)
      ..writeByte(2)
      ..write(obj.level)
      ..writeByte(3)
      ..write(obj.hp)
      ..writeByte(4)
      ..write(obj.maxHp)
      ..writeByte(5)
      ..write(obj.attack)
      ..writeByte(6)
      ..write(obj.defense)
      ..writeByte(7)
      ..write(obj.speed)
      ..writeByte(8)
      ..write(obj.constitution)
      ..writeByte(9)
      ..write(obj.flow);
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
