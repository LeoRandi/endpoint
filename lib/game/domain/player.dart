import 'character.dart';
import 'stats.dart';

class Player extends Character {
  Player({required super.name, required super.stats});

  factory Player.basic({required String name}) => Player(
        name: name,
        stats: const Stats(maxHp: 30, attack: 8, defense: 3, speed: 5),
      );
}
