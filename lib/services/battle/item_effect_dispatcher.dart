import '_imports.dart';

typedef ItemCustomActionHandler = ItemEffectResolution Function({
  required Battler owner,
  required Battler opponent,
  required Item item,
  required ActionEffect effect,
  required BattlePatternMatchContext pattern,
  required List<ActionEffect> previousActions,
});

typedef ItemPassiveEffectHandler = ItemEffectResolution Function({
  required Battler owner,
  required Battler opponent,
  required Item item,
  required PassiveEffect effect,
  required bool isOwnerTurn,
  required int damageDealt,
  required int damageTaken,
  required DamageKind? damageKind,
  required Item? sourceItem,
  required ActionEffect? action,
  required BattlerStatus? status,
  required BattlePatternMatchContext? pattern,
});

/// Central execution registry for bespoke item behavior.
///
/// Standard attack, block and heal actions are resolved directly by battle.
/// Content-specific actions use a stable key so their behavior remains
/// serializable and does not depend on localized description text.
abstract final class ItemEffectDispatcher {
  static final Map<String, ItemCustomActionHandler> _customActions = {
    ItemEffectKeys.homemadeFlameBurnBoth: _resolveHomemadeFlameBurnBoth,
    ItemEffectKeys.broomBrushCleanseAndConmocion:
        _resolveBroomBrushCleanseAndConmocion,
    ItemEffectKeys.poisonStingerIntoxicacion: _resolvePoisonStingerIntoxicacion,
    ItemEffectKeys.mantisBladeGainDesafio: _resolveMantisBladeGainDesafio,
    ItemEffectKeys.bugZapperRacketFragilidad: _resolveBugZapperRacketFragilidad,
    ItemEffectKeys.camouflageLeavesPuntoCiego:
        _resolveCamouflageLeavesPuntoCiego,
    ItemEffectKeys.moltSacrificeBarrierDamage:
        _resolveMoltSacrificeBarrierDamage,
    ItemEffectKeys.flowerCrownGainCalentando: _resolveFlowerCrownGainCalentando,
    ItemEffectKeys.hazardSprayIntoxicacion: _resolveHazardSprayIntoxicacion,
    ItemEffectKeys.zapatillaExtraDamage: _resolveZapatillaExtraDamage,
    ItemEffectKeys.repellerConmocion: _resolveRepellerConmocion,
    ItemEffectKeys.repellerOpeningWave: _resolveRepellerOpeningWave,
    ItemEffectKeys.webCannonFragilidad: _resolveWebCannonFragilidad,
    ItemEffectKeys.webCannonFragileRepeat: _resolveWebCannonFragileRepeat,
    ItemEffectKeys.electricNetSquareTrap: _resolveElectricNetSquareTrap,
    ItemEffectKeys.campfireBurnAndPuntoCiego: _resolveCampfireBurnAndPuntoCiego,
    ItemEffectKeys.sunglasses: _resolveSunglasses,
    ItemEffectKeys.sHarpEner: _resolveSHarpEner,
    ItemEffectKeys.duelistChalkGainDesafio: _resolveDuelistChalkGainDesafio,
    ItemEffectKeys.kindlingAxeBurnBoth: _resolveKindlingAxeBurnBoth,
    ItemEffectKeys.ashEaterMaskSelfBurnHeal: _resolveAshEaterMaskSelfBurnHeal,
    ItemEffectKeys.furnaceHeartRightAngleTrigger:
        _resolveFurnaceHeartRightAngleTrigger,
    ItemEffectKeys.challengeBrandRightAngleDesafio:
        _resolveChallengeBrandRightAngleDesafio,
    ItemEffectKeys.crownOfTheBlackSunFinisher:
        _resolveCrownOfTheBlackSunFinisher,
    ItemEffectKeys.rampartRamFinisher: _resolveRampartRamFinisher,
    ItemEffectKeys.citadelCoreSquareFortress: _resolveCitadelCoreSquareFortress,
    ItemEffectKeys.splinterDartFragilidad: _resolveSplinterDartFragilidad,
    ItemEffectKeys.needlewheelComboRepeat: _resolveNeedlewheelComboRepeat,
    ItemEffectKeys.tripwireKnivesDebuffRepeat:
        _resolveTripwireKnivesDebuffRepeat,
    ItemEffectKeys.venotronomeZigzag: _resolveVenomMetronomeZigzag,
    ItemEffectKeys.afterimageMotorRightAngleRepeat:
        _resolveAfterimageMotorRightAngleRepeat,
    ItemEffectKeys.pulseStitcherFinisherCleanse:
        _resolvePulseStitcherFinisherCleanse,
    ItemEffectKeys.leechwireCoilMiddleContagio:
        _resolveLeechwireCoilMiddleContagio,
    ItemEffectKeys.thousandCutHaloFinisher: _resolveThousandCutHaloFinisher,
    ItemEffectKeys.laCuentaSpendGoldPotencia: _resolveLaCuentaSpendGoldPotencia,
    ItemEffectKeys.lanzamonedasSpendGoldDamage:
        _resolveLanzamonedasSpendGoldDamage,
    ItemEffectKeys.cashbackBadgeOpeningDiscount:
        _resolveCashbackBadgeOpeningDiscount,
    ItemEffectKeys.contrabandCatalogueMiddleProfit:
        _resolveContrabandCatalogueMiddleProfit,
    ItemEffectKeys.goldenGodfatherFinisher: _resolveGoldenGodfatherFinisher,
  };
  static final Map<String, ItemPassiveEffectHandler> _passiveHandlers = {
    ItemEffectKeys.camouflageLeavesBlocking: _resolvePassiveNoop,
    ItemEffectKeys.bloodReservesEmergencyHeal:
        _resolveBloodReservesEmergencyHeal,
    ItemEffectKeys.oniscideaShieldCurlUp: _resolveOniscideaShieldCurlUp,
    ItemEffectKeys.electricNetDefensiveShock: _resolveElectricNetDefensiveShock,
    ItemEffectKeys.campfireBurnAttraction: _resolveCampfireBurnAttraction,
    ItemEffectKeys.campfireBurnBlocking: _resolvePassiveNoop,
    ItemEffectKeys.nanoBandageTurnStartHeal: _resolveNanoBandageTurnStartHeal,
    ItemEffectKeys.oathplateCleanse: _resolveOathplateCleanse,
    ItemEffectKeys.whitewallStandardBarrierBoost:
        _resolveWhitewallStandardBarrierBoost,
    ItemEffectKeys.whitewallStandardBuffStacking:
        _resolveWhitewallStandardBuffStacking,
    ItemEffectKeys.furnaceHeartAdjacentWeapons:
        _resolveFurnaceHeartAdjacentWeapons,
    ItemEffectKeys.spiteHookRevengeStrike: _resolveSpiteHookRevengeStrike,
    ItemEffectKeys.ashEaterMaskBurnPotencia: _resolveAshEaterMaskBurnPotencia,
    ItemEffectKeys.challengeBrandCounterBurn: _resolveChallengeBrandCounterBurn,
    ItemEffectKeys.bloodflameGauntletBurnRevenge:
        _resolveBloodflameGauntletBurnRevenge,
    ItemEffectKeys.crownOfTheBlackSunNoDeathOnce:
        _resolveCrownOfTheBlackSunFirstHurt,
    ItemEffectKeys.citadelCoreFortressScaling:
        _resolveCitadelCoreFortressScaling,
    ItemEffectKeys.citadelCoreUnbrokenRetaliation:
        _resolveCitadelCoreUnbrokenRetaliation,
    ItemEffectKeys.venotronomeRepeatedActionPoison:
        _resolveVenomMetronomeRepeatedActionPoison,
    ItemEffectKeys.pulseStitcherComboHeal: _resolvePulseStitcherComboHeal,
    ItemEffectKeys.leechwireCoilHealFromDebuffs:
        _resolveLeechwireCoilHealFromDebuffs,
    ItemEffectKeys.blindspotMantlePuntoCiegoLimit:
        _resolveBlindspotMantlePuntoCiegoLimit,
    ItemEffectKeys.executionBellCounterRevenge: _resolvePassiveNoop,
    ItemEffectKeys.thousandCutHaloActionScaling:
        _resolveThousandCutHaloActionScaling,
    ItemEffectKeys.thousandCutHaloStatusEcho: _resolveThousandCutHaloStatusEcho,
    ItemEffectKeys.cashbackBadgeRefund: _resolvePassiveNoop,
    ItemEffectKeys.cashbackBadgeSpendPotencia: _resolvePassiveNoop,
    ItemEffectKeys.contrabandCatalogueMixedArchetypeScaling:
        _resolveContrabandCatalogueMixedArchetypeScaling,
    ItemEffectKeys.contrabandCatalogueGoldSpendEcho: _resolvePassiveNoop,
    ItemEffectKeys.goldenGodfatherRichScaling: _resolvePassiveNoop,
  };

