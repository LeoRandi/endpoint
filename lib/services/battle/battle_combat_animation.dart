import '../../entities/_exports.dart';

enum BattleCombatantSide {
  player,
  enemy,
}

enum BattleCombatAnimationHook {
  attackMotion,
  blockMotion,
  simultaneousMotions,
  actionBuff,
  desafioWarning,
  burnDamage,
  poisonDamage,
  damageTaken,
  healthLoss,
  healthGain,
  barrierGain,
  barrierLoss,
  fragilidadBurst,
  moneyChange,
  purgeDamage,
}

class BattleCombatMotionCue {
  final BattleCombatAnimationHook hook;
  final BattleCombatantSide primarySide;
  final BattleCombatantSide? secondarySide;
  final BattleCombatMotionAsset motionAsset;
  final int effectCount;

  const BattleCombatMotionCue({
    required this.hook,
    required this.primarySide,
    this.secondarySide,
    this.motionAsset = BattleCombatMotionAsset.sword,
    this.effectCount = 1,
  });
}

enum BattleCombatMotionAsset {
  sword,
  shield,
  fist,
  health,
}

enum BattleCombatFloatingNumberTone {
  healthDamage,
  barrierDamage,
  burnDamage,
  poisonDamage,
  healing,
  barrierGain,
  fragilidadDamage,
  moneyGain,
  moneyLoss,
  purgeDamage,
}

class BattleCombatFloatingNumberCue {
  final BattleCombatFloatingNumberTone tone;
  final int amount;

  const BattleCombatFloatingNumberCue({
    required this.tone,
    required this.amount,
  }) : assert(amount > 0);
}

class BattleCombatAnimationCue {
  final BattleCombatAnimationHook hook;
  final BattleCombatantSide primarySide;
  final BattleCombatantSide? secondarySide;
  final Battler playerBefore;
  final Battler enemyBefore;
  final Battler playerAfter;
  final Battler enemyAfter;
  final int effectCount;
  final BattleCombatMotionAsset motionAsset;
  final List<BattleCombatMotionCue> simultaneousMotions;
  final List<BattleCombatFloatingNumberCue> floatingNumbers;
  final Map<BattleCombatantSide, List<BattleCombatFloatingNumberCue>>
      floatingNumbersBySide;

  const BattleCombatAnimationCue({
    required this.hook,
    required this.primarySide,
    this.secondarySide,
    required this.playerBefore,
    required this.enemyBefore,
    required this.playerAfter,
    required this.enemyAfter,
    this.effectCount = 1,
    this.motionAsset = BattleCombatMotionAsset.sword,
    this.simultaneousMotions = const <BattleCombatMotionCue>[],
    this.floatingNumbers = const <BattleCombatFloatingNumberCue>[],
    this.floatingNumbersBySide =
        const <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{},
  });
}

typedef BattleCombatAnimationCallback = Future<void> Function(
  BattleCombatAnimationCue cue,
);
