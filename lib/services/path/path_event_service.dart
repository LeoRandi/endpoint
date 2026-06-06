import '../_imports.dart';

typedef PathEventAvailabilityResolver = bool Function(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
});

typedef PathEventVisitResolver = PathEventVisitResult Function(
  PathEventService service, {
  required EventPathNode node,
  required Battler player,
  required RunRandomizer randomizer,
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
  PathEventId.strandedTrash: const PathEventDefinition(
    canAppear: _canAppearForArchetypeItemReward,
    visit: _visitArchetypeItemReward,
  ),
  PathEventId.lostCache: const PathEventDefinition(
    canAppear: _canAppearForArchetypeItemReward,
    visit: _visitArchetypeItemReward,
  ),
  PathEventId.debtCollection: const PathEventDefinition(
    canAppear: _canAppearForDebtCollection,
    visit: _visitDebtCollection,
  ),
  PathEventId.shadyTechnosurgeon: const PathEventDefinition(
    canAppear: _canAppearForTechnosurgeon,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.afterHoursTechnosurgeon: const PathEventDefinition(
    canAppear: _canAppearForTechnosurgeon,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.blackTechnoMarket: const PathEventDefinition(
    canAppear: _canAppearForBlackTechnoMarket,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.pasadizoSecreto: const PathEventDefinition(
    canAppear: _canAppearForPasadizoSecreto,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.sobreKar: const PathEventDefinition(
    canAppear: _canAppearForSobreKar,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.suBastaYa: const PathEventDefinition(
    canAppear: _canAppearForSuBastaYa,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.pitonisaQuitapenas: const PathEventDefinition(
    canAppear: _canAppearForPitonisaQuitapenas,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.clinicaReflejos: const PathEventDefinition(
    canAppear: _canAppearForVeloz,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.viktorOperations: const PathEventDefinition(
    canAppear: _canAppearForViktorOperations,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.arquitecbrosSl: const PathEventDefinition(
    canAppear: _canAppearForInamovible,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.barreraLibre: const PathEventDefinition(
    canAppear: _canAppearForBarreraLibre,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.capillaStShieladurn: const PathEventDefinition(
    canAppear: _canAppearForCapillaStShieladurn,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.contratontos: const PathEventDefinition(
    canAppear: _canAppearForImparable,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.hornoJuramentos: const PathEventDefinition(
    canAppear: _canAppearForHornoJuramentos,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.auditoriaCreativa: const PathEventDefinition(
    canAppear: _canAppearForMercante,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.mercadoFuturos: const PathEventDefinition(
    canAppear: _canAppearForMercante,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.thePurgame: const PathEventDefinition(
    canAppear: _canAppearForThePurgame,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.tempografo: const PathEventDefinition(
    canAppear: _canAppearAlways,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.sWitchCabin: const PathEventDefinition(
    canAppear: _canAppearForSWitchCabin,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.hackathonBooth: const PathEventDefinition(
    canAppear: _canAppearAlways,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.tintoreriaFantasma: const PathEventDefinition(
    canAppear: _canAppearForTintoreriaFantasma,
    visit: _visitDefaultPathEvent,
  ),
});

enum SuBastaYaStatReward {
  health,
  attack,
  barrier,
}

extension SuBastaYaStatRewardPresentation on SuBastaYaStatReward {
  BattlerStat get stat {
    switch (this) {
      case SuBastaYaStatReward.health:
        return BattlerStat.health;
      case SuBastaYaStatReward.attack:
        return BattlerStat.attack;
      case SuBastaYaStatReward.barrier:
        return BattlerStat.barrier;
    }
  }

  String get label {
    switch (this) {
      case SuBastaYaStatReward.health:
        return 'HP';
      case SuBastaYaStatReward.attack:
        return 'ATK';
      case SuBastaYaStatReward.barrier:
        return 'Barrera';
    }
  }
}

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
  final CatalogRuntimeService _runtimeService;

  const PathEventService({
    CatalogRuntimeService runtimeService = const CatalogRuntimeService(),
  }) : _runtimeService = runtimeService;

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
    required RunRandomizer randomizer,
  }) {
    return _definitionFor(node.id).visit(
      this,
      node: node,
      player: player,
      randomizer: randomizer,
    );
  }

  List<Item> buildArchetypeItemRewardPool({
    required Battler player,
    required RarityTier rarity,
  }) {
    final scopedPool = itemPoolForArchetype(player.archetypeId)
        .where((item) => item.rarity == rarity)
        .toList(growable: false);
    if (scopedPool.isNotEmpty) {
      return List<Item>.unmodifiable(scopedPool);
    }

    return List<Item>.unmodifiable(
      itemPresets.where((item) => item.rarity == rarity),
    );
  }

  PathEventVisitResult resolveArchetypeItemReward({
    required EventPathNode node,
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    final rewardPool = buildArchetypeItemRewardPool(
      player: player,
      rarity: node.rarity,
    );
    if (rewardPool.isEmpty) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'No quedaban objetos compatibles en el hallazgo.',
      );
    }

    final rewardItem = rewardPool[randomizer.nextInt(rewardPool.length)];
    final updatedPlayer = player.addItem(rewardItem);
    final resolvedItem = updatedPlayer.inventoryItemOfType(rewardItem.id) ??
        updatedPlayer.equippedItemOfType(rewardItem.id) ??
        rewardItem;
    final actionLabel =
        player.wouldUpgradeItem(rewardItem) ? 'mejora' : 'recibes';

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Del hallazgo $actionLabel ${resolvedItem.displayName} (${resolvedItem.rarity.label}).',
      gainedItem: resolvedItem,
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

    final updatedPlayer = player
        .spendMoney(price)
        .addAbility(_runtimeService.runtimeAbility(selectedAbility));
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

  List<Item> buildSuBastaYaEligibleItems(Battler player) {
    return List<Item>.unmodifiable([
      ...player.equippedItems,
      ...player.inventoryItems,
    ]);
  }

  List<BattlerAbility> buildSuBastaYaEligibleAbilities(Battler player) {
    return List<BattlerAbility>.unmodifiable(player.abilities);
  }

  int suBastaYaAuctionPriceFor(Item item) {
    return max(item.cost, item.sellValue * 3);
  }

  Map<BattlerStat, int> suBastaYaStatRewardFor({
    required Item item,
    required SuBastaYaStatReward selectedReward,
  }) {
    if (item.rarity == RarityTier.yellow) {
      return const <BattlerStat, int>{
        BattlerStat.health: 15,
        BattlerStat.attack: 3,
        BattlerStat.barrier: 3,
      };
    }

    final factor = max(1, item.rarity.factor);
    return <BattlerStat, int>{
      selectedReward.stat:
          selectedReward == SuBastaYaStatReward.health ? 5 * factor : factor,
    };
  }

  PathEventVisitResult resolveSuBastaYaAuctionSale({
    required Battler player,
    required Item selectedItem,
  }) {
    if (!_ownsItem(player, selectedItem)) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'Ese objeto ya no esta disponible para subasta.',
      );
    }

    final payout = suBastaYaAuctionPriceFor(selectedItem);
    final updatedPlayer = player.removeItem(selectedItem).earnMoney(payout);
    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText: 'Subastas ${selectedItem.displayName} y cobras ${payout}C.',
    );
  }

  PathEventVisitResult resolveSuBastaYaStatSacrifice({
    required Battler player,
    required Item selectedItem,
    required SuBastaYaStatReward selectedReward,
  }) {
    if (!_ownsItem(player, selectedItem)) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'Ese objeto ya no esta disponible para reciclar.',
      );
    }

    final statRewards = suBastaYaStatRewardFor(
      item: selectedItem,
      selectedReward: selectedReward,
    );
    final updatedPlayer = _applyPermanentStatRewards(
      player.removeItem(selectedItem),
      statRewards,
    );
    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Entregas ${selectedItem.displayName}. Recibes ${_statRewardSummary(statRewards)} permanente.',
    );
  }

  PathEventVisitResult resolveSuBastaYaAbilitySwap({
    required Battler player,
    required BattlerAbility selectedAbility,
    required RunRandomizer randomizer,
  }) {
    if (player.abilityById(selectedAbility.id) == null) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'Esa habilidad ya no esta disponible para intercambiar.',
      );
    }

    final replacementAbility = _rollSuBastaYaReplacementAbility(
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
          'Cambias ${selectedAbility.displayName} por ${replacementAbility.displayName}.',
      gainedAbility: replacementAbility,
    );
  }

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

  List<Item> buildOwnedItems(Battler player) {
    return List<Item>.unmodifiable([
      ...player.equippedItems,
      ...player.inventoryItems,
    ]);
  }

  PathEventVisitResult resolveTempografoChoice({
    required Battler player,
    required bool preferShops,
  }) {
    return PathEventVisitResult(
      player: player,
      outcomeText: preferShops
          ? 'El Tempografo adelanta las tiendas y retrasa los eventos hasta que termine el dia.'
          : 'El Tempografo adelanta los eventos y retrasa las tiendas hasta que termine el dia.',
      nextShopRarityDayOffset: preferShops ? 1 : -1,
      nextEventRarityDayOffset: preferShops ? -1 : 1,
    );
  }

  List<Item> buildSWitchCabinEligibleItems(Battler player) {
    return List<Item>.unmodifiable(
      buildOwnedItems(player).where((item) => item.hasPatternBonus),
    );
  }

  PathEventVisitResult resolveSWitchPatternSwap({
    required Battler player,
    required Item firstItem,
    required Item secondItem,
  }) {
    if (firstItem == secondItem ||
        !_ownsItem(player, firstItem) ||
        !_ownsItem(player, secondItem) ||
        !firstItem.hasPatternBonus ||
        !secondItem.hasPatternBonus) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'La cabina no encuentra dos patrones compatibles.',
      );
    }

    final updatedFirst = firstItem.copyWith(
      patternBonusKindOverride: secondItem.patternBonusKind,
      patternBonusAmountOverride: secondItem.patternBonusAmount,
      patternRequirementOverride: secondItem.patternRequirement,
    );
    final updatedSecond = secondItem.copyWith(
      patternBonusKindOverride: firstItem.patternBonusKind,
      patternBonusAmountOverride: firstItem.patternBonusAmount,
      patternRequirementOverride: firstItem.patternRequirement,
    );
    final updatedPlayer = _replaceOwnedItems(
      player: player,
      replacements: {
        firstItem: updatedFirst,
        secondItem: updatedSecond,
      },
    );

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          '${firstItem.displayName} y ${secondItem.displayName} intercambian sus bonus de Patron.',
    );
  }

  PathEventVisitResult resolveHackathonReward({
    required Battler player,
    required int score,
    required RunRandomizer randomizer,
  }) {
    final cappedScore = score.clamp(0, 6).toInt();
    if (cappedScore <= 1) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'Los cyber-nerds aplauden con educacion. No hay premio.',
      );
    }

    if (cappedScore <= 3) {
      final ability = _rollRewardAbility(
        player: player,
        rarity: RarityTier.green,
        randomizer: randomizer,
      );
      if (ability == null) {
        return PathEventVisitResult(
          player: player,
          outcomeText: 'El puesto no encuentra un aumento verde compatible.',
        );
      }
      final updatedPlayer =
          player.addAbility(_runtimeService.runtimeAbility(ability));
      return PathEventVisitResult(
        player: updatedPlayer,
        outcomeText: 'Recibes un aumento verde: ${ability.displayName}.',
        gainedAbility: updatedPlayer.abilityById(ability.id) ?? ability,
      );
    }

    if (cappedScore <= 5) {
      final ability = _rollRewardAbility(
        player: player,
        rarity: RarityTier.blue,
        randomizer: randomizer,
      );
      final item = _rollRewardItem(
        rarity: RarityTier.green,
        randomizer: randomizer,
      );
      var updatedPlayer = player;
      if (ability != null) {
        updatedPlayer =
            updatedPlayer.addAbility(_runtimeService.runtimeAbility(ability));
      }
      if (item != null) {
        updatedPlayer = updatedPlayer.addItem(item);
      }
      return PathEventVisitResult(
        player: updatedPlayer,
        outcomeText:
            'Recibes ${ability?.displayName ?? 'sin aumento'} y ${item?.displayName ?? 'sin objeto'}.',
        gainedAbility:
            ability == null ? null : updatedPlayer.abilityById(ability.id),
        gainedItem: item == null
            ? null
            : updatedPlayer.inventoryItemOfType(item.id) ??
                updatedPlayer.equippedItemOfType(item.id) ??
                item,
      );
    }

    final ability = _rollRewardAbility(
      player: player,
      rarity: RarityTier.yellow,
      randomizer: randomizer,
    );
    final item = _rollRewardItem(
      rarity: RarityTier.blue,
      randomizer: randomizer,
    );
    var updatedPlayer = player;
    if (ability != null) {
      updatedPlayer =
          updatedPlayer.addAbility(_runtimeService.runtimeAbility(ability));
    }
    if (item != null) {
      updatedPlayer = updatedPlayer.addItem(item);
    }
    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Reclamas el premio completo: ${ability?.displayName ?? 'sin aumento'} y ${item?.displayName ?? 'sin objeto'}.',
      gainedAbility:
          ability == null ? null : updatedPlayer.abilityById(ability.id),
      gainedItem: item == null
          ? null
          : updatedPlayer.inventoryItemOfType(item.id) ??
              updatedPlayer.equippedItemOfType(item.id) ??
              item,
    );
  }

  List<Item> buildTintoreriaFantasmaOffers({
    required Battler player,
    required RunRandomizer randomizer,
    required int dayNumber,
    int count = 3,
  }) {
    if (count <= 0) return const <Item>[];

    final pool = itemPoolForArchetype(player.archetypeId);
    if (pool.isEmpty) return const <Item>[];

    final targetRarity = _rollEventItemRarityForDay(
      randomizer: randomizer,
      dayNumber: dayNumber + 1,
    );
    final selectedItems = <Item>[];
    final selectedItemIds = <ItemId>{};
    for (final rarity in _rarityFallbacksFrom(targetRarity)) {
      final candidates = pool
          .where(
            (item) =>
                item.rarity == rarity && !selectedItemIds.contains(item.id),
          )
          .toList(growable: false);
      if (candidates.isEmpty) continue;

      final pickedItems = randomizer.pickDistinct(
        candidates,
        min(count - selectedItems.length, candidates.length),
      );
      selectedItems.addAll(pickedItems);
      selectedItemIds.addAll(pickedItems.map((item) => item.id));
      if (selectedItems.length >= count) {
        return List<Item>.unmodifiable(
          selectedItems.take(count),
        );
      }
    }

    return List<Item>.unmodifiable(selectedItems);
  }

  int tintoreriaFantasmaPriceFor(Item item) {
    return max(item.cost, item.rarity.factor * 5);
  }

  PathEventVisitResult resolveTintoreriaFantasmaBorrow({
    required Battler player,
    required Item selectedItem,
  }) {
    if (!player.hasInventorySpace) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'No tienes espacio para llevarte una prenda prestada.',
      );
    }

    final ghostItem = _runtimeService.runtimeItem(
      selectedItem.copyWith(isGhostly: true),
      forceNewInstance: true,
    );
    final updatedPlayer = player.addItemAsNewInstance(ghostItem);
    final resolvedItem = updatedPlayer.inventoryItems.lastWhere(
      (item) => item.instanceId == ghostItem.instanceId,
      orElse: () => ghostItem,
    );

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Te llevas ${resolvedItem.displayName}. La bruma promete volver a reclamarlo tras dos combates.',
      gainedItem: resolvedItem,
      ghostItemLease: GhostItemLease(
        itemInstanceId: resolvedItem.instanceId ?? ghostItem.instanceId!,
        combatsRemaining: 2,
      ),
    );
  }

  List<Item> buildViktorOperationsEligibleItems(Battler player) {
    return List<Item>.unmodifiable(
      buildOwnedItems(player).where(
        (item) =>
            item.rarity.index < RarityTier.purple.index &&
            item.canUpgrade &&
            (item.hasTag(EntityTag.contagio) ||
                item.hasTag(EntityTag.debuff) ||
                item.hasTag(EntityTag.intoxicacion)),
      ),
    );
  }

  List<Item> buildHornoJuramentosEligibleItems(Battler player) {
    return List<Item>.unmodifiable(
      buildOwnedItems(player).where(
        (item) => item.rarity != RarityTier.yellow && item.canUpgrade,
      ),
    );
  }

  PathEventVisitResult resolveClinicaReflejosAbility({
    required Battler player,
    required RunRandomizer randomizer,
    required int dayNumber,
  }) {
    final ability = _rollAbilityForArchetypeAndDay(
      player: player,
      archetypeId: ArchetypeId.veloz,
      randomizer: randomizer,
      dayNumber: dayNumber,
    );
    if (ability == null) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'La clinica no encuentra ningun aumento Veloz compatible.',
      );
    }

    final updatedPlayer =
        player.addAbility(_runtimeService.runtimeAbility(ability));
    final resolvedAbility = updatedPlayer.abilityById(ability.id) ?? ability;
    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'La Clinica de Reflejos integra ${resolvedAbility.displayName} (${resolvedAbility.rarity.label}).',
      gainedAbility: resolvedAbility,
    );
  }

  PathEventVisitResult resolveClinicaReflejosBurnTraining(Battler player) {
    final updatedPlayer = _applyPermanentStatRewards(
      player.applyStatus(
        const QuemaduraStatus(remainingTurns: 6),
        applyEquipmentModifiers: false,
      ),
      const {BattlerStat.attack: 1},
    );
    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Aceptas la inyeccion. Ganas +1 ATK permanente y 6 Quemadura.',
    );
  }

  PathEventVisitResult? resolveViktorOperationsUpgrade({
    required Battler player,
    required Item selectedItem,
  }) {
    if (!buildViktorOperationsEligibleItems(player).contains(selectedItem)) {
      return null;
    }

    final resolution = _upgradeOwnedItemToRarity(
      player: player,
      selectedItem: selectedItem,
      targetRarity: RarityTier.purple,
    );
    if (resolution == null) return null;

    return PathEventVisitResult(
      player: resolution.updatedPlayer,
      outcomeText:
          'Viktor deja ${resolution.upgradedItem.displayName} en MORADO, limpio como un quirofano imposible.',
      gainedItem: resolution.upgradedItem,
    );
  }

  PathEventVisitResult resolveArquitecbrosWall({
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    final wallSeed = player.seedRandomCombatWalls(
      count: 1,
      nextInt: randomizer.nextInt,
    );
    final updatedPlayer = _applyPermanentStatRewards(
      player.queueTemporaryCombatWalls(wallSeed.combatWallSegments),
      {
        BattlerStat.barrier: 1,
        BattlerStat.health: max(1, (player.maxHealth * 0.10).ceil()),
      },
    );
    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Arquitecbros SL deja una muralla preparada para el proximo combate. Ganas +1 Barrera y +10% HP permanente.',
    );
  }

  CombatPathNode buildArquitecbrosBrotherCombatNode({
    required RunRandomizer randomizer,
  }) {
    final node =
        purpleCombatNodes[randomizer.nextInt(purpleCombatNodes.length)];
    final enemy = node.enemy;
    final updatedStats = Map<BattlerStat, int>.from(enemy.baseStats);
    updatedStats[BattlerStat.barrier] =
        max(0, (updatedStats[BattlerStat.barrier] ?? 0) + 3);

    return CombatPathNode(
      nodeId: '${node.nodeId}_arquitecbros_third',
      enemy: enemy.copyWith(
        name: 'TERCER ${enemy.name}',
        baseStats: Map<BattlerStat, int>.unmodifiable(updatedStats),
      ),
      tier: CombatNodeTier.purple,
      label: 'TERCER ${node.label}',
    );
  }

  PathEventVisitResult resolveBarreraLibre({
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    if (player.reinforcedPatternPointKey != null) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'Tu Patron ya tenia un punto reforzado.',
      );
    }

    final point = _barreraLibrePointCandidates[
        randomizer.nextInt(_barreraLibrePointCandidates.length)];
    final updatedPlayer = player.copyWith(
      reinforcedPatternPointKey: point.key,
    );

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Refuerzas el punto ${point.label}. Cada Muralla colocada junto a el te dara +1 Barrera.',
    );
  }

  static const List<OperativePatternPoint> _barreraLibrePointCandidates =
      <OperativePatternPoint>[
    OperativePatternPoint(x: 0, y: 1),
    OperativePatternPoint(x: 0, y: -1),
    OperativePatternPoint(x: 1, y: 0),
    OperativePatternPoint(x: -1, y: 0),
  ];

  PathEventVisitResult resolveCapillaOffering({
    required Battler player,
    required Item selectedItem,
    required RunRandomizer randomizer,
  }) {
    if (!player.ownsItem(selectedItem)) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'La ofrenda ya no esta disponible.',
      );
    }

    final barrierGain = selectedItem.isWeaponLike ? 2 : 1;
    var updatedPlayer = _applyPermanentStatRewards(
      player.removeItem(selectedItem),
      {BattlerStat.barrier: barrierGain},
    );
    BattlerAbility? gainedAbility;
    if (selectedItem.isWeaponLike) {
      gainedAbility = _rollAbilityFromPoolForExactRarity(
        pool: abilityPresets,
        player: updatedPlayer,
        targetRarity: RarityTier.green,
        randomizer: randomizer,
      );
      if (gainedAbility != null) {
        updatedPlayer = updatedPlayer.addAbility(
          _runtimeService.runtimeAbility(gainedAbility),
        );
        gainedAbility = updatedPlayer.abilityById(gainedAbility.id);
      }
    }

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'La Capilla acepta ${selectedItem.displayName}. Ganas +$barrierGain Barrera permanente.',
      gainedAbility: gainedAbility,
    );
  }

  PathEventVisitResult resolveContratontosLight(Battler player) {
    return PathEventVisitResult(
      player: player
          .applyStatus(
            const QuemaduraStatus(remainingTurns: 4),
            applyEquipmentModifiers: false,
          )
          .gainExperience(1),
      outcomeText: 'Aceptas el entrenamiento suave: 4 Quemadura y +1 XP.',
    );
  }

  PathEventVisitResult resolveContratontosBlueAugment({
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    final ability = _rollAbilityFromPoolForExactRarity(
      pool: abilityPoolForArchetype(ArchetypeId.imparable),
      player: player,
      targetRarity: RarityTier.blue,
      randomizer: randomizer,
    );
    var updatedPlayer = player.applyStatus(
      const QuemaduraStatus(remainingTurns: 8),
      applyEquipmentModifiers: false,
    );
    BattlerAbility? gainedAbility;
    if (ability != null) {
      updatedPlayer =
          updatedPlayer.addAbility(_runtimeService.runtimeAbility(ability));
      gainedAbility = updatedPlayer.abilityById(ability.id) ?? ability;
    }

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Aceptas el entrenamiento de holo-arena: 8 Quemadura y un aumento Imparable azul.',
      gainedAbility: gainedAbility,
    );
  }

  PathEventVisitResult resolveContratontosMaxHpLoss(Battler player) {
    return PathEventVisitResult(
      player:
          _applyPermanentMaxHealthPercentLoss(player, 0.20).gainExperience(4),
      outcomeText: 'Aceptas el entrenamiento absurdo: -20% HP maximo y +4 XP.',
    );
  }

  PathEventVisitResult? resolveHornoJuramentosUpgrade({
    required Battler player,
    required Item selectedItem,
  }) {
    if (!buildHornoJuramentosEligibleItems(player).contains(selectedItem)) {
      return null;
    }

    final resolution = _upgradeOwnedItem(
      player: player,
      selectedItem: selectedItem,
    );
    if (resolution == null) return null;

    final selfDamage = max(1, (player.health * 0.15).ceil());
    final damagedHealth = max(1, resolution.updatedPlayer.health - selfDamage);
    final updatedPlayer =
        resolution.updatedPlayer.copyWith(health: damagedHealth).applyStatus(
              const QuemaduraStatus(remainingTurns: 3),
              applyEquipmentModifiers: false,
            );

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          '${resolution.upgradedItem.displayName} sube a ${resolution.upgradedItem.rarity.label}. Sales con 3 Quemadura y el horno te deja a ${updatedPlayer.health} HP.',
      gainedItem: resolution.upgradedItem,
    );
  }

  PathEventVisitResult resolveAuditoriaCreativaCredits(Battler player) {
    return PathEventVisitResult(
      player: _applyPermanentMaxHealthPercentLoss(player, 0.15).earnMoney(20),
      outcomeText:
          'La auditora liquida una parte de tu futuro biologico. Pierdes 15% HP maximo y cobras 20C.',
    );
  }

  PathEventVisitResult resolveAuditoriaCreativaDebtAugment({
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    final ability = _rollAbilityFromPoolForExactRarity(
      pool: abilityPresets,
      player: player,
      targetRarity: RarityTier.green,
      randomizer: randomizer,
    );
    var updatedPlayer = player.applyStatus(
      const DeudaStatus(value: 20),
      applyEquipmentModifiers: false,
    );
    BattlerAbility? gainedAbility;
    if (ability != null) {
      updatedPlayer =
          updatedPlayer.addAbility(_runtimeService.runtimeAbility(ability));
      gainedAbility = updatedPlayer.abilityById(ability.id) ?? ability;
    }

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Firmas deuda operativa y recibes un aumento verde gratuito.',
      gainedAbility: gainedAbility,
    );
  }

  PathEventVisitResult resolveMercadoFuturosCoin({
    required Battler player,
    required bool didWin,
  }) {
    if (!didWin) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'La moneda cae del lado equivocado. El broker sonrie.',
      );
    }

    final updatedPlayer = player.gainExperience(2).applyStatus(
          const MercadoFuturosStatus(attack: 1, barrier: 1),
          applyEquipmentModifiers: false,
        );
    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'La moneda obedece. Ganas +2 XP y +1 ATK/+1 Barrera en el proximo combate.',
    );
  }

  PathEventVisitResult resolveThePurgameChoice({
    required Battler player,
    required PurgeDoctrine doctrine,
  }) {
    final updatedPlayer = player.copyWith(purgeDoctrine: doctrine);
    final doctrineText = switch (doctrine) {
      PurgeDoctrine.embrace =>
        'Abrazas la Purga. Llegara en la ronda 3 e infligira 6 daño por ronda hasta la ronda 10.',
      PurgeDoctrine.wayOut =>
        'Crees en una salida. La Purga llegara en la ronda 7 e infligira 4 daño por ronda hasta la ronda 10.',
    };

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText: doctrineText,
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
          'No te alcanzaba para cubrir la cuota. Entregas ${payment}C, recibes 10 de daño y aun debes ${remainingDebt}C.',
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
    return _runtimeService.promoteAbilityToAtLeastRarity(
      rolledAbility,
      _technosurgeonTargetRarity(
        node: node,
        selectedAbility: selectedAbility,
      ),
    );
  }

  BattlerAbility _rollBlackTechnoMarketOffer({
    required BattlerAbility preset,
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    final ownedAbility = player.abilityById(preset.id);
    if (ownedAbility != null) {
      return _runtimeService.runtimeAbility(ownedAbility);
    }

    final targetRarity = _rollWeightedRarity(
      minimumRarity: preset.rarity,
      randomizer: randomizer,
    );
    return _runtimeService.promoteAbilityToAtLeastRarity(preset, targetRarity);
  }

  BattlerAbility _rollSuBastaYaReplacementAbility({
    required BattlerAbility selectedAbility,
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    final ownedAbilityIds = player.abilities
        .where((ability) => ability.id != selectedAbility.id)
        .map((ability) => ability.id)
        .toSet();
    var candidates = abilityPoolForArchetype(player.archetypeId)
        .where(
          (ability) =>
              ability.id != selectedAbility.id &&
              ability.rarity.index >= selectedAbility.rarity.index &&
              !ownedAbilityIds.contains(ability.id),
        )
        .toList(growable: false);

    if (candidates.isEmpty) {
      candidates = abilityPoolForArchetype(player.archetypeId)
          .where((ability) => ability.id != selectedAbility.id)
          .toList(growable: false);
    }
    if (candidates.isEmpty) {
      candidates = abilityPresets
          .where((ability) => ability.id != selectedAbility.id)
          .toList(growable: false);
    }
    if (candidates.isEmpty) {
      return _runtimeService.runtimeAbility(selectedAbility);
    }

    final rolledAbility = candidates[randomizer.nextInt(candidates.length)];
    return _runtimeService.promoteAbilityToAtLeastRarity(
      rolledAbility,
      selectedAbility.rarity,
    );
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

  bool _ownsItem(Battler player, Item item) {
    return player.equippedItems.contains(item) ||
        player.inventoryItems.contains(item);
  }

  Battler _replaceOwnedItems({
    required Battler player,
    required Map<Item, Item> replacements,
  }) {
    if (replacements.isEmpty) return player;

    final updatedEquippedItems = player.equippedItems
        .map((item) => replacements[item] ?? item)
        .toList(growable: false);
    final updatedInventoryItems = player.inventoryItems
        .map((item) => replacements[item] ?? item)
        .toList(growable: false);

    return player.copyWith(
      equippedItems: List<Item>.unmodifiable(updatedEquippedItems),
      inventoryItems: List<Item>.unmodifiable(updatedInventoryItems),
    );
  }

  BattlerAbility? _rollRewardAbility({
    required Battler player,
    required RarityTier rarity,
    required RunRandomizer randomizer,
  }) {
    final candidatesById = <BattlerAbilityId, BattlerAbility>{};
    for (final ability in abilityPresets) {
      final ownedAbility = player.abilityById(ability.id);
      if (ownedAbility != null) {
        if (ownedAbility.rarity == rarity && ownedAbility.canUpgrade) {
          candidatesById.putIfAbsent(
            ability.id,
            () => _runtimeService.runtimeAbility(ownedAbility),
          );
        }
        continue;
      }

      final promotedAbility =
          _runtimeService.promoteAbilityToExactRarity(ability, rarity);
      if (promotedAbility == null) continue;
      candidatesById.putIfAbsent(ability.id, () => promotedAbility);
    }

    final candidates = candidatesById.values.toList(growable: false);
    if (candidates.isEmpty) return null;
    return _runtimeService.runtimeAbility(
      candidates[randomizer.nextInt(candidates.length)],
    );
  }

  Item? _rollRewardItem({
    required RarityTier rarity,
    required RunRandomizer randomizer,
  }) {
    final candidates = itemPresets
        .where((item) => item.rarity == rarity)
        .toList(growable: false);
    if (candidates.isEmpty) return null;

    return candidates[randomizer.nextInt(candidates.length)];
  }

  Battler _applyPermanentStatRewards(
    Battler player,
    Map<BattlerStat, int> rewards,
  ) {
    if (rewards.isEmpty) return player;

    final updatedBaseStats = Map<BattlerStat, int>.from(player.baseStats);
    for (final entry in rewards.entries) {
      updatedBaseStats[entry.key] =
          max(0, (updatedBaseStats[entry.key] ?? 0) + entry.value);
    }

    final healthGain = rewards[BattlerStat.health] ?? 0;
    return player.copyWith(
      health: player.health + healthGain,
      baseStats: Map<BattlerStat, int>.unmodifiable(updatedBaseStats),
    );
  }

  String _statRewardSummary(Map<BattlerStat, int> rewards) {
    final entries = <String>[];
    final healthGain = rewards[BattlerStat.health] ?? 0;
    if (healthGain > 0) entries.add('+$healthGain HP');
    final attackGain = rewards[BattlerStat.attack] ?? 0;
    if (attackGain > 0) entries.add('+$attackGain ATK');
    final barrierGain = rewards[BattlerStat.barrier] ?? 0;
    if (barrierGain > 0) entries.add('+$barrierGain Barrera');

    return entries.isEmpty ? 'sin cambios' : entries.join(', ');
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

  _SobreKarUpgradedItemResolution? _upgradeOwnedItemToRarity({
    required Battler player,
    required Item selectedItem,
    required RarityTier targetRarity,
  }) {
    if (selectedItem.rarity.index >= targetRarity.index) return null;

    var resolution = _upgradeOwnedItem(
      player: player,
      selectedItem: selectedItem,
    );
    while (resolution != null &&
        resolution.upgradedItem.rarity.index < targetRarity.index &&
        resolution.upgradedItem.canUpgrade) {
      resolution = _upgradeOwnedItem(
        player: resolution.updatedPlayer,
        selectedItem: resolution.upgradedItem,
      );
    }

    if (resolution?.upgradedItem.rarity != targetRarity) return null;
    return resolution;
  }

  Battler _applyPermanentMaxHealthPercentLoss(
    Battler player,
    double percent,
  ) {
    final loss = max(1, (player.maxHealth * percent).ceil());
    final updatedBaseStats = Map<BattlerStat, int>.from(player.baseStats);
    updatedBaseStats[BattlerStat.health] = max(
      1,
      (updatedBaseStats[BattlerStat.health] ?? player.baseMaxHealth) - loss,
    );
    final updatedPlayer = player.copyWith(
      baseStats: Map<BattlerStat, int>.unmodifiable(updatedBaseStats),
    );
    return updatedPlayer.copyWith(
      health: min(updatedPlayer.health, updatedPlayer.maxHealth),
    );
  }

  BattlerAbility? _rollAbilityForArchetypeAndDay({
    required Battler player,
    required ArchetypeId archetypeId,
    required RunRandomizer randomizer,
    required int dayNumber,
  }) {
    final targetRarity = _rollEventAbilityRarityForDay(
      randomizer: randomizer,
      dayNumber: dayNumber,
    );
    for (final rarity in _rarityFallbacksFrom(targetRarity)) {
      final ability = _rollAbilityFromPoolForExactRarity(
        pool: abilityPoolForArchetype(archetypeId),
        player: player,
        targetRarity: rarity,
        randomizer: randomizer,
      );
      if (ability != null) return ability;
    }
    return null;
  }

  BattlerAbility? _rollAbilityFromPoolForExactRarity({
    required Iterable<BattlerAbility> pool,
    required Battler player,
    required RarityTier targetRarity,
    required RunRandomizer randomizer,
  }) {
    final candidatesById = <BattlerAbilityId, BattlerAbility>{};
    for (final ability in pool) {
      final ownedAbility = player.abilityById(ability.id);
      if (ownedAbility != null) {
        if (ownedAbility.rarity == targetRarity && ownedAbility.canUpgrade) {
          candidatesById.putIfAbsent(
            ability.id,
            () => _runtimeService.runtimeAbility(ownedAbility),
          );
        }
        continue;
      }

      final promotedAbility = _runtimeService.promoteAbilityToExactRarity(
        ability,
        targetRarity,
      );
      if (promotedAbility == null) continue;
      candidatesById.putIfAbsent(ability.id, () => promotedAbility);
    }
    final candidates = candidatesById.values.toList(growable: false);
    if (candidates.isEmpty) return null;
    return _runtimeService.runtimeAbility(
      candidates[randomizer.nextInt(candidates.length)],
    );
  }

  RarityTier _rollEventAbilityRarityForDay({
    required RunRandomizer randomizer,
    required int dayNumber,
  }) {
    final weights = switch (dayNumber) {
      1 => const {
          RarityTier.green: 1.00,
          RarityTier.blue: 0.18,
          RarityTier.purple: 0.03,
        },
      2 => const {
          RarityTier.green: 0.70,
          RarityTier.blue: 0.42,
          RarityTier.purple: 0.08,
        },
      3 => const {
          RarityTier.green: 0.35,
          RarityTier.blue: 0.62,
          RarityTier.purple: 0.22,
        },
      4 => const {
          RarityTier.green: 0.14,
          RarityTier.blue: 0.55,
          RarityTier.purple: 0.46,
          RarityTier.yellow: 0.08,
        },
      _ => const {
          RarityTier.blue: 0.40,
          RarityTier.purple: 0.72,
          RarityTier.yellow: 0.20,
        },
    };
    final totalWeight =
        weights.values.fold<double>(0, (sum, value) => sum + value);
    var roll = randomizer.nextDouble() * totalWeight;
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll <= 0) return entry.key;
    }
    return weights.keys.last;
  }

  RarityTier _rollEventItemRarityForDay({
    required RunRandomizer randomizer,
    required int dayNumber,
  }) {
    final weights = switch (dayNumber) {
      1 => const {
          RarityTier.gray: 1.00,
          RarityTier.green: 0.42,
          RarityTier.blue: 0.08,
        },
      2 => const {
          RarityTier.gray: 0.46,
          RarityTier.green: 0.86,
          RarityTier.blue: 0.22,
          RarityTier.purple: 0.04,
        },
      3 => const {
          RarityTier.green: 0.62,
          RarityTier.blue: 0.68,
          RarityTier.purple: 0.18,
        },
      4 => const {
          RarityTier.green: 0.22,
          RarityTier.blue: 0.62,
          RarityTier.purple: 0.42,
          RarityTier.yellow: 0.08,
        },
      _ => const {
          RarityTier.blue: 0.36,
          RarityTier.purple: 0.70,
          RarityTier.yellow: 0.18,
        },
    };
    final totalWeight =
        weights.values.fold<double>(0, (sum, value) => sum + value);
    var roll = randomizer.nextDouble() * totalWeight;
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll <= 0) return entry.key;
    }
    return weights.keys.last;
  }

  List<RarityTier> _rarityFallbacksFrom(RarityTier targetRarity) {
    return List<RarityTier>.unmodifiable(
      RarityTier.values
          .where((rarity) => rarity.index <= targetRarity.index)
          .toList(growable: false)
          .reversed,
    );
  }

  _SobreKarDebuffRoll _rollSobreKarDebuff(RunRandomizer randomizer) {
    switch (randomizer.nextInt(3)) {
      case 0:
        return const _SobreKarDebuffRoll(
          status: ConmocionStatus(value: 3),
          label: 'Conmocion (-3 daño)',
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

bool _canAppearAlways(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  return true;
}

bool _canAppearForSWitchCabin(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player == null) {
    return itemPresets.where((item) => item.hasPatternBonus).length >= 2;
  }

  return service.buildSWitchCabinEligibleItems(player).length >= 2;
}

bool _canAppearForTechnosurgeon(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  return player?.abilities.isNotEmpty ?? false;
}

bool _canAppearForArchetypeItemReward(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player == null) {
    return itemPresets.any((item) => item.rarity == node.rarity);
  }

  return service
      .buildArchetypeItemRewardPool(
        player: player,
        rarity: node.rarity,
      )
      .isNotEmpty;
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

bool _canAppearForTintoreriaFantasma(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player == null) return itemPresets.isNotEmpty;
  if (!player.hasInventorySpace) return false;

  return itemPoolForArchetype(player.archetypeId).isNotEmpty;
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

bool _canAppearForSuBastaYa(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player == null) {
    return itemPresets.isNotEmpty || abilityPresets.isNotEmpty;
  }

  return service.buildSuBastaYaEligibleItems(player).isNotEmpty ||
      service.buildSuBastaYaEligibleAbilities(player).isNotEmpty;
}

bool _canAppearForPitonisaQuitapenas(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player == null) {
    return true;
  }

  return service.buildPitonisaPurgeableDebuffs(player).isNotEmpty ||
      service.buildPitonisaItemOfferings(player).isNotEmpty ||
      (player.canAfford(service.pitonisaCooldownReductionCost) &&
          service.buildPitonisaCooldownAbilities(player).isNotEmpty);
}

