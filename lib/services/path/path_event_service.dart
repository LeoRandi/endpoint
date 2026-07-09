import '_imports.dart';

part 'handlers/pitonisa_path_event_handler.dart';
part 'handlers/market_path_event_handler.dart';
part 'handlers/mutation_path_event_handler.dart';
part 'handlers/pattern_path_event_handler.dart';
part 'handlers/reward_path_event_handler.dart';
part 'handlers/purge_path_event_handler.dart';
part 'handlers/su_basta_ya_path_event_handler.dart';

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

String _rarityLabel(RarityTier rarity) => switch (rarity) {
      RarityTier.gray => 'GRIS',
      RarityTier.green => 'VERDE',
      RarityTier.blue => 'AZUL',
      RarityTier.purple => 'MORADO',
      RarityTier.yellow => 'AMARILLO',
    };

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
    canAppear: _canAppearForCrepitans,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.viktorOperations: const PathEventDefinition(
    canAppear: _canAppearForViktorOperations,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.arquitecbrosSl: const PathEventDefinition(
    canAppear: _canAppearForDiabolicus,
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
    canAppear: _canAppearForHercules,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.hornoJuramentos: const PathEventDefinition(
    canAppear: _canAppearForHornoJuramentos,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.auditoriaCreativa: const PathEventDefinition(
    canAppear: _canAppearForSacer,
    visit: _visitDefaultPathEvent,
  ),
  PathEventId.mercadoFuturos: const PathEventDefinition(
    canAppear: _canAppearForSacer,
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
    final resolvedItem =
        updatedPlayer.inventoryItemOfType(rewardItem.catalogKey) ??
            updatedPlayer.equippedItemOfType(rewardItem.catalogKey) ??
            rewardItem;
    final actionLabel =
        player.wouldUpgradeItem(rewardItem) ? 'mejora' : 'recibes';

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Del hallazgo $actionLabel ${resolvedItem.displayName} (${_rarityLabel(resolvedItem.rarity)}).',
      gainedItem: resolvedItem,
    );
  }

  List<Item> buildOwnedItems(Battler player) {
    return List<Item>.unmodifiable([
      ...player.equippedItems,
      ...player.inventoryItems,
    ]);
  }

  List<Item> buildViktorOperationsEligibleItems(Battler player) {
    return List<Item>.unmodifiable(
      buildOwnedItems(player).where(
        (item) =>
            item.rarity.isBelow(RarityTier.purple) &&
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

  PathEventVisitResult resolveClinicaReflejosAugment({
    required Battler player,
    required RunRandomizer randomizer,
    required int dayNumber,
  }) {
    final augment = _rollAugmentForArchetypeAndDay(
      player: player,
      archetypeId: ArchetypeId.crepitans,
      randomizer: randomizer,
      dayNumber: dayNumber,
    );
    if (augment == null) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'La clinica no encuentra ningun aumento Crepitans compatible.',
      );
    }

    final updatedPlayer =
        player.addAugment(_runtimeService.runtimeAugment(augment));
    final resolvedAugment = updatedPlayer.augmentById(augment.id) ?? augment;
    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'La Clinica de Reflejos integra ${resolvedAugment.displayName} (${_rarityLabel(resolvedAugment.rarity)}).',
      gainedAugment: resolvedAugment,
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
          'Refuerzas el punto ${point.debugLabel}. Cada Muralla colocada junto a el te dara +1 Barrera.',
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
    Augment? gainedAugment;
    if (selectedItem.isWeaponLike) {
      gainedAugment = _rollAugmentFromPoolForExactRarity(
        pool: augmentCatalog,
        player: updatedPlayer,
        targetRarity: RarityTier.green,
        randomizer: randomizer,
      );
      if (gainedAugment != null) {
        updatedPlayer = updatedPlayer.addAugment(
          _runtimeService.runtimeAugment(gainedAugment),
        );
        gainedAugment = updatedPlayer.augmentById(gainedAugment.id);
      }
    }

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'La Capilla acepta ${selectedItem.displayName}. Ganas +$barrierGain Barrera permanente.',
      gainedAugment: gainedAugment,
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
    final augment = _rollAugmentFromPoolForExactRarity(
      pool: augmentCatalogForArchetype(ArchetypeId.hercules),
      player: player,
      targetRarity: RarityTier.blue,
      randomizer: randomizer,
    );
    var updatedPlayer = player.applyStatus(
      const QuemaduraStatus(remainingTurns: 8),
      applyEquipmentModifiers: false,
    );
    Augment? gainedAugment;
    if (augment != null) {
      updatedPlayer =
          updatedPlayer.addAugment(_runtimeService.runtimeAugment(augment));
      gainedAugment = updatedPlayer.augmentById(augment.id) ?? augment;
    }

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Aceptas el entrenamiento de holo-arena: 8 Quemadura y un aumento Hercules azul.',
      gainedAugment: gainedAugment,
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
          '${resolution.upgradedItem.displayName} sube a ${_rarityLabel(resolution.upgradedItem.rarity)}. Sales con 3 Quemadura y el horno te deja a ${updatedPlayer.health} HP.',
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
    final augment = _rollAugmentFromPoolForExactRarity(
      pool: augmentCatalog,
      player: player,
      targetRarity: RarityTier.green,
      randomizer: randomizer,
    );
    var updatedPlayer = player.applyStatus(
      const DeudaStatus(value: 20),
      applyEquipmentModifiers: false,
    );
    Augment? gainedAugment;
    if (augment != null) {
      updatedPlayer =
          updatedPlayer.addAugment(_runtimeService.runtimeAugment(augment));
      gainedAugment = updatedPlayer.augmentById(augment.id) ?? augment;
    }

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Firmas deuda operativa y recibes un aumento verde gratuito.',
      gainedAugment: gainedAugment,
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

  Augment _rollTechnosurgeonReplacement({
    required EventPathNode node,
    required Augment selectedAugment,
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    final ownedAugmentIds = player.augments
        .where((augment) => augment.id != selectedAugment.id)
        .map((augment) => augment.id)
        .toSet();
    final scopedPool = augmentCatalogForArchetype(player.archetypeId);
    var candidates = scopedPool
        .where(
          (augment) =>
              augment.id != selectedAugment.id &&
              !ownedAugmentIds.contains(augment.id),
        )
        .toList(growable: false);

    if (candidates.isEmpty) {
      candidates = scopedPool
          .where((augment) => augment.id != selectedAugment.id)
          .toList(growable: false);
    }
    if (candidates.isEmpty) {
      candidates = augmentCatalog;
    }

    final rolledAugment = candidates[randomizer.nextInt(candidates.length)];
    return _runtimeService.promoteAugmentToAtLeastRarity(
      rolledAugment,
      _technosurgeonTargetRarity(
        node: node,
        selectedAugment: selectedAugment,
      ),
    );
  }

  Augment _rollBlackTechnoMarketOffer({
    required Augment catalogEntry,
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    final ownedAugment = player.augmentById(catalogEntry.id);
    if (ownedAugment != null) {
      return _runtimeService.runtimeAugment(ownedAugment);
    }

    final targetRarity = RarityProgressionService.rollWeightedAtLeast(
      minimumRarity: catalogEntry.rarity,
      randomizer: randomizer,
    );
    return _runtimeService.promoteAugmentToAtLeastRarity(
      catalogEntry,
      targetRarity,
    );
  }

  Augment _rollSuBastaYaReplacementAugment({
    required Augment selectedAugment,
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    final ownedAugmentIds = player.augments
        .where((augment) => augment.id != selectedAugment.id)
        .map((augment) => augment.id)
        .toSet();
    var candidates = augmentCatalogForArchetype(player.archetypeId)
        .where(
          (augment) =>
              augment.id != selectedAugment.id &&
              augment.rarity.isAtLeast(selectedAugment.rarity) &&
              !ownedAugmentIds.contains(augment.id),
        )
        .toList(growable: false);

    if (candidates.isEmpty) {
      candidates = augmentCatalogForArchetype(player.archetypeId)
          .where((augment) => augment.id != selectedAugment.id)
          .toList(growable: false);
    }
    if (candidates.isEmpty) {
      candidates = augmentCatalog
          .where((augment) => augment.id != selectedAugment.id)
          .toList(growable: false);
    }
    if (candidates.isEmpty) {
      return _runtimeService.runtimeAugment(selectedAugment);
    }

    final rolledAugment = candidates[randomizer.nextInt(candidates.length)];
    return _runtimeService.promoteAugmentToAtLeastRarity(
      rolledAugment,
      selectedAugment.rarity,
    );
  }

  RarityTier _technosurgeonTargetRarity({
    required EventPathNode node,
    required Augment selectedAugment,
  }) {
    final nextTier = selectedAugment.rarity.nextTier;
    if (node.id != PathEventId.afterHoursTechnosurgeon ||
        nextTier.isAtLeast(RarityTier.purple)) {
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

  Augment? _rollRewardAugment({
    required Battler player,
    required RarityTier rarity,
    required RunRandomizer randomizer,
  }) {
    final candidatesById = <int, Augment>{};
    for (final augment in augmentCatalog) {
      final ownedAugment = player.augmentById(augment.id);
      if (ownedAugment != null) {
        if (ownedAugment.rarity == rarity && ownedAugment.canUpgrade) {
          candidatesById.putIfAbsent(
            augment.id,
            () => _runtimeService.runtimeAugment(ownedAugment),
          );
        }
        continue;
      }

      final promotedAugment =
          _runtimeService.promoteAugmentToExactRarity(augment, rarity);
      if (promotedAugment == null) continue;
      candidatesById.putIfAbsent(augment.id, () => promotedAugment);
    }

    final candidates = candidatesById.values.toList(growable: false);
    if (candidates.isEmpty) return null;
    return _runtimeService.runtimeAugment(
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
    if (selectedItem.rarity.isAtLeast(targetRarity)) return null;

    var resolution = _upgradeOwnedItem(
      player: player,
      selectedItem: selectedItem,
    );
    while (resolution != null &&
        resolution.upgradedItem.rarity.isBelow(targetRarity) &&
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

  Augment? _rollAugmentForArchetypeAndDay({
    required Battler player,
    required ArchetypeId archetypeId,
    required RunRandomizer randomizer,
    required int dayNumber,
  }) {
    final targetRarity = _rollEventAugmentRarityForDay(
      randomizer: randomizer,
      dayNumber: dayNumber,
    );
    for (final rarity in RarityProgressionService.fallbackTiersFrom(
      targetRarity,
    )) {
      final augment = _rollAugmentFromPoolForExactRarity(
        pool: augmentCatalogForArchetype(archetypeId),
        player: player,
        targetRarity: rarity,
        randomizer: randomizer,
      );
      if (augment != null) return augment;
    }
    return null;
  }

  Augment? _rollAugmentFromPoolForExactRarity({
    required Iterable<Augment> pool,
    required Battler player,
    required RarityTier targetRarity,
    required RunRandomizer randomizer,
  }) {
    final candidatesById = <int, Augment>{};
    for (final augment in pool) {
      final ownedAugment = player.augmentById(augment.id);
      if (ownedAugment != null) {
        if (ownedAugment.rarity == targetRarity && ownedAugment.canUpgrade) {
          candidatesById.putIfAbsent(
            augment.id,
            () => _runtimeService.runtimeAugment(ownedAugment),
          );
        }
        continue;
      }

      final promotedAugment = _runtimeService.promoteAugmentToExactRarity(
        augment,
        targetRarity,
      );
      if (promotedAugment == null) continue;
      candidatesById.putIfAbsent(augment.id, () => promotedAugment);
    }
    final candidates = candidatesById.values.toList(growable: false);
    if (candidates.isEmpty) return null;
    return _runtimeService.runtimeAugment(
      candidates[randomizer.nextInt(candidates.length)],
    );
  }

  RarityTier _rollEventAugmentRarityForDay({
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
    return itemPresets.where((item) => item.patternEffects.isNotEmpty).length >=
        2;
  }

  return service.buildSWitchCabinEligibleItems(player).length >= 2;
}

bool _canAppearForTechnosurgeon(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  return player?.augments.isNotEmpty ?? false;
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
    return augmentCatalog.isNotEmpty;
  }

  return augmentCatalog.any((augment) {
    final ownedAugment = player.augmentById(augment.id);
    return ownedAugment == null || ownedAugment.canUpgrade;
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
    return itemPresets.isNotEmpty || augmentCatalog.isNotEmpty;
  }

  return service.buildSuBastaYaEligibleItems(player).isNotEmpty ||
      service.buildSuBastaYaEligibleAugments(player).isNotEmpty;
}

bool _canAppearForPitonisaQuitapenas(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player == null) {
    return true;
  }

  return service.buildPitonisaPurgeableDebuffs(player).isNotEmpty;
}

bool _canAppearForCrepitans(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  return player?.archetypeId == ArchetypeId.crepitans;
}

bool _canAppearForDiabolicus(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  return player?.archetypeId == ArchetypeId.diabolicus;
}

bool _canAppearForBarreraLibre(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player == null) return true;
  return player.reinforcedPatternPointKey == null;
}

bool _canAppearForHercules(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  return player?.archetypeId == ArchetypeId.hercules;
}

bool _canAppearForSacer(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  return player?.archetypeId == ArchetypeId.sacer;
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
  if (player?.archetypeId != ArchetypeId.crepitans) return false;
  return service.buildViktorOperationsEligibleItems(player!).isNotEmpty;
}

bool _canAppearForCapillaStShieladurn(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player?.archetypeId != ArchetypeId.diabolicus) return false;
  return service.buildOwnedItems(player!).isNotEmpty;
}

bool _canAppearForHornoJuramentos(
  PathEventService service, {
  required EventPathNode node,
  required Battler? player,
}) {
  if (player?.archetypeId != ArchetypeId.hercules) return false;
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
