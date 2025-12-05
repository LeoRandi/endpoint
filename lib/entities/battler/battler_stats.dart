enum BattlerStatsType {
  defense,
  magicDefense,
  dodge,
  magicDodge,
  health,
  mana,
  strength,
  magic,
  sword,
  spear,
  axe,
  dagger,
  unarmed,
  shield,
  bow,
  speed,
  luck,
}

class BattlerStats {
  Map<BattlerStatsType, int> rawStats = {};
  Map<BattlerStatsType, int> get calculatedStats {
    // In the future, we can add equipment and buff calculations here
    return rawStats;
  }

  BattlerStats({
    required this.rawStats,
  });
}