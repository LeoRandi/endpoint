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
    return copyWith(money: money + max(0, amount));
  }

  /// Resta dinero sin permitir que el total baje de cero.
  Battler spendMoney(int amount) {
    final safeAmount = max(0, amount);
    return copyWith(money: max(0, money - safeAmount));
  }

  /// Consume una subida de nivel pendiente, aplica la mejora base y la recompensa elegida.
  Battler applyLevelReward(BattlerLevelRewardChoice reward) {
    if (!canLevelUp) return this;

    final requiredExperience = experienceToNextLevel;
    final nextLevel = min(Battler.maximumLevel, level + 1);
    final updatedBaseStats = Map<BattlerStat, int>.from(baseStats);
    var attackGain = 1;
    var healthGain = 10;
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
          healthGain += 10;
          break;
      }
    }

    updatedBaseStats[BattlerStat.attack] =
        max(0, (updatedBaseStats[BattlerStat.attack] ?? 0) + attackGain);
    updatedBaseStats[BattlerStat.health] =
        max(0, (updatedBaseStats[BattlerStat.health] ?? 0) + healthGain);

    final remainingExperience = nextLevel >= Battler.maximumLevel
        ? 0
        : max(0, experience - requiredExperience);

    var updatedPlayer = copyWith(
      health: health + healthGain,
      income: baseIncome + incomeGain,
      equipmentCapacity: equipmentCapacity + 1,
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
}
