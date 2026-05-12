class BattleActionBonus {
  final int attackBonus;
  final int healAmount;
  final int immediateBarrierAmount;
  final int endTurnBarrierAmount;

  const BattleActionBonus({
    this.attackBonus = 0,
    this.healAmount = 0,
    this.immediateBarrierAmount = 0,
    this.endTurnBarrierAmount = 0,
  });

  static const BattleActionBonus empty = BattleActionBonus();

  bool get hasAnyBonus =>
      attackBonus > 0 ||
      healAmount > 0 ||
      immediateBarrierAmount > 0 ||
      endTurnBarrierAmount > 0;
}
