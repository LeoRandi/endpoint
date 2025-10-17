import 'package:hive/hive.dart';

part 'save_data.g.dart';

@HiveType(typeId: 1)
class SaveData {
  @HiveField(0)
  final int version;

  @HiveField(1)
  final String playerName;

  @HiveField(2)
  final int level;

  @HiveField(3)
  final int hp;

  const SaveData({
    required this.version,
    required this.playerName,
    required this.level,
    required this.hp,
  });

  SaveData copyWith({int? version, String? playerName, int? level, int? hp}) {
    return SaveData(
      version: version ?? this.version,
      playerName: playerName ?? this.playerName,
      level: level ?? this.level,
      hp: hp ?? this.hp,
    );
  }

  static SaveData fresh() => const SaveData(
        version: 1,
        playerName: 'Héroe',
        level: 1,
        hp: 30,
      );
}
