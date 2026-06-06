part of 'battler.dart';

extension BattlerProgression on Battler {
  /// Suma XP persistente fuera del combate y deja el exceso acumulado para futuros niveles.
  Battler gainExperience(int amount) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0 || isAtMaxLevel) return this;

    return copyWith(experience: experience + safeAmount);
  }

  /// Comprueba si el battler tiene dinero suficiente para pagar una cantidad.
  bool canAfford(int amount) => money >= amount;

  /// Suma dinero sin permitir cantidades negativas.
  Battler earnMoney(int amount) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0) return this;

    final previousMoney = money;
    return copyWith(money: money + safeAmount)
        ._applyCreditGainItemEffects(safeAmount)
        ._applyCreditGainAbilityEffects(previousMoney: previousMoney);
  }

  /// Resta dinero sin permitir que el total baje de cero.
  Battler spendMoney(int amount) => _spendMoney(amount);

  /// Resta dinero causado por un efecto de item.
  Battler spendMoneyForItemEffect(int amount) {
    return _spendMoney(amount, applyItemPaymentAbilities: true);
  }

  /// Aplica el pago real y dispara los efectos que reaccionan a gastar creditos.
  ///
  /// La cantidad pagada se limita al dinero disponible para que reembolsos y
  /// umbrales usen lo que realmente salio de la cartera, no el coste pedido.
  Battler _spendMoney(
    int amount, {
    bool applyItemPaymentAbilities = false,
  }) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0) return this;

    final paidAmount = min(money, safeAmount);
    var updatedBattler = copyWith(money: max(0, money - safeAmount));
    if (paidAmount <= 0) return updatedBattler;

    if (updatedBattler.combatFlags.contains(Battler.combatActiveFlag)) {
      updatedBattler = updatedBattler.addCombatFlag(
        const CombatRuntimeFlag.battler(
          BattlerCombatFlag.creditsSpentThisCombat,
        ),
      );
    }

    updatedBattler = updatedBattler._applyCreditSpendItemEffects(paidAmount);
    if (applyItemPaymentAbilities) {
      updatedBattler =
          updatedBattler._applyCreditSpendAbilityEffects(paidAmount);
    }
    return updatedBattler;
  }

  /// Consume una subida de nivel pendiente, aplica la mejora base y la recompensa elegida.
  Battler applyLevelReward(BattlerLevelRewardChoice reward) {
    if (!canLevelUp) return this;

    final requiredExperience = experienceToNextLevel;
    final nextLevel = min(Battler.maximumLevel, level + 1);
    final equipmentCapacityGain =
        Battler.evenLevelProgressionBonusFor(nextLevel) -
            Battler.evenLevelProgressionBonusFor(level);
    final updatedBaseStats = Map<BattlerStat, int>.from(baseStats);
    var attackGain = 1;
    const barrierGain = 1;
    var healthGain = 5;
    var incomeGain = 0;

    final statReward = reward.statReward;
    if (statReward != null) {
      switch (statReward) {
        case BattlerLevelReward.income:
          incomeGain = 1;
          break;
        case BattlerLevelReward.attack:
          attackGain += 1;
          break;
        case BattlerLevelReward.health:
          healthGain += 5;
          break;
      }
    }

    updatedBaseStats[BattlerStat.attack] =
        max(0, (updatedBaseStats[BattlerStat.attack] ?? 0) + attackGain);
    updatedBaseStats[BattlerStat.barrier] =
        max(0, (updatedBaseStats[BattlerStat.barrier] ?? 0) + barrierGain);
    updatedBaseStats[BattlerStat.health] =
        max(0, (updatedBaseStats[BattlerStat.health] ?? 0) + healthGain);

    final remainingExperience = nextLevel >= Battler.maximumLevel
        ? 0
        : max(0, experience - requiredExperience);

    var updatedPlayer = copyWith(
      health: health + healthGain,
      income: baseIncome + incomeGain,
      equipmentCapacity: equipmentCapacity + equipmentCapacityGain,
      level: nextLevel,
      experience: remainingExperience,
      baseStats: Map<BattlerStat, int>.unmodifiable(updatedBaseStats),
    );

    final abilityReward = reward.ability;
    if (abilityReward != null) {
      updatedPlayer =
          updatedPlayer.addAbility(abilityReward.toRuntimeInstance());
    }

    final itemReward = reward.item;
    if (itemReward != null) {
      updatedPlayer = updatedPlayer.addItem(itemReward);
    }

    return updatedPlayer;
  }

  /// Dispara efectos de items que reaccionan cuando el jugador gana creditos.
  Battler _applyCreditGainItemEffects(int amount) {
    if (amount <= 0 || equippedItems.isEmpty) return this;

    var updatedBattler = this;
    for (final item in equippedItems) {
      if (item.id != ItemId.selloMercante) continue;
      updatedBattler = updatedBattler.heal(max(1, item.value));
    }
    return updatedBattler;
  }

  /// Dispara habilidades que reaccionan al cruzar umbrales de creditos ganados.
  ///
  /// Actualmente `franquiciaTotal` se activa una sola vez por combate al llegar
  /// a 20 creditos y mejora el item mercante equipado de menor rareza.
  Battler _applyCreditGainAbilityEffects({required int previousMoney}) {
    if (!combatFlags.contains(Battler.combatActiveFlag) ||
        previousMoney >= 20 ||
        money < 20 ||
        hasCombatFlag(
          const CombatRuntimeFlag.battler(
            BattlerCombatFlag.franquiciaTotalTriggered,
          ),
        ) ||
        abilityById(BattlerAbilityId.franquiciaTotal) == null) {
      return this;
    }

    final mercanteItems = equippedItems
        .where(
          (item) => item.hasArchetypeAffinity(ItemArchetypeAffinity.mercante),
        )
        .toList(growable: false);
    if (mercanteItems.isEmpty) return this;

    final selected = mercanteItems.reduce((best, item) {
      if (item.rarity.index != best.rarity.index) {
        return item.rarity.index < best.rarity.index ? item : best;
      }
      final bestIndex = equippedItems.indexOf(best);
      final itemIndex = equippedItems.indexOf(item);
      return itemIndex < bestIndex ? item : best;
    });

    return _replaceEquippedItemForCreditAbility(
      currentItem: selected,
      replacement: _boostItemForCreditAbility(item: selected, amount: 1),
    ).addCombatFlag(
      const CombatRuntimeFlag.battler(
        BattlerCombatFlag.franquiciaTotalTriggered,
      ),
    );
  }

  /// Dispara habilidades que reaccionan a pagos de creditos hechos por items.
  Battler _applyCreditSpendAbilityEffects(int paidAmount) {
    if (paidAmount <= 0 ||
        !combatFlags.contains(Battler.combatActiveFlag) ||
        money >= 10) {
      return this;
    }

    final ability = abilityById(BattlerAbilityId.comisionRiesgo);
    if (ability == null) return this;

    return applyStatus(
      PotenciaStatus(value: max(1, ability.currentValue)),
      applyEquipmentModifiers: false,
    );
  }

  /// Dispara items equipados que reaccionan cuando se gastan creditos.
  ///
  /// Cada item conserva sus propios limites mediante flags de combate para que
  /// multiples copias no compartan accidentalmente usos.
  Battler _applyCreditSpendItemEffects(int paidAmount) {
    if (paidAmount <= 0 ||
        equippedItems.isEmpty ||
        !combatFlags.contains(Battler.combatActiveFlag)) {
      return this;
    }

    var updatedBattler = this;
    for (final item in equippedItems) {
      switch (item.id) {
        case ItemId.laCuenta:
          final uses = updatedBattler.itemCombatFlagUseCount(
            item: item,
            kind: ItemCombatFlagKind.laCuentaSpendTriggered,
          );
          if (uses >= max(1, item.value)) break;
          updatedBattler = updatedBattler
              .addItemCombatFlagUse(
                item: item,
                kind: ItemCombatFlagKind.laCuentaSpendTriggered,
              )
              .addItemCombatFlagUse(
                item: item,
                kind: ItemCombatFlagKind.laCuentaPendingAttackBonus,
              );
          break;
        case ItemId.bolsoR33m:
          final uses = updatedBattler.itemCombatFlagUseCount(
            item: item,
            kind: ItemCombatFlagKind.bolsoR33mRefundedSpend,
          );
          if (uses >= max(1, item.value)) break;
          updatedBattler = updatedBattler
              .addItemCombatFlagUse(
                item: item,
                kind: ItemCombatFlagKind.bolsoR33mRefundedSpend,
              )
              .copyWith(money: updatedBattler.money + paidAmount)
              ._applyCreditGainItemEffects(paidAmount);
          break;
        default:
          break;
      }
    }
    return updatedBattler;
  }

  /// Reemplaza una instancia equipada conservando la posicion visual del equipo.
  Battler _replaceEquippedItemForCreditAbility({
    required Item currentItem,
    required Item replacement,
  }) {
    final equippedIndex = equippedItems.indexOf(currentItem);
    if (equippedIndex < 0) return this;

    final updatedEquippedItems = List<Item>.from(equippedItems);
    updatedEquippedItems[equippedIndex] = replacement;
    return copyWith(
      equippedItems: List<Item>.unmodifiable(updatedEquippedItems),
    );
  }

  /// Aplica la mejora temporal que `franquiciaTotal` concede a un item mercante.
  ///
  /// El aumento se marca como aura de combate para que pueda limpiarse al salir
  /// del encuentro sin tocar mejoras permanentes del objeto.
  Item _boostItemForCreditAbility({
    required Item item,
    required int amount,
  }) {
    final statModifiers = Map<BattlerStat, int>.from(item.statModifiers);
    for (final entry in item.statModifiers.entries) {
      if (entry.value <= 0) continue;
      statModifiers[entry.key] = entry.value + amount;
    }

    final adjacencyBonuses = item.patternAdjacencyBonuses
        .map(
          (bonus) => OperativePatternAdjacencyBonus(
            direction: bonus.direction,
            requiredTag: bonus.requiredTag,
            kind: bonus.kind,
            amount: bonus.amount + amount,
          ),
        )
        .toList(growable: false);

    return item.copyWith(
      value: item.effect != null && item.value > 0 ? item.value + amount : null,
      statModifiers: statModifiers,
      patternBonusAmountOverride:
          item.hasPatternBonus ? item.patternBonusAmount + amount : null,
      patternAdjacencyBonuses: adjacencyBonuses,
      hasPatternAura: true,
      combatItemBonusBoost: item.combatItemBonusBoost + amount,
    );
  }
}
