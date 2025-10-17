import '../domain/character.dart';
import 'rng.dart';

class DamageCalculator {
  final Rng rng;
  DamageCalculator(this.rng);

  int basicAttack(Character attacker, Character defender) {
    final base = attacker.stats.attack - defender.stats.defense;
    final variance = rng.range(-1, 2);
    return (base + variance).clamp(1, 999);
  }
}
