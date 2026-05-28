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

    return copyWith(money: money + safeAmount)
        ._applyCreditGainItemEffects(safeAmount);
  }

  /// Resta dinero sin permitir que el total baje de cero.
  Battler spendMoney(int amount) {
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

    return updatedBattler._applyCreditSpendItemEffects(paidAmount);
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
      updatedPlayer = updatedPlayer.addAbility(abilityReward.resetState());
    }

    final itemReward = reward.item;
    if (itemReward != null) {
      updatedPlayer = updatedPlayer.addItem(itemReward);
    }

    return updatedPlayer;
  }

  Battler _applyCreditGainItemEffects(int amount) {
    if (amount <= 0 || equippedItems.isEmpty) return this;

    var updatedBattler = this;
    for (final item in equippedItems) {
      if (item.id != ItemId.selloMercante) continue;
      updatedBattler = updatedBattler.heal(max(1, item.value));
    }
    return updatedBattler;
  }

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
}
