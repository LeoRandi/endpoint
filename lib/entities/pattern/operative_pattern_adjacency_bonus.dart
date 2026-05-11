import '../entity_tag.dart';
import 'operative_pattern_bonus.dart';

enum OperativePatternAdjacencyDirection {
  north(dx: 0, dy: 1, label: 'Norte', shortLabel: 'N'),
  east(dx: 1, dy: 0, label: 'Este', shortLabel: 'E'),
  south(dx: 0, dy: -1, label: 'Sur', shortLabel: 'S'),
  west(dx: -1, dy: 0, label: 'Oeste', shortLabel: 'O');

  final int dx;
  final int dy;
  final String label;
  final String shortLabel;

  const OperativePatternAdjacencyDirection({
    required this.dx,
    required this.dy,
    required this.label,
    required this.shortLabel,
  });
}

class OperativePatternAdjacencyBonus {
  final OperativePatternAdjacencyDirection direction;
  final EntityTag requiredTag;
  final OperativePatternBonusKind kind;
  final int amount;

  const OperativePatternAdjacencyBonus({
    required this.direction,
    required this.requiredTag,
    required this.kind,
    required this.amount,
  });

  const OperativePatternAdjacencyBonus.match(
    this.direction,
    this.requiredTag,
    this.kind,
    this.amount,
  );

  OperativePatternBonus get bonus => OperativePatternBonus(
        kind: kind,
        amount: amount,
      );
}
