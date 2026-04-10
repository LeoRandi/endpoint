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
        return player?.abilities.isNotEmpty ?? false;
      case PathEventId.blackTechnoMarket:
        if (player == null) return abilityPresets.isNotEmpty;

        return abilityPresets.any((ability) {
          final ownedAbility = player.abilityById(ability.id);
          return ownedAbility == null || ownedAbility.canUpgrade;
        });
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
      case PathEventId.blackTechnoMarket:
        return PathEventVisitResult(
          player: player,
          outcomeText: node.outcomeText,
        );
    }
  }

  PathEventVisitResult resolveTechnosurgeonMutation({
    required EventPathNode node,
    required Battler player,
    required BattlerAbility selectedAbility,
    required RunRandomizer randomizer,
  }) {
    final replacementAbility = _rollTechnosurgeonReplacement(
      node: node,
      selectedAbility: selectedAbility,
      player: player,
      randomizer: randomizer,
    );
    final updatedPlayer = player.replaceAbility(
      currentAbility: selectedAbility,
      replacementAbility: replacementAbility,
    );

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          '${selectedAbility.displayName} ha sido reemplazada por ${replacementAbility.displayName}.',
      gainedAbility: replacementAbility,
    );
  }

  List<BattlerAbility> buildBlackTechnoMarketOffers({
    required Battler player,
    required RunRandomizer randomizer,
    int count = 3,
  }) {
    final eligiblePresets = abilityPresets.where((ability) {
      final ownedAbility = player.abilityById(ability.id);
      return ownedAbility == null || ownedAbility.canUpgrade;
    }).toList(growable: false);
    if (count <= 0 || eligiblePresets.isEmpty) {
      return const <BattlerAbility>[];
    }

    final selectedPresets = randomizer.pickDistinct(eligiblePresets, count);
    return List<BattlerAbility>.unmodifiable(
      selectedPresets.map(
        (preset) => _rollBlackTechnoMarketOffer(
          preset: preset,
          player: player,
          randomizer: randomizer,
        ),
      ),
    );
  }

  int blackTechnoMarketPriceFor(BattlerAbility ability) {
    return max(0, ability.rarity.factor * 5);
  }

  PathEventVisitResult resolveBlackTechnoMarketPurchase({
    required Battler player,
    required BattlerAbility selectedAbility,
  }) {
    final price = blackTechnoMarketPriceFor(selectedAbility);
    if (!player.canAfford(price)) {
      return PathEventVisitResult(
        player: player,
        outcomeText:
            'No tienes creditos suficientes para comprar ${selectedAbility.displayName}.',
      );
    }

    final existingAbility = player.abilityById(selectedAbility.id);
    if (existingAbility != null && !existingAbility.canUpgrade) {
      return PathEventVisitResult(
        player: player,
        outcomeText:
            '${existingAbility.displayName} no puede mejorar mas ahora mismo.',
      );
    }

    final updatedPlayer =
        player.spendMoney(price).addAbility(selectedAbility.resetState());
    final resolvedAbility =
        updatedPlayer.abilityById(selectedAbility.id) ?? selectedAbility;
    final outcomeText = existingAbility == null
        ? 'Has comprado ${resolvedAbility.displayName} por ${price}C.'
        : 'Has comprado una copia de ${resolvedAbility.displayName} por ${price}C. Su tier actual es ${resolvedAbility.rarity.label}.';

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText: outcomeText,
      gainedAbility: resolvedAbility,
    );
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

  BattlerAbility _rollTechnosurgeonReplacement({
    required EventPathNode node,
    required BattlerAbility selectedAbility,
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    final ownedAbilityIds = player.abilities
        .where((ability) => ability.id != selectedAbility.id)
        .map((ability) => ability.id)
        .toSet();
    var candidates = abilityPresets
        .where(
          (ability) =>
              ability.id != selectedAbility.id &&
              !ownedAbilityIds.contains(ability.id),
        )
        .toList(growable: false);

    if (candidates.isEmpty) {
      candidates = abilityPresets
          .where((ability) => ability.id != selectedAbility.id)
          .toList(growable: false);
    }
    if (candidates.isEmpty) {
      candidates = abilityPresets;
    }

    final rolledAbility = candidates[randomizer.nextInt(candidates.length)];
    return _promoteAbilityToAtLeast(
      rolledAbility,
      _technosurgeonTargetRarity(
        node: node,
        selectedAbility: selectedAbility,
      ),
    ).resetState();
  }

  BattlerAbility _rollBlackTechnoMarketOffer({
    required BattlerAbility preset,
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    final ownedAbility = player.abilityById(preset.id);
    if (ownedAbility != null) {
      return ownedAbility.resetState();
    }

    final targetRarity = _rollWeightedRarity(
      minimumRarity: preset.rarity,
      randomizer: randomizer,
    );
    return _promoteAbilityToAtLeast(preset, targetRarity).resetState();
  }

  RarityTier _rollWeightedRarity({
    required RarityTier minimumRarity,
    required RunRandomizer randomizer,
  }) {
    final allowedTiers = RarityTier.values
        .where((tier) => tier.index >= minimumRarity.index)
        .toList(growable: false);
    final totalWeight = allowedTiers.fold<double>(
      0,
      (sum, tier) => sum + tier.rollWeight,
    );
    if (totalWeight <= 0) {
      return allowedTiers[randomizer.nextInt(allowedTiers.length)];
    }

    var roll = randomizer.nextDouble() * totalWeight;
    for (final tier in allowedTiers) {
      roll -= tier.rollWeight;
      if (roll <= 0) return tier;
    }

    return allowedTiers.last;
  }

  RarityTier _technosurgeonTargetRarity({
    required EventPathNode node,
    required BattlerAbility selectedAbility,
  }) {
    final nextTier = selectedAbility.rarity.nextTier;
    if (node.id != PathEventId.afterHoursTechnosurgeon ||
        nextTier.index >= RarityTier.purple.index) {
      return nextTier;
    }

    return RarityTier.purple;
  }

  BattlerAbility _promoteAbilityToAtLeast(
    BattlerAbility ability,
    RarityTier targetRarity,
  ) {
    var promotedAbility = ability;
    while (promotedAbility.rarity.index < targetRarity.index &&
        promotedAbility.canUpgrade) {
      promotedAbility = promotedAbility.upgraded();
    }
    if (promotedAbility.rarity.index >= targetRarity.index) {
      return promotedAbility;
    }

    return promotedAbility.copyWith(rarity: targetRarity);
  }
}
