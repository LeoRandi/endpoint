import '_imports.dart';

class PathEventService {
  const PathEventService();

  bool canAppear({
    required EventPathNode node,
    required Battler? player,
  }) {
    switch (node.id) {
      case PathEventId.debtCollection:
        return player?.statusById(DeudaStatus.statusId) is DeudaStatus;
      case PathEventId.shadyTechnosurgeon:
      case PathEventId.afterHoursTechnosurgeon:
        return true;
    }
  }

  PathEventVisitResult visit({
    required EventPathNode node,
    required Battler player,
  }) {
    switch (node.id) {
      case PathEventId.debtCollection:
        return _resolveDebtCollection(player);
      case PathEventId.shadyTechnosurgeon:
      case PathEventId.afterHoursTechnosurgeon:
        return PathEventVisitResult(
          player: player,
          outcomeText: node.outcomeText,
        );
    }
  }

  PathEventVisitResult _resolveDebtCollection(Battler player) {
    final debtStatus = player.statusById(DeudaStatus.statusId);
    if (debtStatus is! DeudaStatus) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'No habia deuda activa que reclamar.',
      );
    }

    final debtAmount = max(0, debtStatus.value);
    final payment = min(player.money, debtAmount);
    var updatedPlayer = player.spendMoney(payment);
    final remainingDebt = debtAmount - payment;

    if (remainingDebt <= 0) {
      updatedPlayer = updatedPlayer.removeStatusInstance(debtStatus);
      return PathEventVisitResult(
        player: updatedPlayer,
        outcomeText:
            'Has pagado ${payment}C y la deuda queda saldada. Tu income operativo vuelve a la normalidad.',
      );
    }

    updatedPlayer = updatedPlayer.receiveDamage(10).replaceStatusInstance(
          currentStatus: debtStatus,
          replacement: debtStatus.registerPayment(payment),
        );

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'No te alcanzaba para cubrir la cuota. Entregas ${payment}C, recibes 10 de dano y aun debes ${remainingDebt}C.',
    );
  }
}
