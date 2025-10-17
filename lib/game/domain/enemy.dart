import 'character.dart';
import 'stats.dart';

class Enemy extends Character {
  Enemy({required super.name, required super.stats});

  factory Enemy.basic({required String name}) => Enemy(
        name: name,
        stats: const Stats(maxHp: 18, attack: 5, defense: 2, speed: 3),
      );
}
