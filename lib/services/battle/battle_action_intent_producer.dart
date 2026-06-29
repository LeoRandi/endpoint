import 'dart:math';

import '../../entities/_exports.dart';
import 'battle_action_intents.dart';

/// Builds read-only action previews without mutating combat state.
class BattleActionIntentProducer {
  const BattleActionIntentProducer();

  int combatDurabilityOf(Battler battler) {
    return max(0, battler.health) + max(0, battler.currentBarrier);
  }

  List<PlayerActionEffectIntent> playerActionEffects({
    required Battler ownerBefore,
    required Battler ownerAfter,
    required Battler opponentBefore,
    required Battler opponentAfter,
  }) {
    final intents = <PlayerActionEffectIntent>[];
    final ownerHealthGain = max(0, ownerAfter.health - ownerBefore.health);
    if (ownerHealthGain > 0) {
      intents.add(PlayerActionEffectIntent.heal(ownerHealthGain));
    }
    intents.addAll(_statusDeltaIntents(before: ownerBefore, after: ownerAfter));
    intents.addAll(
      _statusDeltaIntents(before: opponentBefore, after: opponentAfter),
    );
    return List<PlayerActionEffectIntent>.unmodifiable(intents);
  }

  List<EnemyTurnDebuffIntent> appliedDebuffs({
    required Battler before,
    required Battler after,
  }) {
    final beforeCounts = <String, int>{};
    for (final status in before.statuses) {
      if (status.type != BattlerStatusType.debuff) continue;
      final resolvedStatus = status.resolved(before);
      final key = _statusIntentKey(resolvedStatus);
      beforeCounts[key] = (beforeCounts[key] ?? 0) + 1;
    }

    final intents = <EnemyTurnDebuffIntent>[];
    for (final status in after.statuses) {
      if (status.type != BattlerStatusType.debuff) continue;
      final resolvedStatus = status.resolved(after);
      final key = _statusIntentKey(resolvedStatus);
      final previousCount = beforeCounts[key] ?? 0;
      if (previousCount > 0) {
        beforeCounts[key] = previousCount - 1;
        continue;
      }
      intents.add(
        EnemyTurnDebuffIntent(
          status: resolvedStatus,
          amountLabel: resolvedStatus.badgeLabelFor(after),
        ),
      );
    }
    return List<EnemyTurnDebuffIntent>.unmodifiable(intents);
  }

  List<PlayerActionEffectIntent> _statusDeltaIntents({
    required Battler before,
    required Battler after,
  }) {
    final beforeById = _statusIntentAmountsById(before);
    final afterById = _statusIntentAmountsById(after);
    final intents = <PlayerActionEffectIntent>[];
    for (final entry in afterById.entries) {
      final delta = entry.value - (beforeById[entry.key] ?? 0);
      if (delta <= 0) continue;
      final status = after.statusById(entry.key)?.resolved(after);
      if (status != null) {
        intents.add(PlayerActionEffectIntent.status(status, amount: delta));
      }
    }
    return intents;
  }

  Map<BattlerStatusId, int> _statusIntentAmountsById(Battler battler) {
    final amounts = <BattlerStatusId, int>{};
    for (final status in battler.statuses) {
      final resolvedStatus = status.resolved(battler);
      amounts.update(
        resolvedStatus.id,
        (value) => value + _statusIntentAmount(resolvedStatus),
        ifAbsent: () => _statusIntentAmount(resolvedStatus),
      );
    }
    return amounts;
  }

  int _statusIntentAmount(BattlerStatus status) {
    if (status.value > 0) return status.value;
    if (!status.isIndefinite && status.remainingTurns > 0) {
      return status.remainingTurns;
    }
    return 1;
  }

  String _statusIntentKey(BattlerStatus status) {
    return '${status.id.name}|${status.remainingTurns}|${status.value}';
  }
}
