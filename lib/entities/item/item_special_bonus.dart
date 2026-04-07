/// Enumera las formas geometricas que pueden asociarse al bonus especial de un item.
enum ItemBonusShape {
  triangle,
  square,
  circle,
}

/// Expone el texto visible de cada forma para UI y depuracion.
extension ItemBonusShapePresentation on ItemBonusShape {
  String get label {
    switch (this) {
      case ItemBonusShape.triangle:
        return 'Triangulo';
      case ItemBonusShape.square:
        return 'Cuadrado';
      case ItemBonusShape.circle:
        return 'Circulo';
    }
  }
}

/// Identifica el efecto base que describe el bonus especial ligado a una forma.
enum ItemSpecialBonusKind {
  attack,
  barrierOnTurnEnd,
  heal,
}

/// Describe el bonus especial teorico de un item sin aplicarlo todavia al combate.
class ItemSpecialBonus {
  static const ItemSpecialBonus triangleAttack = ItemSpecialBonus._(
    shape: ItemBonusShape.triangle,
    kind: ItemSpecialBonusKind.attack,
    amount: 1,
  );
  static const ItemSpecialBonus squareBarrierOnTurnEnd = ItemSpecialBonus._(
    shape: ItemBonusShape.square,
    kind: ItemSpecialBonusKind.barrierOnTurnEnd,
    amount: 1,
  );
  static const ItemSpecialBonus circleHeal = ItemSpecialBonus._(
    shape: ItemBonusShape.circle,
    kind: ItemSpecialBonusKind.heal,
    amount: 3,
  );

  final ItemBonusShape shape;
  final ItemSpecialBonusKind kind;
  final int amount;

  /// Construye una descripcion inmutable del bonus especial asociado a una forma.
  const ItemSpecialBonus._({
    required this.shape,
    required this.kind,
    required this.amount,
  });

  /// Resuelve el bonus canonico asociado a cada forma geometrica.
  static ItemSpecialBonus forShape(ItemBonusShape shape) {
    switch (shape) {
      case ItemBonusShape.triangle:
        return triangleAttack;
      case ItemBonusShape.square:
        return squareBarrierOnTurnEnd;
      case ItemBonusShape.circle:
        return circleHeal;
    }
  }

  /// Devuelve un texto compacto del bonus previsto para futuras integraciones.
  String get description {
    switch (kind) {
      case ItemSpecialBonusKind.attack:
        return '+$amount ATK';
      case ItemSpecialBonusKind.barrierOnTurnEnd:
        return '+$amount Barrera al final del turno';
      case ItemSpecialBonusKind.heal:
        return 'Curacion de $amount HP';
    }
  }
}
