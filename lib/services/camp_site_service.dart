import '_imports.dart';

class CampSiteVisitResult {
  final Battler player;
  final int healedAmount;
  final BattlerStatus? removedDebuff;

  const CampSiteVisitResult({
    required this.player,
    required this.healedAmount,
    this.removedDebuff,
  });
}

class CampSiteService {
  final double recoveryFactor;
  final bool removeRandomDebuff;

  const CampSiteService({
    this.recoveryFactor = 1,
    this.removeRandomDebuff = false,
  });

  CampSiteVisitResult recover(
    Battler player, {
    RunRandomizer? randomizer,
  }) {
    final effectiveRandomizer = randomizer ?? RunRandomizer();
    final recoveryAmount = max(1, (player.maxHealth * recoveryFactor).round());
    var updatedPlayer = player.heal(recoveryAmount);
    BattlerStatus? removedDebuff;

    if (removeRandomDebuff) {
      final debuffs = updatedPlayer.statuses
          .where((status) => status.type == BattlerStatusType.debuff)
          .toList(growable: false);

      if (debuffs.isNotEmpty) {
        final debuffIndex = effectiveRandomizer.nextInt(debuffs.length);
        removedDebuff = debuffs[debuffIndex];
        updatedPlayer = updatedPlayer.removeStatusInstance(removedDebuff);
      }
    }

    final healedAmount = updatedPlayer.health - player.health;

    return CampSiteVisitResult(
      player: updatedPlayer,
      healedAmount: healedAmount,
      removedDebuff: removedDebuff,
    );
  }
}
