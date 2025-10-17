class Stats {
  final int maxHp;
  final int attack;
  final int defense;
  final int speed;

  const Stats({required this.maxHp, required this.attack, required this.defense, required this.speed});

  Stats copyWith({int? maxHp, int? attack, int? defense, int? speed}) => Stats(
    maxHp: maxHp ?? this.maxHp,
    attack: attack ?? this.attack,
    defense: defense ?? this.defense,
    speed: speed ?? this.speed,
  );
}
