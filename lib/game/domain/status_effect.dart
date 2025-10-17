enum StatusKind { buff, debuff, poison, stun }

class StatusEffect {
  final String id;
  final StatusKind kind;
  int remainingTurns;
  StatusEffect({required this.id, required this.kind, required this.remainingTurns});
}
