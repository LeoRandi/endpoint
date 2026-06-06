import 'dart:math';

import '../../entities/_exports.dart';
import '../runtime/battler_runtime_service.dart';
import 'battle_turn_engine.dart';

class BattlePurgeConfig {
  final int startRound;
  final int? fixedDamageUntilRound10;

  const BattlePurgeConfig({
    required this.startRound,
    this.fixedDamageUntilRound10,
  });

  int get warningRound => max(1, startRound - 2);
}

/// Centralizes Purge timing and damage rules for previews and end-of-round
/// resolution.
class BattlePurgeService {
  static const int normalStartRound = 5;
  static const int _rampRoundCount = 5;
  static const int _initialDamage = 1;
  static const int _initialDamagePerRound = 1;
  static const int _lateDamagePerRound = 2;

  const BattlePurgeService();

  BattlePurgeConfig configFor(PurgeDoctrine? doctrine) {
    switch (doctrine) {
      case PurgeDoctrine.embrace:
        return const BattlePurgeConfig(
          startRound: 3,
          fixedDamageUntilRound10: 6,
        );
      case PurgeDoctrine.wayOut:
        return const BattlePurgeConfig(
          startRound: 7,
          fixedDamageUntilRound10: 4,
        );
      case null:
        return const BattlePurgeConfig(startRound: normalStartRound);
    }
  }

  int damageForRound({
    required int round,
    required PurgeDoctrine? doctrine,
  }) {
    final config = configFor(doctrine);
    if (round < config.startRound) {
      return 0;
    }
    if (config.fixedDamageUntilRound10 != null && round < 10) {
      return config.fixedDamageUntilRound10!;
    }

    return _normalDamageForRound(round);
  }

  int damageForBattler({
    required Battler battler,
    required int round,
    required PurgeDoctrine? doctrine,
  }) {
    final purgeDamage = damageForRound(
      round: round,
      doctrine: doctrine,
    );
    if (battler.isDefeated || purgeDamage <= 0) {
      return 0;
    }

    return purgeDamage;
  }

  BattleTurnResolution applyDamage({
    required Battler player,
    required Battler enemy,
    required int round,
    required PurgeDoctrine? doctrine,
  }) {
    final playerDamage = damageForBattler(
      battler: player,
      round: round,
      doctrine: doctrine,
    );
    final enemyDamage = damageForBattler(
      battler: enemy,
      round: round,
      doctrine: doctrine,
    );

    return BattleTurnResolution(
      player: playerDamage > 0 ? player.receiveDamage(playerDamage) : player,
      enemy: enemyDamage > 0 ? enemy.receiveDamage(enemyDamage) : enemy,
    );
  }

  int _normalDamageForRound(int round) {
    if (round < normalStartRound) {
      return 0;
    }
    final purgeCount = round - normalStartRound + 1;
    if (purgeCount <= _rampRoundCount) {
      return _initialDamage + ((purgeCount - 1) * _initialDamagePerRound);
    }

    const rampEndDamage =
        _initialDamage + ((_rampRoundCount - 1) * _initialDamagePerRound);
    return rampEndDamage +
        ((purgeCount - _rampRoundCount) * _lateDamagePerRound);
  }
}
