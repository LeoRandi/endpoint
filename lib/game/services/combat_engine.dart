import '../domain/player.dart';
import '../domain/enemy.dart';
import 'battle_state.dart';
import 'damage_calculator.dart';
import 'enemy_ai.dart';
import 'rng.dart';

typedef LogFn = void Function(String);

class CombatEngine {
  final BattleState state;
  final LogFn onLog;
  final DamageCalculator _calc;
  final EnemyAI _ai = EnemyAI();

  CombatEngine({required this.state, required this.onLog})
      : _calc = DamageCalculator(Rng());

  void playerBasicAttack() {
    if (state.isBattleOver) return;
    final player = _firstAlivePlayer();
    final enemy = _firstAliveEnemy();
    if (player == null || enemy == null) return;
    final dmg = _calc.basicAttack(player, enemy);
    enemy.receiveDamage(dmg);
    onLog('${player.name} golpea a ${enemy.name} por $dmg');
    _enemyTurn();
    _checkEnd();
  }

  void playerDefend() {
    if (state.isBattleOver) return;
    final player = _firstAlivePlayer();
    if (player == null) return;
    onLog('${player.name} se defiende.');
    _enemyTurn();
    _checkEnd();
  }

  void _enemyTurn() {
    if (state.isBattleOver) return;
    final enemy = _firstAliveEnemy();
    final player = _firstAlivePlayer();
    if (enemy == null || player == null) return;
    final _ = _ai.decide(enemy, [player]);
    final dmg = _calc.basicAttack(enemy, player);
    player.receiveDamage(dmg);
    onLog('${enemy.name} ataca a ${player.name} por $dmg');
  }

  void _checkEnd() {
    if (!state.party.anyAlive) onLog('Has sido derrotado...');
    if (state.enemies.every((e) => !e.isAlive)) onLog('¡Victoria!');
  }

  Player? _firstAlivePlayer() {
    for (final p in state.party.players) {
      if (p.isAlive) return p;
    }
    return null;
  }

  Enemy? _firstAliveEnemy() {
    for (final e in state.enemies) {
      if (e.isAlive) return e;
    }
    return null;
  }
}
