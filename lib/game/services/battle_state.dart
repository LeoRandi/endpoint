import '../domain/player.dart';
import '../domain/enemy.dart';
import '../domain/turn_order.dart';
import '../domain/character.dart';
import '../domain/party.dart';

enum BattleOutcome { ongoing, victory, defeat }

class BattleState {
  final PartyWrapper party;
  final List<Enemy> enemies;
  TurnOrder turnOrder;

  BattleState({required this.party, required this.enemies, required this.turnOrder});

  factory BattleState.fromParties({required Party party, required List<Enemy> enemies}) {
    final order = <Character>[...party.players, ...enemies];
    order.sort((a, b) => b.stats.speed.compareTo(a.stats.speed));
    return BattleState(
      party: PartyWrapper(party.players),
      enemies: enemies,
      turnOrder: TurnOrder(order),
    );
  }

  bool get isBattleOver => outcome != BattleOutcome.ongoing;

  BattleOutcome get outcome {
    final noAllies = !party.anyAlive;
    final noEnemies = enemies.every((e) => !e.isAlive);
    if (noAllies && !noEnemies) return BattleOutcome.defeat;
    if (noEnemies) return BattleOutcome.victory;
    return BattleOutcome.ongoing;
  }
}

class PartyWrapper {
  final List<Player> players;
  PartyWrapper(this.players);
  bool get anyAlive => players.any((p) => p.isAlive);
}
