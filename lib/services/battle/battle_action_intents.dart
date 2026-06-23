import 'dart:math';

import '../../entities/_exports.dart';
import 'battle_enemy_ai_service.dart';

class EnemyTurnDebuffIntent {
  final BattlerStatus status;
  final String amountLabel;

  const EnemyTurnDebuffIntent({
    required this.status,
    required this.amountLabel,
  });
}

enum PlayerActionEffectIntentKind {
  heal,
  buff,
  debuff,
  ability,
}

class PlayerActionEffectIntent {
  final PlayerActionEffectIntentKind kind;
  final BattlerStatus? status;
  final BattlerAbility? ability;
  final int amount;

  const PlayerActionEffectIntent._({
    required this.kind,
    this.status,
    this.ability,
    this.amount = 0,
  });

  factory PlayerActionEffectIntent.heal(int amount) {
    return PlayerActionEffectIntent._(
      kind: PlayerActionEffectIntentKind.heal,
      amount: max(0, amount),
    );
  }

  factory PlayerActionEffectIntent.status(
    BattlerStatus status, {
    required int amount,
  }) {
    return PlayerActionEffectIntent._(
      kind: status.type == BattlerStatusType.buff
          ? PlayerActionEffectIntentKind.buff
          : PlayerActionEffectIntentKind.debuff,
      status: status,
      amount: max(0, amount),
    );
  }

  factory PlayerActionEffectIntent.ability(BattlerAbility ability) {
    return PlayerActionEffectIntent._(
      kind: PlayerActionEffectIntentKind.ability,
      ability: ability,
    );
  }
}

class PlayerActionIntentPreview {
  final int attackDamage;
  final int attackHitDamage;
  final int attackHitCount;
  final int blockBarrierGain;
  final List<PlayerActionEffectIntent> attackEffects;
  final List<PlayerActionEffectIntent> blockEffects;

  const PlayerActionIntentPreview({
    this.attackDamage = 0,
    this.attackHitDamage = 0,
    this.attackHitCount = 1,
    this.blockBarrierGain = 0,
    this.attackEffects = const <PlayerActionEffectIntent>[],
    this.blockEffects = const <PlayerActionEffectIntent>[],
  });

  String get attackDamageLabel {
    final resolvedHitCount = max(1, attackHitCount);
    if (resolvedHitCount > 1 && attackHitDamage > 0) {
      return '${max(0, attackHitDamage)}x$resolvedHitCount';
    }
    return '${max(0, attackDamage)}';
  }
}

class EnemyTurnIntentPreview {
  final EnemyTurnAction action;
  final BattlerAbility? activatedBattleAbility;
  final int damage;
  final int attackHitDamage;
  final int attackHitCount;
  final int barrierGain;
  final List<EnemyTurnDebuffIntent> appliedDebuffs;

  const EnemyTurnIntentPreview({
    this.action = EnemyTurnAction.attack,
    this.activatedBattleAbility,
    this.damage = 0,
    this.attackHitDamage = 0,
    this.attackHitCount = 1,
    this.barrierGain = 0,
    this.appliedDebuffs = const <EnemyTurnDebuffIntent>[],
  });

  String get damageLabel {
    final resolvedDamage =
        max(0, attackHitDamage > 0 ? attackHitDamage : damage);
    final resolvedHitCount = max(1, attackHitCount);
    if (resolvedHitCount <= 1) return '$resolvedDamage';
    return '${resolvedDamage}x$resolvedHitCount';
  }

  bool get hasAnyEffect {
    return activatedBattleAbility != null ||
        damage > 0 ||
        barrierGain > 0 ||
        appliedDebuffs.isNotEmpty;
  }
}
