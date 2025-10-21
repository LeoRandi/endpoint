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

  /// HP actual
  @HiveField(3)
  final int hp;

  /// HP máximo
  @HiveField(4)
  final int maxHp;

  @HiveField(5)
  final int attack;

  @HiveField(6)
  final int defense;

  @HiveField(7)
  final int speed;

  @HiveField(8)
  final int constitution;

  @HiveField(9)
  final int flow;

  const SaveData({
    required this.version,
    required this.playerName,
    required this.level,
    required this.hp,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.constitution,
    required this.flow,
  });

  SaveData copyWith({
    int? version,
    String? playerName,
    int? level,
    int? hp,
    int? maxHp,
    int? attack,
    int? defense,
    int? speed,
    int? constitution,
    int? flow,
  }) {
    return SaveData(
      version: version ?? this.version,
      playerName: playerName ?? this.playerName,
      level: level ?? this.level,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      speed: speed ?? this.speed,
      constitution: constitution ?? this.constitution,
      flow: flow ?? this.flow,
    );
  }

  static int hpFromCon(int con) => (con * 3) + (con ~/ 3);

  static SaveData fresh() {
    const con = 2, atk = 2, def = 2, spd = 2, flw = 2;
    final maxHp = hpFromCon(con);
    return SaveData(
      version: 1,
      playerName: 'Héroe',
      level: 1,
      hp: maxHp,
      maxHp: maxHp,
      attack: atk,
      defense: def,
      speed: spd,
      constitution: con,
      flow: flw,
    );
  }
}
