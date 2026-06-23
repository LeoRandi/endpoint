import '../entity_tag.dart';
import 'operative_pattern_bonus.dart';

/// Direccion cardinal que debe ocupar el item vecino para activar un bonus.
enum OperativePatternAdjacencyDirection {
  north(dx: 0, dy: 1),
  east(dx: 1, dy: 0),
  south(dx: 0, dy: -1),
  west(dx: -1, dy: 0);

  final int dx;
  final int dy;

  /// Crea una direccion con su desplazamiento logico de grilla.
  const OperativePatternAdjacencyDirection({
    required this.dx,
    required this.dy,
  });
}

/// Regla de bonus por adyacencia entre dos items del patron operativo.
///
/// Si el item situado en [direction] desde el item actual tiene [requiredTag],
/// se concede un [bonus] del tipo y cantidad configurados.
class OperativePatternAdjacencyBonus {
  final OperativePatternAdjacencyDirection direction;
  final EntityTag requiredTag;
  final OperativePatternBonusKind kind;
  final int amount;

  /// Crea una regla de adyacencia con campos nombrados para configuraciones UI.
  const OperativePatternAdjacencyBonus({
    required this.direction,
    required this.requiredTag,
    required this.kind,
    required this.amount,
  });

  /// Crea una regla compacta usada por presets grandes de items.
  const OperativePatternAdjacencyBonus.match(
    this.direction,
    this.requiredTag,
    this.kind,
    this.amount,
  );

  /// Materializa la regla como bonus operativo una vez validada la adyacencia.
  OperativePatternBonus get bonus => OperativePatternBonus(
        kind: kind,
        amount: amount,
      );
}
