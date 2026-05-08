enum OperativePatternBonusKind {
  attack,
  barrier,
}

class OperativePatternBonus {
  final OperativePatternBonusKind kind;
  final int amount;

  const OperativePatternBonus({
    required this.kind,
    required this.amount,
  });
}
