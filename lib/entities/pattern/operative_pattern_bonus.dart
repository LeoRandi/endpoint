enum OperativePatternBonusKind {
  attack,
  barrier,
  health,
}

class OperativePatternBonus {
  final OperativePatternBonusKind kind;
  final int amount;

  const OperativePatternBonus({
    required this.kind,
    required this.amount,
  });
}
