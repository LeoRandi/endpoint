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

    return copyWith(money: money + safeAmount);
  }

  /// Suma dinero causado por un efecto de item.
  Battler earnMoneyForItemEffect(int amount) => earnMoney(amount);

  /// Resta dinero sin permitir que el total baje de cero.
  Battler spendMoney(int amount) => _spendMoney(amount);

  /// Resta dinero causado por un efecto de item.
  Battler spendMoneyForItemEffect(int amount) => _spendMoney(amount);

  /// Aplica el pago real y dispara los efectos que reaccionan a gastar creditos.
  ///
  /// La cantidad pagada se limita al dinero disponible para que reembolsos y
  /// umbrales usen lo que realmente salio de la cartera, no el coste pedido.
  Battler _spendMoney(int amount) {
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

    final augmentReward = reward.augment;
    if (augmentReward != null) {
      updatedPlayer = updatedPlayer.addAugment(augmentReward);
    }

    final itemReward = reward.item;
    if (itemReward != null) {
      updatedPlayer = updatedPlayer.addItem(itemReward);
    }

    return updatedPlayer;
  }

}
