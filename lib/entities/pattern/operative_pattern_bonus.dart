/// Tipo de bonus que puede entregar un punto activado del patron operativo.
enum OperativePatternBonusKind {
  attack,
  barrier,
  health,
}

/// Bonus numerico obtenido al resolver un punto del patron operativo.
///
/// Los servicios agregan estos valores despues de validar posicion, requisito y
/// adyacencias de objetos.
class OperativePatternBonus {
  final OperativePatternBonusKind kind;
  final int amount;

  /// Crea un bonus de [kind] con la cantidad ya resuelta.
  const OperativePatternBonus({
    required this.kind,
    required this.amount,
  });
}
