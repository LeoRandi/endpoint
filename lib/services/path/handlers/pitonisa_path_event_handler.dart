part of '../path_event_service.dart';

/// Use cases owned by the Pitonisa Quitapenas event family.
extension PitonisaPathEventHandler on PathEventService {
  List<Item> buildPitonisaItemOfferings(Battler player) {
    return List<Item>.unmodifiable([
      ...player.equippedItems,
      ...player.inventoryItems,
    ]);
  }

  List<BattlerStatus> buildPitonisaPurgeableDebuffs(Battler player) {
    return List<BattlerStatus>.unmodifiable(
      player.statuses.where(
        (status) =>
            status.type == BattlerStatusType.debuff && status.isPurgeable,
      ),
    );
  }

  List<BattlerAbility> buildPitonisaCooldownAbilities(Battler player) {
    return List<BattlerAbility>.unmodifiable(
      player.abilities.where(
        (ability) =>
            ability.manualActivationContext != null &&
            ability.cooldownTurns > 0,
      ),
    );
  }

  int get pitonisaCooldownReductionCost => 10;

  PathEventVisitResult resolvePitonisaDebuffPurge({
    required Battler player,
  }) {
    final debuffs = buildPitonisaPurgeableDebuffs(player);
    if (debuffs.isEmpty) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'La pitonisa no encuentra penas que quitar.',
      );
    }

    var updatedPlayer = player;
    for (final debuff in debuffs) {
      updatedPlayer = updatedPlayer.removeStatusInstance(debuff);
    }

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText: 'La pitonisa elimina ${debuffs.length} debuffs activos.',
    );
  }

  PathEventVisitResult resolvePitonisaItemHealing({
    required Battler player,
    required Item selectedItem,
  }) {
    if (!_ownsItem(player, selectedItem)) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'Ese objeto ya no esta disponible como ofrenda.',
      );
    }

    final updatedPlayer = player.removeItem(selectedItem);
    return PathEventVisitResult(
      player: updatedPlayer.copyWith(health: updatedPlayer.maxHealth),
      outcomeText:
          'La pitonisa acepta ${selectedItem.displayName} y restaura toda tu vida.',
    );
  }

  PathEventVisitResult resolvePitonisaCooldownReduction({
    required Battler player,
    required BattlerAbility selectedAbility,
  }) {
    final currentAbility = player.abilityById(selectedAbility.id);
    if (currentAbility == null ||
        currentAbility.manualActivationContext == null ||
        currentAbility.cooldownTurns <= 0) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'Esa habilidad no puede reducir su recarga.',
      );
    }

    final price = pitonisaCooldownReductionCost;
    if (!player.canAfford(price)) {
      return PathEventVisitResult(
        player: player,
        outcomeText:
            'No tienes creditos suficientes para reducir la recarga de ${currentAbility.displayName}.',
      );
    }

    final nextCooldown = max(0, currentAbility.cooldownTurns - 1);
    final updatedAbility = currentAbility.copyWith(
      cooldownTurns: nextCooldown,
      remainingCooldownTurns: min(
        currentAbility.remainingCooldownTurns,
        nextCooldown,
      ),
    );

    return PathEventVisitResult(
      player: player.spendMoney(price).updateAbility(updatedAbility),
      outcomeText:
          'Pagas ${price}C. ${currentAbility.displayName} reduce su cooldown permanente a $nextCooldown turnos.',
    );
  }
}
