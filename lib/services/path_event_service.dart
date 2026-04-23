import '_imports.dart';

typedef PathEventAvailabilityResolver = bool Function(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
});

typedef PathEventVisitResolver = PathEventVisitResult Function(
  PathEventService service, {
  required EventPathNode node,
  required Battler player,
});

class PathEventDefinition {
  final PathEventAvailabilityResolver canAppear;
  final PathEventVisitResolver visit;

  const PathEventDefinition({
    required this.canAppear,
    required this.visit,
  });
}

final pathEventDefinitionById =
    Map<PathEventId, PathEventDefinition>.unmodifiable({
  PathEventId.debtCollection: PathEventDefinition(
    canAppear: _canAppearForDebtCollection,
    visit: _visitDebtCollection,
  ),
  PathEventId.shadyTechnosurgeon: PathEventDefinition(
    canAppear: _canAppearForTechnosurgeon,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.afterHoursTechnosurgeon: PathEventDefinition(
    canAppear: _canAppearForTechnosurgeon,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.blackTechnoMarket: PathEventDefinition(
    canAppear: _canAppearForBlackTechnoMarket,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.pasadizoSecreto: PathEventDefinition(
    canAppear: _canAppearForPasadizoSecreto,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.sobreKar: PathEventDefinition(
    canAppear: _canAppearForSobreKar,
    visit: _visitDefaultPathEvent,
  ),
});

class SobreKarUpgradeResolution {
  final PathEventVisitResult visitResult;
  final Item upgradedItem;
  final BattlerStatus appliedDebuff;
  final String appliedDebuffLabel;

  const SobreKarUpgradeResolution({
    required this.visitResult,
    required this.upgradedItem,
    required this.appliedDebuff,
    required this.appliedDebuffLabel,
  });
}

class PathEventService {
  const PathEventService();

  bool canAppear({
    required EventPathNode node,
    required Battler? player,
  }) {
    return _definitionFor(node.id).canAppear(
      this,
      node: node,
      player: player,
    );
  }

  PathEventVisitResult visit({
    required EventPathNode node,
    required Battler player,
  }) {
    return _definitionFor(node.id).visit(
      this,
      node: node,
      player: player,
    );
  }

  List<Item> buildSobreKarEligibleItems(Battler player) {
    final eligibleItems = [
      ...player.equippedItems,
      ...player.inventoryItems,
    ].where(_isSobreKarItemEligible).toList(growable: false);

    return List<Item>.unmodifiable(eligibleItems);
  }

  SobreKarUpgradeResolution? resolveSobreKarUpgrade({
    required Battler player,
    required Item selectedItem,
    required RunRandomizer randomizer,
  }) {
    if (!_isSobreKarItemEligible(selectedItem)) {
      return null;
    }

    final upgradedItemResolution = _upgradeOwnedItem(
      player: player,
      selectedItem: selectedItem,
    );
    if (upgradedItemResolution == null) {
      return null;
    }

    final debuffRoll = _rollSobreKarDebuff(randomizer);
    final updatedPlayer = upgradedItemResolution.updatedPlayer.applyStatus(
      debuffRoll.status,
      applyEquipmentModifiers: false,
    );
    final outcomeText =
        '${upgradedItemResolution.upgradedItem.displayName} se mejora a ${upgradedItemResolution.upgradedItem.rarity.label}. Efecto secundario: ${debuffRoll.label}.';

    return SobreKarUpgradeResolution(
      visitResult: PathEventVisitResult(
        player: updatedPlayer,
        outcomeText: outcomeText,
      ),
      upgradedItem: upgradedItemResolution.upgradedItem,
      appliedDebuff: debuffRoll.status,
      appliedDebuffLabel: debuffRoll.label,
    );
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

  List<PathNode> buildSecretPassageOffers({
    required RunRandomizer randomizer,
    int count = 5,
  }) {
    final offerPool = allPathNodes
        .where(_isPasadizoSecretoOfferCandidate)
        .toList(growable: false);
    if (count <= 0 || offerPool.isEmpty) {
      return const <PathNode>[];
    }

    return List<PathNode>.unmodifiable(
      randomizer.pickDistinct(offerPool, count),
    );
  }

  int get pasadizoSecretoDealCost => 10;

  PathEventVisitResult resolvePasadizoSecretoDeal({
    required Battler player,
    required PathNode selectedNode,
  }) {
    if (!_isPasadizoSecretoOfferCandidate(selectedNode)) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'El trato no puede cerrarse con ese nodo.',
      );
    }

    final price = pasadizoSecretoDealCost;
    if (!player.canAfford(price)) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'No tienes creditos suficientes para cerrar el trato.',
      );
    }

    final updatedPlayer = player.spendMoney(price);
    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Pagas ${price}C. En la siguiente eleccion aparecera ${selectedNode.label}.',
      guaranteedNextNode: selectedNode,
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
    final scopedPool = abilityPoolForArchetype(player.archetypeId);
    var candidates = scopedPool
        .where(
          (ability) =>
              ability.id != selectedAbility.id &&
              !ownedAbilityIds.contains(ability.id),
        )
        .toList(growable: false);

    if (candidates.isEmpty) {
      candidates = scopedPool
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

  bool _isPasadizoSecretoOfferCandidate(PathNode node) {
    if (node is ShopPathNode) {
      return true;
    }
    if (node is EventPathNode) {
      return node.id != PathEventId.pasadizoSecreto;
    }

    return false;
  }

  bool _isSobreKarItemEligible(Item item) {
    return item.canUpgrade && item.rarity != RarityTier.yellow;
  }

  _SobreKarUpgradedItemResolution? _upgradeOwnedItem({
    required Battler player,
    required Item selectedItem,
  }) {
    final equippedIndex = player.equippedItems.indexOf(selectedItem);
    if (equippedIndex >= 0) {
      final updatedEquippedItems = List<Item>.from(player.equippedItems);
      final upgradedItem = updatedEquippedItems[equippedIndex].upgraded();
      updatedEquippedItems[equippedIndex] = upgradedItem;
      return _SobreKarUpgradedItemResolution(
        updatedPlayer: player.copyWith(
          equippedItems: List<Item>.unmodifiable(updatedEquippedItems),
        ),
        upgradedItem: upgradedItem,
      );
    }

    final inventoryIndex = player.inventoryItems.indexOf(selectedItem);
    if (inventoryIndex >= 0) {
      final updatedInventoryItems = List<Item>.from(player.inventoryItems);
      final upgradedItem = updatedInventoryItems[inventoryIndex].upgraded();
      updatedInventoryItems[inventoryIndex] = upgradedItem;
      return _SobreKarUpgradedItemResolution(
        updatedPlayer: player.copyWith(
          inventoryItems: List<Item>.unmodifiable(updatedInventoryItems),
        ),
        upgradedItem: upgradedItem,
      );
    }

    return null;
  }

  _SobreKarDebuffRoll _rollSobreKarDebuff(RunRandomizer randomizer) {
    switch (randomizer.nextInt(3)) {
      case 0:
        return const _SobreKarDebuffRoll(
          status: InterferenciaStatus(remainingTurns: 10),
          label: 'Interferencia (10 turnos)',
        );
      case 1:
        return const _SobreKarDebuffRoll(
          status: IntoxicacionStatus(value: 3),
          label: 'Intoxicacion (potencia 3)',
        );
      default:
        return const _SobreKarDebuffRoll(
          status: QuemaduraStatus(remainingTurns: 6),
          label: 'Quemadura (6 turnos)',
        );
    }
  }
}

class _SobreKarUpgradedItemResolution {
  final Battler updatedPlayer;
  final Item upgradedItem;

  const _SobreKarUpgradedItemResolution({
    required this.updatedPlayer,
    required this.upgradedItem,
  });
}

class _SobreKarDebuffRoll {
  final BattlerStatus status;
  final String label;

  const _SobreKarDebuffRoll({
    required this.status,
    required this.label,
  });
}

PathEventDefinition _definitionFor(PathEventId id) {
  final definition = pathEventDefinitionById[id];
  if (definition != null) {
    return definition;
  }

  throw StateError(
      'No existe definicion registrada para el evento ${id.name}.');
}

bool _canAppearForDebtCollection(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  return player?.statusById(DeudaStatus.statusId) is DeudaStatus;
}

bool _canAppearForTechnosurgeon(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  return player?.abilities.isNotEmpty ?? false;
}

bool _canAppearForBlackTechnoMarket(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player == null) {
    return abilityPresets.isNotEmpty;
  }

  return abilityPresets.any((ability) {
    final ownedAbility = player.abilityById(ability.id);
    return ownedAbility == null || ownedAbility.canUpgrade;
  });
}

bool _canAppearForPasadizoSecreto(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  return allPathNodes.any(service._isPasadizoSecretoOfferCandidate);
}

bool _canAppearForSobreKar(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player == null) {
    return itemPresets.any(service._isSobreKarItemEligible);
  }

  return service.buildSobreKarEligibleItems(player).isNotEmpty;
}

PathEventVisitResult _visitDebtCollection(
  PathEventService service, {
  required EventPathNode node,
  required Battler player,
}) {
  return service._resolveDebtCollection(player);
}

PathEventVisitResult _visitDefaultPathEvent(
  PathEventService service, {
  required EventPathNode node,
  required Battler player,
}) {
  return PathEventVisitResult(
    player: player,
    outcomeText: node.outcomeText,
  );
}