bool _canAppearForVeloz(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  return player?.archetypeId == ArchetypeId.veloz;
}

bool _canAppearForInamovible(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  return player?.archetypeId == ArchetypeId.inamovible;
}

bool _canAppearForBarreraLibre(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player == null) return true;
  return player.reinforcedPatternPointKey == null;
}

bool _canAppearForImparable(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  return player?.archetypeId == ArchetypeId.imparable;
}

bool _canAppearForMercante(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  return player?.archetypeId == ArchetypeId.mercante;
}

bool _canAppearForThePurgame(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player == null) return true;
  return player.purgeDoctrine == null;
}

bool _canAppearForViktorOperations(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player?.archetypeId != ArchetypeId.veloz) return false;
  return service.buildViktorOperationsEligibleItems(player!).isNotEmpty;
}

bool _canAppearForCapillaStShieladurn(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player?.archetypeId != ArchetypeId.inamovible) return false;
  return service.buildOwnedItems(player!).isNotEmpty;
}

bool _canAppearForHornoJuramentos(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player?.archetypeId != ArchetypeId.imparable) return false;
  return service.buildHornoJuramentosEligibleItems(player!).isNotEmpty;
}

PathEventVisitResult _visitDebtCollection(
  PathEventService service, {
  required EventPathNode node,
  required Battler player,
  required RunRandomizer randomizer,
}) {
  return service._resolveDebtCollection(player);
}

PathEventVisitResult _visitArchetypeItemReward(
  PathEventService service, {
  required EventPathNode node,
  required Battler player,
  required RunRandomizer randomizer,
}) {
  return service.resolveArchetypeItemReward(
    node: node,
    player: player,
    randomizer: randomizer,
  );
}

PathEventVisitResult _visitDefaultPathEvent(
  PathEventService service, {
  required EventPathNode node,
  required Battler player,
  required RunRandomizer randomizer,
}) {
  return PathEventVisitResult(
    player: player,
    outcomeText: node.outcomeText,
  );
}
