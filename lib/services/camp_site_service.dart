import '_imports.dart';

class CampSiteVisitResult {
  final Battler player;
  final int healedAmount;

  const CampSiteVisitResult({
    required this.player,
    required this.healedAmount,
  });
}

class CampSiteService {
  final double recoveryFactor;

  const CampSiteService({
    this.recoveryFactor = 0.5,
  });

  CampSiteVisitResult recover(Battler player) {
    final recoveryAmount = (player.maxHealth * recoveryFactor).ceil();
    final healedPlayer = player.heal(recoveryAmount);
    final healedAmount = healedPlayer.health - player.health;

    return CampSiteVisitResult(
      player: healedPlayer,
      healedAmount: healedAmount,
    );
  }
}
