import 'stats.dart';

abstract class Character {
  final String name;
  final Stats stats;
  int currentHp;

  Character({required this.name, required this.stats}) : currentHp = stats.maxHp;

  bool get isAlive => currentHp > 0;
  void receiveDamage(int dmg) {
    currentHp = (currentHp - dmg).clamp(0, stats.maxHp);
  }
}
