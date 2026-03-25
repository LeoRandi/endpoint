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

  CampSiteVisitResult recover(Battler player) {
    final recoveryAmount = max(1, (player.maxHealth * recoveryFactor).round());
    var updatedPlayer = player.heal(recoveryAmount);
    BattlerStatus? removedDebuff;

    if (removeRandomDebuff) {
      final debuffs = updatedPlayer.statuses
          .where((status) => status.type == BattlerStatusType.debuff)
          .toList(growable: false);

      if (debuffs.isNotEmpty) {
        removedDebuff = debuffs[Random().nextInt(debuffs.length)];
        updatedPlayer = updatedPlayer.removeStatus(removedDebuff.id);
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
