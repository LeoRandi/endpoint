import '../domain/enemy.dart';
import '../domain/character.dart';
import '../domain/action.dart';

class EnemyAI {
  BattleAction decide(Enemy enemy, List<Character> foes) {
    // Simple: atacar siempre
    return const BattleAction.attack();
  }
}