  static void registerCustomAction(
    String key,
    ItemCustomActionHandler handler,
  ) {
    _customActions[key] = handler;
  }

  static void registerPassive(
    String effectKey,
    ItemPassiveEffectHandler handler,
  ) {
    _passiveHandlers[effectKey] = handler;
  }

  static ItemEffectResolution resolveCustomAction({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    List<ActionEffect> previousActions = const <ActionEffect>[],
  }) {
    final key = effect.customEffectKey;
    final handler = key == null ? null : _customActions[key];
    return handler?.call(
          owner: owner,
          opponent: opponent,
          item: item,
          effect: effect,
          pattern: pattern,
          previousActions: previousActions,
        ) ??
        ItemEffectResolution(owner: owner, opponent: opponent);
  }

  static ItemEffectResolution resolvePassiveHook({
    required Battler owner,
    required Battler opponent,
    required ItemEffectHook hook,
    Item? onlyItem,
    bool isOwnerTurn = false,
    int damageDealt = 0,
    int damageTaken = 0,
    DamageKind? damageKind,
    Item? sourceItem,
    ActionEffect? action,
    BattlerStatus? status,
    BattlePatternMatchContext? pattern,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;
    var updatedStatus = status;
    final followUpActions = <ActionEffect>[];
    final followUpItemActions = <ItemFollowUpAction>[];
    final items = onlyItem == null ? owner.equippedItems : <Item>[onlyItem];
    for (final item in items) {
      for (final effect in item.passiveEffects.where(
        (effect) => effect.hook == hook,
      )) {
        final handler = _passiveHandlers[effect.effectKey];
        if (handler == null) continue;
        final resolution = handler(
          owner: updatedOwner,
          opponent: updatedOpponent,
          item: item,
          effect: effect,
          isOwnerTurn: isOwnerTurn,
          damageDealt: damageDealt,
          damageTaken: damageTaken,
          damageKind: damageKind,
          sourceItem: sourceItem,
          action: action,
          status: updatedStatus,
          pattern: pattern,
        );
        updatedOwner = resolution.owner;
        updatedOpponent = resolution.opponent;
        updatedStatus = resolution.status ?? updatedStatus;
        followUpActions.addAll(resolution.followUpActions);
        followUpItemActions.addAll(resolution.followUpItemActions);
      }
    }

    if (hook == ItemEffectHook.attackResolved) {
      final resolution = _resolveAttackResolvedCrossHookEffects(
        owner: updatedOwner,
        opponent: updatedOpponent,
        sourceItem: sourceItem,
        damageDealt: damageDealt,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
      followUpActions.addAll(resolution.followUpActions);
      followUpItemActions.addAll(resolution.followUpItemActions);
    }

    return ItemEffectResolution(
      owner: updatedOwner,
      opponent: updatedOpponent,
      status: updatedStatus,
      followUpActions: List<ActionEffect>.unmodifiable(followUpActions),
      followUpItemActions:
          List<ItemFollowUpAction>.unmodifiable(followUpItemActions),
    );
  }

  static ItemEffectResolution _resolveSunglasses({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    return ItemEffectResolution(
      owner: owner,
      opponent: opponent,
      followUpActions: List<ActionEffect>.unmodifiable(previousActions),
    );
  }

  static ItemEffectResolution _resolveSHarpEner({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    const sourceKey = 'item:s_harp_ener';
    final sourcePointKey = OperativePatternLayoutService.pointKeyForItem(
      player: owner,
      item: item,
    );
    if (sourcePointKey == null) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final sourcePoint = operativePatternPointsByKey[sourcePointKey];
    if (sourcePoint == null) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    var updatedOwner = owner;
    final boostedPointKeys = _adjacentPointKeys(sourcePoint);
    for (final targetItem in owner.equippedItems) {
      if (!targetItem.isWeaponLike) continue;
      final targetPointKey = OperativePatternLayoutService.pointKeyForItem(
        player: owner,
        item: targetItem,
      );
      if (targetPointKey == null ||
          !boostedPointKeys.contains(targetPointKey)) {
        continue;
      }

      final currentBonus = targetItem.actionBonusValueForSource(
        actionType: ItemActionType.attack,
        sourceKey: sourceKey,
      );
      updatedOwner = updatedOwner.replaceOwnedItem(
        currentItem: targetItem,
        replacementItem: targetItem.withActionBonus(
          actionType: ItemActionType.attack,
          sourceKey: sourceKey,
          bonusValue: currentBonus + max(0, effect.totalValue),
        ),
      );
    }

    return ItemEffectResolution(owner: updatedOwner, opponent: opponent);
  }

  static ItemEffectResolution _resolveHomemadeFlameBurnBoth({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final opponentBurn = _applyBurnToOpponent(
      owner: owner,
      opponent: opponent,
      amount: effect.totalValue,
    );
    final burnedOwner = _applyBurnToOwner(
      owner: opponentBurn.owner,
      opponent: opponentBurn.opponent,
      amount: 1,
    );
    return ItemEffectResolution(
      owner: burnedOwner,
      opponent: opponentBurn.opponent,
    );
  }

  static ItemEffectResolution _resolveBroomBrushCleanseAndConmocion({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    var cleansedCount = 0;
    var updatedOpponent = opponent;
    for (final status in opponent.statuses) {
      if (cleansedCount >= effect.totalValue) break;
      if (status.type != BattlerStatusType.buff || !status.isPurgeable) {
        continue;
      }
      updatedOpponent = updatedOpponent.removeStatusInstance(status);
      cleansedCount++;
    }

    var updatedOwner = owner;
    if (owner.equippedItemOfType('Wooden Stick') != null) {
      final resolution = _applyConmocionToOpponent(
        owner: updatedOwner,
        opponent: updatedOpponent,
        amount: effect.totalValue,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return ItemEffectResolution(
      owner: updatedOwner,
      opponent: updatedOpponent,
    );
  }

  static ItemEffectResolution _resolvePoisonStingerIntoxicacion({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final resolution = _applyPoisonToOpponent(
      owner: owner,
      opponent: opponent,
      amount: effect.totalValue,
    );
    return ItemEffectResolution(
      owner: resolution.owner,
      opponent: resolution.opponent,
    );
  }

  static ItemEffectResolution _resolveMantisBladeGainDesafio({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    return ItemEffectResolution(
      owner: owner.gainDesafio(effect.totalValue),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveBugZapperRacketFragilidad({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    return _resolveFragilidadAction(
      owner: owner,
      opponent: opponent,
      effect: effect,
    );
  }

  static ItemEffectResolution _resolveCamouflageLeavesPuntoCiego({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    return ItemEffectResolution(
      owner: _gainPuntoCiegoAndMaybeBlockPoint(
        owner: owner,
        item: item,
        blockEffectKey: ItemEffectKeys.camouflageLeavesBlocking,
      ),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveMoltSacrificeBarrierDamage({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final consumedBarrier = min(owner.currentBarrier, effect.totalValue);
    if (consumedBarrier <= 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _gainCalentando(
        owner.copyWith(currentBarrier: owner.currentBarrier - consumedBarrier),
        consumedBarrier,
      ),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveFlowerCrownGainCalentando({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    return ItemEffectResolution(
      owner: _gainPotencia(owner, effect.totalValue),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveHazardSprayIntoxicacion({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    return _resolvePoisonStingerIntoxicacion(
      owner: owner,
      opponent: opponent,
      item: item,
      effect: effect,
      pattern: pattern,
      previousActions: previousActions,
    );
  }

  static ItemEffectResolution _resolveZapatillaExtraDamage({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final hasDebuff = opponent.statuses.any(
      (status) => status.type == BattlerStatusType.debuff,
    );
    return ItemEffectResolution(
      owner: owner,
      opponent: hasDebuff
          ? opponent.copyWith(
              health: max(0, opponent.health - effect.totalValue),
            )
          : opponent,
    );
  }

  static ItemEffectResolution _resolveRepellerConmocion({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final resolution = _applyConmocionToOpponent(
      owner: owner,
      opponent: opponent,
      amount: effect.totalValue,
    );
    return ItemEffectResolution(
      owner: resolution.owner,
      opponent: resolution.opponent,
    );
  }

  static ItemEffectResolution _resolveRepellerOpeningWave({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    return ItemEffectResolution(
      owner: owner.addCombatFlag(
        CombatRuntimeFlag.item(
          itemEffectKey: ItemEffectKeys.repellerOpeningWave,
          itemKey: item.catalogKey,
          itemInstanceId: item.instanceId,
          secondaryValue: effect.totalValue,
        ),
      ),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveWebCannonFragilidad({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    return _resolveFragilidadAction(
      owner: owner,
      opponent: opponent,
      effect: effect,
    );
  }

  static ItemEffectResolution _resolveWebCannonFragileRepeat({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    if (!opponent.hasStatus(FragilidadStatus.statusId)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final weakestWeapon = _weakestWeapon(owner);
    if (weakestWeapon == null) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final followUps = <ItemFollowUpAction>[
      for (var repeat = 0; repeat < max(0, effect.totalValue); repeat++)
        for (final action in _attackActionsForFollowUpWeapon(
          owner: owner,
          weapon: weakestWeapon,
        ))
          ItemFollowUpAction(item: weakestWeapon, action: action),
    ];

    return ItemEffectResolution(
      owner: owner,
      opponent: opponent,
      followUpItemActions: List<ItemFollowUpAction>.unmodifiable(followUps),
    );
  }

  static ItemEffectResolution _resolveElectricNetSquareTrap({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final barrierOwner = owner.gainCombatBarrier(effect.totalValue);
    final fragilityResolution = _applyStatusToOpponent(
      owner: barrierOwner,
      opponent: opponent,
      status: const FragilidadStatus(value: 2),
    );
    return ItemEffectResolution(
      owner: fragilityResolution.owner,
      opponent: fragilityResolution.opponent,
    );
  }

  static ItemEffectResolution _resolveCampfireBurnAndPuntoCiego({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final burnResolution = _applyBurnToOpponent(
      owner: owner,
      opponent: opponent,
      amount: effect.totalValue,
    );
    return ItemEffectResolution(
      owner: _gainPuntoCiegoAndMaybeBlockPoint(
        owner: burnResolution.owner,
        item: item,
        blockEffectKey: ItemEffectKeys.campfireBurnBlocking,
      ),
      opponent: burnResolution.opponent,
    );
  }

  static ItemEffectResolution _resolveDuelistChalkGainDesafio({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    return ItemEffectResolution(
      owner: owner.gainDesafio(effect.totalValue),
      opponent: opponent,
    );
  }

  static Set<String> _adjacentPointKeys(OperativePatternPoint sourcePoint) {
    final pointKeys = <String>{};
    for (final offset in const [
      (dx: 0, dy: 1),
      (dx: 0, dy: -1),
      (dx: 1, dy: 0),
      (dx: -1, dy: 0),
    ]) {
      final point = operativePatternPointAt(
        x: sourcePoint.x + offset.dx,
        y: sourcePoint.y + offset.dy,
      );
      if (point != null) pointKeys.add(point.key);
    }
    return pointKeys;
  }

  static ItemEffectResolution _resolveNanoBandageTurnStartHeal({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    return ItemEffectResolution(
      owner: isOwnerTurn ? owner.heal(effect.value) : owner,
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveBloodReservesEmergencyHeal({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    if (damageTaken <= 0 ||
        owner.health * 2 >= owner.maxHealth ||
        owner.itemCombatFlagUseCount(item: item, kind: effect.effectKey) > 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner
          .heal(effect.value)
          .addItemCombatFlagUse(item: item, kind: effect.effectKey),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveOniscideaShieldCurlUp({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    if (!isOwnerTurn || owner.itemAttackActionResolvedCountThisTurn > 1) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.gainCombatBarrier(effect.value),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveElectricNetDefensiveShock({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    final resolution = _applyStatusToOpponent(
      owner: owner,
      opponent: opponent,
      status: FragilidadStatus(value: effect.value),
    );
    return ItemEffectResolution(
      owner: resolution.owner,
      opponent: resolution.opponent,
    );
  }

  static ItemEffectResolution _resolveCampfireBurnAttraction({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    final resolution = _applyBurnToOpponent(
      owner: owner,
      opponent: opponent,
      amount: effect.value,
    );
    return ItemEffectResolution(
      owner: resolution.owner,
      opponent: resolution.opponent,
    );
  }

  static ItemEffectResolution _resolveOathplateCleanse({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    if (!isOwnerTurn || owner.currentBarrier <= 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _cleanseDebuffs(
        owner: owner,
        maxCount: effect.value,
      ),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveWhitewallStandardBarrierBoost({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    final adjacentBarrierItems =
        _adjacentBarrierItems(owner: owner, item: item);
    return ItemEffectResolution(
      owner: owner.addCombatBlockBonusToItems(
        items: adjacentBarrierItems,
        amount: effect.value,
        sourceKey: _itemSourceKey(
          item: item,
          effectKey: effect.effectKey,
        ),
      ),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveWhitewallStandardBuffStacking({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    final usedBarrierItems = _usedItemsMatching(
      owner: owner,
      pattern: pattern,
      matches: (item) => item.hasTag(EntityTag.barrera),
    );
    if (usedBarrierItems.length < 2) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _gainCalentando(owner, effect.value),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveKindlingAxeBurnBoth({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final opponentBurn = _applyBurnToOpponent(
      owner: owner,
      opponent: opponent,
      amount: effect.totalValue,
    );
    final burnedOwner = _applyBurnToOwner(
      owner: opponentBurn.owner,
      opponent: opponentBurn.opponent,
      amount: 2,
    );
    return ItemEffectResolution(
      owner: burnedOwner,
      opponent: opponentBurn.opponent,
    );
  }

  static ItemEffectResolution _resolveSpiteHookRevengeStrike({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    if (sourceItem != item || owner.damageTakenThisRound <= 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.gainDesafio(effect.value),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveAshEaterMaskBurnPotencia({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    if (!isOwnerTurn || _burnValue(owner) <= 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _gainPotencia(owner, effect.value),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveAshEaterMaskSelfBurnHeal({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final burnedOwner = _applyBurnToOwner(
      owner: owner,
      opponent: opponent,
      amount: effect.totalValue,
    );
    return ItemEffectResolution(
      owner: burnedOwner.health * 2 < burnedOwner.maxHealth
          ? burnedOwner.heal(effect.totalValue)
          : burnedOwner,
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveFurnaceHeartAdjacentWeapons({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    final adjacentWeapons = _adjacentWeaponItems(owner: owner, item: item);
    return ItemEffectResolution(
      owner: owner.addCombatAttackBonusToWeapons(
        weapons: adjacentWeapons,
        amount: effect.value,
        sourceKey: _itemSourceKey(
          item: item,
          effectKey: effect.effectKey,
        ),
      ),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveFurnaceHeartRightAngleTrigger({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final burnedOwner = _applyBurnToOwner(
      owner: owner,
      opponent: opponent,
      amount: effect.totalValue,
    );
    final usedPointKeys = pattern.usedItemPointKeys.toSet();
    final followUps = <ItemFollowUpAction>[
      for (final weapon in _adjacentWeaponItems(owner: burnedOwner, item: item))
        if (usedPointKeys.contains(
          OperativePatternLayoutService.pointKeyForItem(
            player: burnedOwner,
            item: weapon,
          ),
        ))
          for (final action in _actionsForFollowUpWeapon(
            owner: burnedOwner,
            weapon: weapon,
          ))
            ItemFollowUpAction(item: weapon, action: action),
    ];

    return ItemEffectResolution(
      owner: burnedOwner,
      opponent: opponent,
      followUpItemActions: List<ItemFollowUpAction>.unmodifiable(followUps),
    );
  }

  static ItemEffectResolution _resolveChallengeBrandCounterBurn({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    if (damageKind != DamageKind.desafioCounter || damageTaken <= 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final opponentBurn = _applyBurnToOpponent(
      owner: owner,
      opponent: opponent,
      amount: effect.value,
    );
    final ownerBurn = _applyBurnToOwner(
      owner: opponentBurn.owner,
      opponent: opponentBurn.opponent,
      amount: effect.value,
    );
    return ItemEffectResolution(
      owner: ownerBurn,
      opponent: opponentBurn.opponent,
    );
  }

  static ItemEffectResolution _resolveChallengeBrandRightAngleDesafio({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final ownerWithDesafio = owner.gainDesafio(effect.totalValue);
    return ItemEffectResolution(
      owner: _burnValue(ownerWithDesafio) > 0
          ? ownerWithDesafio.heal(effect.totalValue)
          : ownerWithDesafio,
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveBloodflameGauntletBurnRevenge({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    if (damageKind != DamageKind.burn || damageTaken <= 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.addItemCombatFlagUse(
        item: item,
        kind: effect.effectKey,
      ),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveCrownOfTheBlackSunFirstHurt({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    if (damageDealt <= 0 ||
        owner.itemCombatFlagUseCount(item: item, kind: effect.effectKey) > 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final opponentBurn = _applyBurnToOpponent(
      owner: owner,
      opponent: opponent,
      amount: effect.value,
    );
    final burnedOwner = _applyBurnToOwner(
      owner: opponentBurn.owner,
      opponent: opponentBurn.opponent,
      amount: effect.value,
    ).addItemCombatFlagUse(
      item: item,
      kind: effect.effectKey,
    );
    final followUps = <ItemFollowUpAction>[
      for (final weapon in _adjacentWeaponItems(owner: burnedOwner, item: item))
        for (final action in _actionsForFollowUpWeapon(
          owner: burnedOwner,
          weapon: weapon,
        ))
          ItemFollowUpAction(item: weapon, action: action),
    ];

    return ItemEffectResolution(
      owner: burnedOwner,
      opponent: opponentBurn.opponent,
      followUpItemActions: List<ItemFollowUpAction>.unmodifiable(followUps),
    );
  }

  static ItemEffectResolution _resolveRampartRamFinisher({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final damage = effect.totalValue * (owner.currentBarrier ~/ 10);
    return ItemEffectResolution(
      owner: owner,
      opponent: _dealDamageToOpponent(
        owner: owner,
        opponent: opponent,
        damage: damage,
      ),
    );
  }

  static ItemEffectResolution _resolveCitadelCoreFortressScaling({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    if (!isOwnerTurn || owner.currentBarrier < 20) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _gainCalentando(owner, effect.value),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveCitadelCoreUnbrokenRetaliation({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    final damage = effect.value * _buffStackValue(owner);
    return ItemEffectResolution(
      owner: owner,
      opponent: _dealDamageToOpponent(
        owner: owner,
        opponent: opponent,
        damage: damage,
      ),
    );
  }

  static ItemEffectResolution _resolveCitadelCoreSquareFortress({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final ownerAfterBarrier = owner.gainCombatBarrier(effect.totalValue);
    final ownerAfterCleanse = _cleanseDebuffs(
      owner: ownerAfterBarrier,
      maxCount: 1,
    );
    final damage = ownerAfterCleanse.currentBarrier ~/ 4;

    return ItemEffectResolution(
      owner: ownerAfterCleanse,
      opponent: _dealDamageToOpponent(
        owner: ownerAfterCleanse,
        opponent: opponent,
        damage: damage,
      ),
    );
  }

  static ItemEffectResolution _resolveCrownOfTheBlackSunFinisher({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final burnToConsume = _burnValue(owner) ~/ 2;
    if (burnToConsume <= 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final updatedOwner = _consumeBurn(owner, burnToConsume);
    final trueDamage = burnToConsume * effect.totalValue;
    final updatedOpponent = trueDamage <= 0
        ? opponent
        : opponent.copyWith(
            health: max(0, opponent.health - trueDamage),
          );

    return ItemEffectResolution(
      owner: updatedOwner,
      opponent: updatedOpponent,
    );
  }

  static ItemEffectResolution _resolveNeedlewheelComboRepeat({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final actionNumberThisTurn = previousActions.length + 1;
    if (actionNumberThisTurn != 3 || effect.totalValue <= 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final followUps = <ItemFollowUpAction>[
      for (var repeat = 0; repeat < effect.totalValue; repeat++)
        for (final action in _attackActionsForFollowUpWeapon(
          owner: owner,
          weapon: item,
        ))
          ItemFollowUpAction(item: item, action: action),
    ];

    return ItemEffectResolution(
      owner: owner,
      opponent: opponent,
      followUpItemActions: List<ItemFollowUpAction>.unmodifiable(followUps),
    );
  }

  static ItemEffectResolution _resolveTripwireKnivesDebuffRepeat({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    if (effect.totalValue <= 0 ||
        previousActions.isEmpty ||
        !_actionAppliesDebuff(previousActions.last)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final followUps = <ItemFollowUpAction>[
      for (var repeat = 0; repeat < effect.totalValue; repeat++)
        for (final action in _attackActionsForFollowUpWeapon(
          owner: owner,
          weapon: item,
        ))
          ItemFollowUpAction(item: item, action: action),
    ];

    return ItemEffectResolution(
      owner: owner,
      opponent: opponent,
      followUpItemActions: List<ItemFollowUpAction>.unmodifiable(followUps),
    );
  }

  static ItemEffectResolution _resolveSplinterDartFragilidad({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final resolution = _applyStatusToOpponent(
      owner: owner,
      opponent: opponent,
      status: FragilidadStatus(value: effect.totalValue),
    );
    return ItemEffectResolution(
      owner: resolution.owner,
      opponent: resolution.opponent,
    );
  }

  static ItemEffectResolution _resolveAfterimageMotorRightAngleRepeat({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    if (effect.totalValue <= 0 || previousActions.isEmpty) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final actionToRepeat = previousActions.last;
    return ItemEffectResolution(
      owner: owner,
      opponent: opponent,
      followUpActions: List<ActionEffect>.unmodifiable([
        for (var repeat = 0; repeat < effect.totalValue; repeat++)
          actionToRepeat,
      ]),
    );
  }

  static ItemEffectResolution _resolvePulseStitcherFinisherCleanse({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final actionNumberThisTurn = previousActions.length + 1;
    if (actionNumberThisTurn < 4) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _cleanseDebuffs(owner: owner, maxCount: 1).heal(
        effect.totalValue,
      ),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveVenomMetronomeZigzag({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final shockResolution = _applyConmocionToOpponent(
      owner: owner,
      opponent: opponent,
      amount: effect.totalValue,
    );
    final firstWeapon = _firstPatternWeapon(
      owner: shockResolution.owner,
      pattern: pattern,
    );
    final followUps = firstWeapon == null
        ? const <ItemFollowUpAction>[]
        : <ItemFollowUpAction>[
            for (final action in _attackActionsForFollowUpWeapon(
              owner: shockResolution.owner,
              weapon: firstWeapon,
            ))
              ItemFollowUpAction(item: firstWeapon, action: action),
          ];

    return ItemEffectResolution(
      owner: shockResolution.owner,
      opponent: shockResolution.opponent,
      followUpItemActions: List<ItemFollowUpAction>.unmodifiable(followUps),
    );
  }

  static ItemEffectResolution _resolveLeechwireCoilMiddleContagio({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final contagioResolution = _applyContagioToOpponent(
      owner: owner,
      opponent: opponent,
      amount: effect.totalValue,
    );
    return ItemEffectResolution(
      owner: contagioResolution.owner,
      opponent: contagioResolution.opponent,
    );
  }

  static ItemEffectResolution _resolveThousandCutHaloFinisher({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final debuffCount = _differentDebuffCount(opponent);
    final repeatCount = debuffCount * max(0, effect.totalValue);
    final weakestWeapon = _weakestWeapon(owner);
    if (repeatCount <= 0 || weakestWeapon == null) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final followUps = <ItemFollowUpAction>[
      for (var repeat = 0; repeat < repeatCount; repeat++)
        for (final action in _attackActionsForFollowUpWeapon(
          owner: owner,
          weapon: weakestWeapon,
        ))
          ItemFollowUpAction(item: weakestWeapon, action: action),
    ];

    return ItemEffectResolution(
      owner: owner,
      opponent: opponent,
      followUpItemActions: List<ItemFollowUpAction>.unmodifiable(followUps),
    );
  }

  static ItemEffectResolution _resolveLaCuentaSpendGoldPotencia({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final goldCost = max(0, effect.totalValue);
    if (goldCost <= 0 || !owner.canAfford(goldCost)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final spendResolution = _spendGoldThroughItemEffect(
      owner: owner,
      opponent: opponent,
      amount: goldCost,
      pattern: pattern,
    );
    return ItemEffectResolution(
      owner: _gainPotencia(spendResolution.owner, 1),
      opponent: spendResolution.opponent,
      followUpItemActions: spendResolution.followUpItemActions,
    );
  }

  static ItemEffectResolution _resolveLanzamonedasSpendGoldDamage({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    const goldCost = 2;
    if (!owner.canAfford(goldCost)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final spendResolution = _spendGoldThroughItemEffect(
      owner: owner,
      opponent: opponent,
      amount: goldCost,
      pattern: pattern,
    );
    final trueDamage = max(0, effect.totalValue);
    return ItemEffectResolution(
      owner: spendResolution.owner,
      opponent: trueDamage <= 0
          ? spendResolution.opponent
          : spendResolution.opponent.copyWith(
              health: max(0, spendResolution.opponent.health - trueDamage),
            ),
      followUpItemActions: spendResolution.followUpItemActions,
    );
  }

  static ItemEffectResolution _resolveCashbackBadgeOpeningDiscount({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    return ItemEffectResolution(
      owner: _gainGoldThroughItemEffect(owner, effect.totalValue),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveContrabandCatalogueMixedArchetypeScaling({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    final affinityCount = owner.equippedItems
        .where((item) => item.affinity != ItemArchetypeAffinity.sacer)
        .map((item) => item.affinity)
        .toSet()
        .length;
    return ItemEffectResolution(
      owner: _gainPotencia(owner, affinityCount * effect.value),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveContrabandCatalogueMiddleProfit({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final affinityCount = _usedPatternItems(
      owner: owner,
      pattern: pattern,
    ).map((item) => item.affinity).toSet().length;
    return ItemEffectResolution(
      owner: _gainGoldThroughItemEffect(
        owner,
        affinityCount * effect.totalValue,
      ),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveGoldenGodfatherFinisher({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    final actionTypeCount = previousActions
        .map((action) => action.actionType)
        .where((actionType) => actionType != ItemActionType.none)
        .toSet()
        .length;
    return ItemEffectResolution(
      owner: _gainGoldThroughItemEffect(
        owner,
        actionTypeCount * effect.totalValue,
      ),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveVenomMetronomeRepeatedActionPoison({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    final attackActionCount = owner.itemAttackActionResolvedCountThisTurn;
    if (attackActionCount <= 0 || attackActionCount.isOdd) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final triggerKey = '${effect.effectKey}:$attackActionCount';
    if (owner.itemCombatRoundFlagUseCount(item: item, kind: triggerKey) > 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final poisonResolution = _applyPoisonToOpponent(
      owner: owner.addItemCombatRoundFlagUse(item: item, kind: triggerKey),
      opponent: opponent,
      amount: effect.value,
    );
    return ItemEffectResolution(
      owner: poisonResolution.owner,
      opponent: poisonResolution.opponent,
    );
  }

  static ItemEffectResolution _resolvePulseStitcherComboHeal({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    final interval = max(1, effect.value);
    final actionCount = owner.itemActionResolvedCountThisTurn;
    if (actionCount <= 0 || actionCount % interval != 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final triggerKey = '${effect.effectKey}:$actionCount';
    if (owner.itemCombatRoundFlagUseCount(item: item, kind: triggerKey) > 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.heal(3).addItemCombatRoundFlagUse(
            item: item,
            kind: triggerKey,
          ),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveLeechwireCoilHealFromDebuffs({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    if (status?.type != BattlerStatusType.debuff) {
      return ItemEffectResolution(
        owner: owner,
        opponent: opponent,
        status: status,
      );
    }

    final usesThisTurn = owner.itemCombatRoundFlagUseCount(
      item: item,
      kind: effect.effectKey,
    );
    if (usesThisTurn >= 3) {
      return ItemEffectResolution(
        owner: owner,
        opponent: opponent,
        status: status,
      );
    }

    return ItemEffectResolution(
      owner: owner
          .heal(effect.value)
          .addItemCombatRoundFlagUse(item: item, kind: effect.effectKey),
      opponent: opponent,
      status: status,
    );
  }

  static ItemEffectResolution _resolveBlindspotMantlePuntoCiegoLimit({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    if (owner.itemActionResolvedCountThisTurn < 6) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final usesThisCombat = owner.itemCombatFlagUseCount(
      item: item,
      kind: effect.effectKey,
    );
    if (usesThisCombat >= max(0, effect.value)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner
          .applyStatus(const PuntoCiegoStatus())
          .addItemCombatFlagUse(item: item, kind: effect.effectKey),
      opponent: opponent,
    );
  }

  static ItemEffectResolution _resolveThousandCutHaloActionScaling({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  static ItemEffectResolution _resolveThousandCutHaloStatusEcho({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    if (status?.type != BattlerStatusType.debuff) {
      return ItemEffectResolution(
        owner: owner,
        opponent: opponent,
        status: status,
      );
    }

    final echoSource = _echoDebuffCandidate(
      opponent: opponent,
      incomingStatus: status,
    );
    if (echoSource == null) {
      return ItemEffectResolution(
        owner: owner,
        opponent: opponent,
        status: status,
      );
    }

    final echoStatus = _singleStackOfDebuff(echoSource, effect.value);
    final echoResolution = opponent.applyStatusFromSourceResolved(
      echoStatus,
      source: owner,
      applyEquipmentModifiers: false,
    );
    return ItemEffectResolution(
      owner: echoResolution.source,
      opponent: echoResolution.owner,
      status: status,
    );
  }

  static ItemEffectResolution _resolveAttackResolvedCrossHookEffects({
    required Battler owner,
    required Battler opponent,
    required Item? sourceItem,
    required int damageDealt,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;

    if (sourceItem != null && _burnValue(updatedOwner) > 0) {
      for (final furnace in updatedOwner.equippedItems.where(
        (item) => item.passiveEffects.any(
          (effect) =>
              effect.effectKey == ItemEffectKeys.furnaceHeartAdjacentWeapons,
        ),
      )) {
        if (!_isAdjacentWeapon(
          owner: updatedOwner,
          source: furnace,
          weapon: sourceItem,
        )) {
          continue;
        }
        final burnResolution = _applyBurnToOpponent(
          owner: updatedOwner,
          opponent: updatedOpponent,
          amount: 1,
        );
        updatedOwner = burnResolution.owner;
        updatedOpponent = burnResolution.opponent;
      }
    }

    if (sourceItem != null && sourceItem.isWeaponLike) {
      for (final repeller in updatedOwner.equippedItems) {
        final pendingConmocion = updatedOwner.itemCombatFlagValue(
          item: repeller,
          kind: ItemEffectKeys.repellerOpeningWave,
        );
        if (pendingConmocion == null || pendingConmocion <= 0) continue;

        final shockResolution = _applyConmocionToOpponent(
          owner: updatedOwner,
          opponent: updatedOpponent,
          amount: pendingConmocion,
        );
        updatedOwner = shockResolution.owner.removeItemCombatFlagsFor(
          item: repeller,
          kind: ItemEffectKeys.repellerOpeningWave,
        );
        updatedOpponent = shockResolution.opponent;
        break;
      }
    }

    if (damageDealt > 0) {
      for (final item in updatedOwner.equippedItems.where(
        (item) => item.passiveEffects.any(
          (effect) =>
              effect.effectKey == ItemEffectKeys.bloodflameGauntletBurnRevenge,
        ),
      )) {
        final pendingBurnCount = updatedOwner.itemCombatFlagUseCount(
          item: item,
          kind: ItemEffectKeys.bloodflameGauntletBurnRevenge,
        );
        if (pendingBurnCount <= 0) continue;

        final revengeEffect = item.passiveEffects.firstWhere(
          (effect) =>
              effect.effectKey == ItemEffectKeys.bloodflameGauntletBurnRevenge,
        );
        final burnResolution = _applyBurnToOpponent(
          owner: updatedOwner,
          opponent: updatedOpponent,
          amount: revengeEffect.value * pendingBurnCount,
        );
        updatedOwner = burnResolution.owner.removeItemCombatFlagsFor(
          item: item,
          kind: ItemEffectKeys.bloodflameGauntletBurnRevenge,
        );
        updatedOpponent = burnResolution.opponent;
      }
    }

    return ItemEffectResolution(owner: updatedOwner, opponent: updatedOpponent);
  }

  static ItemEffectResolution _resolvePassiveNoop({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
    required int damageDealt,
    required int damageTaken,
    required DamageKind? damageKind,
    required Item? sourceItem,
    required ActionEffect? action,
    required BattlerStatus? status,
    required BattlePatternMatchContext? pattern,
  }) {
    return ItemEffectResolution(
      owner: owner,
      opponent: opponent,
      status: status,
    );
  }

  static ItemEffectResolution _spendGoldThroughItemEffect({
    required Battler owner,
    required Battler opponent,
    required int amount,
    required BattlePatternMatchContext pattern,
  }) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0 || !owner.canAfford(safeAmount)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    var updatedOwner = owner.spendMoneyForItemEffect(safeAmount);
    final followUps = <ItemFollowUpAction>[];

    for (final cashbackItem in updatedOwner.equippedItems) {
      for (final effect in cashbackItem.passiveEffects.where(
        (effect) => effect.effectKey == ItemEffectKeys.cashbackBadgeRefund,
      )) {
        if (updatedOwner.itemCombatRoundFlagUseCount(
              item: cashbackItem,
              kind: effect.effectKey,
            ) >
            0) {
          continue;
        }
        updatedOwner = _gainGoldThroughItemEffect(updatedOwner, effect.value)
            .addItemCombatRoundFlagUse(
          item: cashbackItem,
          kind: effect.effectKey,
        );
      }
    }

    for (final catalogueItem in updatedOwner.equippedItems) {
      for (final effect in catalogueItem.passiveEffects.where(
        (effect) =>
            effect.effectKey == ItemEffectKeys.contrabandCatalogueGoldSpendEcho,
      )) {
        final weakestItem = _weakestNonSacerPatternItem(
          owner: updatedOwner,
          pattern: pattern,
        );
        if (weakestItem == null) continue;
        final actions = _actionsForFollowUpItem(
          owner: updatedOwner,
          item: weakestItem,
          pattern: pattern,
        );
        for (var repeat = 0; repeat < max(0, effect.value); repeat++) {
          for (final action in actions) {
            followUps
                .add(ItemFollowUpAction(item: weakestItem, action: action));
          }
        }
      }
    }

    return ItemEffectResolution(
      owner: updatedOwner,
      opponent: opponent,
      followUpItemActions: List<ItemFollowUpAction>.unmodifiable(followUps),
    );
  }

  static Battler _gainGoldThroughItemEffect(Battler owner, int amount) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0) return owner;

    var updatedOwner = owner.earnMoneyForItemEffect(safeAmount);
    for (final item in updatedOwner.equippedItems) {
      for (final effect in item.passiveEffects.where(
        (effect) =>
            effect.effectKey == ItemEffectKeys.cashbackBadgeSpendPotencia,
      )) {
        updatedOwner = _gainPotencia(updatedOwner, effect.value);
      }
    }
    return updatedOwner;
  }

  static Battler _gainPotencia(Battler owner, int amount) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0) return owner;

    return owner.applyStatus(PotenciaStatus(value: safeAmount));
  }

  static ({Battler owner, Battler opponent}) _applyBurnToOpponent({
    required Battler owner,
    required Battler opponent,
    required int amount,
  }) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0) return (owner: owner, opponent: opponent);

    final resolution = opponent.applyStatusFromSourceResolved(
      QuemaduraStatus(remainingTurns: safeAmount),
      source: owner,
    );
    return (owner: resolution.source, opponent: resolution.owner);
  }

  static Battler _applyBurnToOwner({
    required Battler owner,
    required Battler opponent,
    required int amount,
  }) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0) return owner;

    return owner
        .applyStatusFromSourceResolved(
          QuemaduraStatus(remainingTurns: safeAmount),
          source: owner,
        )
        .owner;
  }

  static ({Battler owner, Battler opponent}) _applyPoisonToOpponent({
    required Battler owner,
    required Battler opponent,
    required int amount,
  }) {
    return _applyStatusToOpponent(
      owner: owner,
      opponent: opponent,
      status: IntoxicacionStatus(value: amount),
    );
  }

  static ({Battler owner, Battler opponent}) _applyConmocionToOpponent({
    required Battler owner,
    required Battler opponent,
    required int amount,
  }) {
    return _applyStatusToOpponent(
      owner: owner,
      opponent: opponent,
      status: ConmocionStatus(value: amount),
    );
  }

  static ({Battler owner, Battler opponent}) _applyContagioToOpponent({
    required Battler owner,
    required Battler opponent,
    required int amount,
  }) {
    return _applyStatusToOpponent(
      owner: owner,
      opponent: opponent,
      status: ContagioStatus(value: amount),
    );
  }

  static ({Battler owner, Battler opponent}) _applyStatusToOpponent({
    required Battler owner,
    required Battler opponent,
    required BattlerStatus status,
  }) {
    if (status.value <= 0) return (owner: owner, opponent: opponent);

    final resolution = opponent.applyStatusFromSourceResolved(
      status,
      source: owner,
    );
    return (owner: resolution.source, opponent: resolution.owner);
  }

  static ItemEffectResolution _resolveFragilidadAction({
    required Battler owner,
    required Battler opponent,
    required ActionEffect effect,
  }) {
    final resolution = _applyStatusToOpponent(
      owner: owner,
      opponent: opponent,
      status: FragilidadStatus(value: effect.totalValue),
    );
    return ItemEffectResolution(
      owner: resolution.owner,
      opponent: resolution.opponent,
    );
  }

  static Battler _gainPuntoCiegoAndMaybeBlockPoint({
    required Battler owner,
    required Item item,
    required String blockEffectKey,
  }) {
    var updatedOwner = owner.applyStatus(const PuntoCiegoStatus());
    final blockEffect = item.passiveEffects.where(
      (effect) => effect.effectKey == blockEffectKey,
    );
    if (blockEffect.isEmpty) return updatedOwner;

    final threshold = max(1, blockEffect.first.value);
    final previousUses = updatedOwner.itemCombatFlagUseCount(
      item: item,
      kind: blockEffectKey,
    );
    updatedOwner = updatedOwner.addItemCombatFlagUse(
      item: item,
      kind: blockEffectKey,
    );
    if (previousUses + 1 < threshold) return updatedOwner;

    final pointKey = OperativePatternLayoutService.pointKeyForItem(
      player: updatedOwner,
      item: item,
    );
    if (pointKey == null) return updatedOwner;

    return updatedOwner.addCombatBlockedPoints(<String>[pointKey]);
  }

  static int _burnValue(Battler owner) {
    return owner.statusesById(QuemaduraStatus.statusId).fold<int>(
          0,
          (total, status) => total + max(0, status.resolved(owner).value),
        );
  }

  static Battler _consumeBurn(Battler owner, int amount) {
    var remaining = max(0, amount);
    var updatedOwner = owner;
    for (final status in owner.statusesById(QuemaduraStatus.statusId)) {
      if (remaining <= 0) break;
      final resolvedStatus = status.resolved(updatedOwner);
      final currentValue = max(0, resolvedStatus.value);
      if (currentValue <= 0) continue;

      final consumed = min(currentValue, remaining);
      remaining -= consumed;
      final nextValue = currentValue - consumed;
      if (nextValue <= 0) {
        updatedOwner = updatedOwner.removeStatusInstance(status);
      } else {
        updatedOwner = updatedOwner.replaceStatusInstance(
          currentStatus: status,
          replacement: status.copyWith(
            remainingTurns: nextValue,
            value: nextValue,
          ),
        );
      }
    }
    return updatedOwner.pruneExpiredStatuses();
  }

  static Battler _cleanseDebuffs({
    required Battler owner,
    required int maxCount,
  }) {
    final safeCount = max(0, maxCount);
    if (safeCount <= 0) return owner;

    var cleansedCount = 0;
    var updatedOwner = owner;
    for (final status in owner.statuses) {
      if (cleansedCount >= safeCount) break;
      if (status.type != BattlerStatusType.debuff || !status.isPurgeable) {
        continue;
      }
      updatedOwner = updatedOwner.removeStatusInstance(status);
      cleansedCount++;
    }

    if (cleansedCount <= 0) return updatedOwner;
    return _resolveCitadelCleanseRewards(
      owner: updatedOwner,
      cleansedCount: cleansedCount,
    );
  }

  static Battler _resolveCitadelCleanseRewards({
    required Battler owner,
    required int cleansedCount,
  }) {
    var updatedOwner = owner;
    for (final item in owner.equippedItems) {
      for (final effect in item.passiveEffects.where(
        (effect) => effect.effectKey == ItemEffectKeys.citadelCoreCleanseHeal,
      )) {
        final count = max(0, cleansedCount);
        if (count <= 0) continue;
        updatedOwner = updatedOwner
            .heal(effect.value * count)
            .applyStatus(PotenciaStatus(value: count));
      }
    }
    return updatedOwner;
  }

  static Battler _gainCalentando(Battler owner, int amount) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0) return owner;

    final currentStatus = owner.statusById(CalentandoStatus.statusId);
    if (currentStatus is CalentandoStatus) {
      return owner.replaceStatusInstance(
        currentStatus: currentStatus,
        replacement: currentStatus.copyWith(
          value: currentStatus.resolved(owner).value + safeAmount,
        ),
      );
    }
    return owner.applyStatus(CalentandoStatus(value: safeAmount));
  }

  static int _buffStackValue(Battler owner) {
    return owner.statuses.where((status) {
      return status.type == BattlerStatusType.buff;
    }).fold<int>(
      0,
      (total, status) => total + max(1, status.resolved(owner).value),
    );
  }

  static int _differentDebuffCount(Battler owner) {
    return owner.statuses
        .where((status) => status.type == BattlerStatusType.debuff)
        .map((status) => status.id)
        .toSet()
        .length;
  }

  static bool _actionAppliesDebuff(ActionEffect action) {
    return switch (action.customEffectKey) {
      ItemEffectKeys.homemadeFlameBurnBoth ||
      ItemEffectKeys.poisonStingerIntoxicacion ||
      ItemEffectKeys.bugZapperRacketFragilidad ||
      ItemEffectKeys.hazardSprayIntoxicacion ||
      ItemEffectKeys.repellerConmocion ||
      ItemEffectKeys.repellerOpeningWave ||
      ItemEffectKeys.webCannonFragilidad ||
      ItemEffectKeys.electricNetSquareTrap ||
      ItemEffectKeys.campfireBurnAndPuntoCiego ||
      ItemEffectKeys.kindlingAxeBurnBoth ||
      ItemEffectKeys.splinterDartFragilidad ||
      ItemEffectKeys.venotronomeZigzag ||
      ItemEffectKeys.leechwireCoilMiddleContagio =>
        true,
      _ => false,
    };
  }

  static Battler _dealDamageToOpponent({
    required Battler owner,
    required Battler opponent,
    required int damage,
  }) {
    final safeDamage = max(0, damage);
    if (safeDamage <= 0) return opponent;
    return opponent.receiveDirectDamage(safeDamage, source: owner);
  }

  static List<Item> _usedItemsMatching({
    required Battler owner,
    required BattlePatternMatchContext? pattern,
    required bool Function(Item item) matches,
  }) {
    if (pattern == null) return const <Item>[];

    final usedPointKeys = pattern.usedItemPointKeys.toSet();
    final items = <Item>[];
    for (final item in owner.equippedItems) {
      final pointKey = OperativePatternLayoutService.pointKeyForItem(
        player: owner,
        item: item,
      );
      if (pointKey == null || !usedPointKeys.contains(pointKey)) continue;
      if (matches(item)) items.add(item);
    }
    return List<Item>.unmodifiable(items);
  }

  static List<Item> _usedPatternItems({
    required Battler owner,
    required BattlePatternMatchContext pattern,
  }) {
    final items = <Item>[];
    for (final pointKey in pattern.usedItemPointKeys) {
      for (final item in owner.equippedItems) {
        final itemPointKey = OperativePatternLayoutService.pointKeyForItem(
          player: owner,
          item: item,
        );
        if (itemPointKey == pointKey) {
          items.add(item);
          break;
        }
      }
    }
    return List<Item>.unmodifiable(items);
  }

  static Item? _weakestNonSacerPatternItem({
    required Battler owner,
    required BattlePatternMatchContext pattern,
  }) {
    Item? weakest;
    var weakestValue = 0;
    for (final item in _usedPatternItems(owner: owner, pattern: pattern)) {
      if (item.affinity == ItemArchetypeAffinity.sacer) continue;
      final itemValue = _itemActionValue(
        owner: owner,
        item: item,
        pattern: pattern,
      );
      if (itemValue <= 0) continue;
      if (weakest == null || itemValue < weakestValue) {
        weakest = item;
        weakestValue = itemValue;
      }
    }
    return weakest;
  }

  static int _itemActionValue({
    required Battler owner,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    return _actionsForFollowUpItem(
      owner: owner,
      item: item,
      pattern: pattern,
    ).fold<int>(
      0,
      (total, action) => total + action.totalValue,
    );
  }

  static List<Item> _adjacentBarrierItems({
    required Battler owner,
    required Item item,
  }) {
    return owner.equippedItems.where((candidate) {
      return candidate.hasTag(EntityTag.barrera) &&
          _areDirectNeighbors(owner: owner, source: item, target: candidate);
    }).toList(growable: false);
  }

  static List<Item> _adjacentWeaponItems({
    required Battler owner,
    required Item item,
  }) {
    return owner.equippedItems.where((candidate) {
      return _isAdjacentWeapon(
        owner: owner,
        source: item,
        weapon: candidate,
      );
    }).toList(growable: false);
  }

  static Item? _firstPatternWeapon({
    required Battler owner,
    required BattlePatternMatchContext pattern,
  }) {
    for (final pointKey in pattern.usedItemPointKeys) {
      for (final item in owner.equippedItems) {
        if (!item.isWeaponLike) continue;
        final itemPointKey = OperativePatternLayoutService.pointKeyForItem(
          player: owner,
          item: item,
        );
        if (itemPointKey == pointKey) return item;
      }
    }
    return null;
  }

  static Item? _weakestWeapon(Battler owner) {
    Item? weakest;
    var weakestValue = 0;
    for (final item in owner.equippedItems) {
      if (!item.isWeaponLike) continue;
      final attackValue = _weaponAttackValue(owner: owner, weapon: item);
      if (attackValue <= 0) continue;
      if (weakest == null || attackValue < weakestValue) {
        weakest = item;
        weakestValue = attackValue;
      }
    }
    return weakest;
  }

  static int _weaponAttackValue({
    required Battler owner,
    required Item weapon,
  }) {
    return _attackActionsForFollowUpWeapon(
      owner: owner,
      weapon: weapon,
    ).fold<int>(
      0,
      (total, action) => total + action.totalValue,
    );
  }

  static bool _isAdjacentWeapon({
    required Battler owner,
    required Item source,
    required Item weapon,
  }) {
    if (!weapon.isWeaponLike) {
      return false;
    }
    return _areDirectNeighbors(owner: owner, source: source, target: weapon);
  }

  static bool _areDirectNeighbors({
    required Battler owner,
    required Item source,
    required Item target,
  }) {
    if (identical(source, target) || source == target) return false;
    final sourcePointKey = OperativePatternLayoutService.pointKeyForItem(
      player: owner,
      item: source,
    );
    final targetPointKey = OperativePatternLayoutService.pointKeyForItem(
      player: owner,
      item: target,
    );
    if (sourcePointKey == null || targetPointKey == null) return false;

    final sourcePoint = operativePatternPointsByKey[sourcePointKey];
    final targetPoint = operativePatternPointsByKey[targetPointKey];
    if (sourcePoint == null || targetPoint == null) return false;

    return (sourcePoint.x - targetPoint.x).abs() +
            (sourcePoint.y - targetPoint.y).abs() ==
        1;
  }

  static List<ActionEffect> _actionsForFollowUpWeapon({
    required Battler owner,
    required Item weapon,
  }) {
    final boostedWeapon = owner.itemWithCombatActionBonuses(weapon);
    return List<ActionEffect>.unmodifiable(boostedWeapon.actionEffects);
  }

  static List<ActionEffect> _actionsForFollowUpItem({
    required Battler owner,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    final boostedItem = owner.itemWithCombatActionBonuses(item);
    final itemPointKey = OperativePatternLayoutService.pointKeyForItem(
      player: owner,
      item: item,
    );
    OperativePatternPoint? itemPoint;
    if (itemPointKey != null) {
      for (final point in pattern.patternPoints) {
        if (point.key == itemPointKey) {
          itemPoint = point;
          break;
        }
      }
    }

    return List<ActionEffect>.unmodifiable([
      ...boostedItem.actionEffects,
      if (itemPoint != null)
        ...boostedItem
            .matchingPatternEffects(
              patternPoints: pattern.patternPoints,
              itemPoint: itemPoint,
            )
            .map((effect) => effect.actionEffect),
    ]);
  }

  static List<ActionEffect> _attackActionsForFollowUpWeapon({
    required Battler owner,
    required Item weapon,
  }) {
    final boostedWeapon = owner.itemWithCombatActionBonuses(weapon);
    return List<ActionEffect>.unmodifiable(
      boostedWeapon.actionEffects.where(
        (action) => action.actionType == ItemActionType.attack,
      ),
    );
  }

  static BattlerStatus? _echoDebuffCandidate({
    required Battler opponent,
    required BattlerStatus? incomingStatus,
  }) {
    final candidates = opponent.statuses
        .where(
          (status) =>
              status.type == BattlerStatusType.debuff &&
              status.id != incomingStatus?.id,
        )
        .toList(growable: false);
    if (candidates.isEmpty) return null;

    return candidates[Random().nextInt(candidates.length)];
  }

  static BattlerStatus _singleStackOfDebuff(
    BattlerStatus source,
    int amount,
  ) {
    final safeAmount = max(1, amount);
    if (source is QuemaduraStatus) {
      return QuemaduraStatus(remainingTurns: safeAmount);
    }
    if (source is IntoxicacionStatus) {
      return IntoxicacionStatus(value: safeAmount);
    }
    if (source is ContagioStatus) {
      return ContagioStatus(value: safeAmount);
    }
    if (source is FragilidadStatus) {
      return FragilidadStatus(value: safeAmount);
    }
    if (source is ConmocionStatus) {
      return ConmocionStatus(value: safeAmount);
    }
    return source.copyWith(value: safeAmount);
  }

  static String _itemSourceKey({
    required Item item,
    required String effectKey,
  }) {
    return '$effectKey:${item.instanceId ?? item.catalogKey}';
  }
}
