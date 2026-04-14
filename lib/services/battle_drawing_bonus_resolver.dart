import '_imports.dart';

enum BattleDrawingShape {
  triangle,
  square,
  circle,
  scissors,
}

extension BattleDrawingShapePresentation on BattleDrawingShape {
  String get label {
    switch (this) {
      case BattleDrawingShape.triangle:
        return 'Triangulo';
      case BattleDrawingShape.square:
        return 'Cuadrado';
      case BattleDrawingShape.circle:
        return 'Circulo';
      case BattleDrawingShape.scissors:
        return 'Tijera';
    }
  }

  ItemBonusShape? get itemBonusShape {
    switch (this) {
      case BattleDrawingShape.triangle:
        return ItemBonusShape.triangle;
      case BattleDrawingShape.square:
        return ItemBonusShape.square;
      case BattleDrawingShape.circle:
        return ItemBonusShape.circle;
      case BattleDrawingShape.scissors:
        return null;
    }
  }
}

extension ItemBonusShapeBattleDrawingShape on ItemBonusShape {
  BattleDrawingShape get battleDrawingShape {
    switch (this) {
      case ItemBonusShape.triangle:
        return BattleDrawingShape.triangle;
      case ItemBonusShape.square:
        return BattleDrawingShape.square;
      case ItemBonusShape.circle:
        return BattleDrawingShape.circle;
    }
  }
}

enum BattleDrawingEnemyNuisanceKind {
  directDamage,
  barrierTransfer,
  healthTransfer,
  buffTransfer,
}

class BattleDrawingEnemyNuisance {
  final BattleDrawingShape requiredShape;
  final BattleDrawingEnemyNuisanceKind kind;
  final int amount;

  const BattleDrawingEnemyNuisance({
    required this.requiredShape,
    required this.kind,
    this.amount = 0,
  }) : assert(amount >= 0);

  String get pendingDescription {
    switch (kind) {
      case BattleDrawingEnemyNuisanceKind.directDamage:
        return 'Recibes $amount de dano.';
      case BattleDrawingEnemyNuisanceKind.barrierTransfer:
        return 'Transfieres $amount de Barrera al enemigo.';
      case BattleDrawingEnemyNuisanceKind.healthTransfer:
        return 'Transfieres $amount de Vida al enemigo.';
      case BattleDrawingEnemyNuisanceKind.buffTransfer:
        return 'Transfieres tus buffs al enemigo.';
    }
  }

  String get failureLabel {
    switch (kind) {
      case BattleDrawingEnemyNuisanceKind.directDamage:
        return '-$amount HP';
      case BattleDrawingEnemyNuisanceKind.barrierTransfer:
        return '-$amount BAR => ENEMIGO';
      case BattleDrawingEnemyNuisanceKind.healthTransfer:
        return '-$amount HP => ENEMIGO';
      case BattleDrawingEnemyNuisanceKind.buffTransfer:
        return 'BUFFS => ENEMIGO';
    }
  }
}

class BattleDrawingEnemyNuisancePlanner {
  const BattleDrawingEnemyNuisancePlanner();

  List<BattleDrawingEnemyNuisance> build({
    required Battler player,
    required Battler enemy,
  }) {
    if (enemy.equippedItems.isEmpty) {
      return const <BattleDrawingEnemyNuisance>[];
    }

    final enemyAttack = max(1, enemy.calculateDamageAgainst(player));
    final barrierTransferAmount = max(1, (enemyAttack * 0.75).round());
    final healthTransferAmount = max(1, (enemyAttack * 0.8).round());
    final nuisances = enemy.equippedItems
        .map(
          (item) => _nuisanceFromEnemyItem(
            item: item,
            enemyAttack: enemyAttack,
            barrierTransferAmount: barrierTransferAmount,
            healthTransferAmount: healthTransferAmount,
          ),
        )
        .toList(growable: false);

    return List<BattleDrawingEnemyNuisance>.unmodifiable(
      nuisances,
    );
  }

  BattleDrawingEnemyNuisance _nuisanceFromEnemyItem({
    required Item item,
    required int enemyAttack,
    required int barrierTransferAmount,
    required int healthTransferAmount,
  }) {
    switch (item.bonusShape) {
      case ItemBonusShape.triangle:
        return BattleDrawingEnemyNuisance(
          requiredShape: BattleDrawingShape.triangle,
          kind: BattleDrawingEnemyNuisanceKind.directDamage,
          amount: enemyAttack,
        );
      case ItemBonusShape.square:
        return BattleDrawingEnemyNuisance(
          requiredShape: BattleDrawingShape.square,
          kind: BattleDrawingEnemyNuisanceKind.barrierTransfer,
          amount: barrierTransferAmount,
        );
      case ItemBonusShape.circle:
        return BattleDrawingEnemyNuisance(
          requiredShape: BattleDrawingShape.circle,
          kind: BattleDrawingEnemyNuisanceKind.healthTransfer,
          amount: healthTransferAmount,
        );
    }
  }
}

class BattleAttackDrawingPenalty {
  final int directDamage;
  final int barrierTransferAmount;
  final int healthTransferAmount;
  final bool transferBuffs;

  const BattleAttackDrawingPenalty({
    this.directDamage = 0,
    this.barrierTransferAmount = 0,
    this.healthTransferAmount = 0,
    this.transferBuffs = false,
  });

  static const BattleAttackDrawingPenalty empty = BattleAttackDrawingPenalty();

  bool get hasAnyPenalty =>
      directDamage > 0 ||
      barrierTransferAmount > 0 ||
      healthTransferAmount > 0 ||
      transferBuffs;
}

class BattleDrawingEnemyNuisanceResolution {
  final List<BattleDrawingEnemyNuisance> nuisances;
  final List<BattleDrawingEnemyNuisance> resolvedNuisances;
  final List<BattleDrawingEnemyNuisance> triggeredNuisances;
  final Map<BattleDrawingShape, int> consumedCounts;
  final Map<BattleDrawingShape, int> remainingCounts;
  final BattleAttackDrawingPenalty penalty;

  const BattleDrawingEnemyNuisanceResolution({
    this.nuisances = const <BattleDrawingEnemyNuisance>[],
    this.resolvedNuisances = const <BattleDrawingEnemyNuisance>[],
    this.triggeredNuisances = const <BattleDrawingEnemyNuisance>[],
    this.consumedCounts = const <BattleDrawingShape, int>{},
    this.remainingCounts = const <BattleDrawingShape, int>{},
    this.penalty = BattleAttackDrawingPenalty.empty,
  });

  bool get hasNuisances => nuisances.isNotEmpty;
  bool get hasTriggeredNuisances => triggeredNuisances.isNotEmpty;

  bool isResolved(BattleDrawingEnemyNuisance nuisance) {
    return resolvedNuisances.any(
      (candidate) => _matchesNuisance(candidate, nuisance),
    );
  }

  static bool _matchesNuisance(
    BattleDrawingEnemyNuisance first,
    BattleDrawingEnemyNuisance second,
  ) {
    return first.requiredShape == second.requiredShape &&
        first.kind == second.kind &&
        first.amount == second.amount;
  }
}

class BattleAttackDrawingBonus {
  final int attackBonus;
  final int healAmount;
  final int endTurnBarrierAmount;

  const BattleAttackDrawingBonus({
    this.attackBonus = 0,
    this.healAmount = 0,
    this.endTurnBarrierAmount = 0,
  });

  static const BattleAttackDrawingBonus empty = BattleAttackDrawingBonus();

  bool get hasAnyBonus =>
      attackBonus > 0 || healAmount > 0 || endTurnBarrierAmount > 0;
}

class BattleDrawingBonusResolution {
  final BattleAttackDrawingBonus bonus;
  final BattleAttackDrawingPenalty penalty;
  final List<Item> activatedItems;
  final Map<ItemBonusShape, int> recognizedCounts;
  final Map<BattleDrawingShape, int> recognizedShapeCounts;
  final Map<ItemBonusShape, int> remainingCountsAfterNuisances;
  final BattleDrawingEnemyNuisanceResolution enemyNuisanceResolution;

  const BattleDrawingBonusResolution({
    this.bonus = BattleAttackDrawingBonus.empty,
    this.penalty = BattleAttackDrawingPenalty.empty,
    this.activatedItems = const <Item>[],
    this.recognizedCounts = const <ItemBonusShape, int>{},
    this.recognizedShapeCounts = const <BattleDrawingShape, int>{},
    this.remainingCountsAfterNuisances = const <ItemBonusShape, int>{},
    this.enemyNuisanceResolution = const BattleDrawingEnemyNuisanceResolution(),
  });

  bool get hasActivatedItems => activatedItems.isNotEmpty;
  bool get hasTriggeredNuisances =>
      enemyNuisanceResolution.hasTriggeredNuisances;
  bool get hasEnemyNuisances => enemyNuisanceResolution.hasNuisances;

  bool isItemActivated(Item item) {
    return activatedItems.any(
      (candidate) => _matchesOwnedItem(candidate, item),
    );
  }

  static bool _matchesOwnedItem(Item first, Item second) {
    final firstInstanceId = first.instanceId;
    final secondInstanceId = second.instanceId;
    if (firstInstanceId != null &&
        secondInstanceId != null &&
        firstInstanceId == secondInstanceId) {
      return true;
    }

    return identical(first, second) || first.id == second.id;
  }
}

class BattleDrawingBonusResolver {
  const BattleDrawingBonusResolver();

  BattleDrawingBonusResolution resolve({
    required List<Item> equippedItems,
    required Map<ItemBonusShape, int> recognizedCounts,
    List<BattleDrawingEnemyNuisance> enemyNuisances =
        const <BattleDrawingEnemyNuisance>[],
    Map<BattleDrawingShape, int>? recognizedShapeCounts,
  }) {
    final normalizedRecognizedCounts = _normalizeItemCounts(recognizedCounts);
    final normalizedShapeCounts = _normalizeShapeCounts(
      recognizedShapeCounts ??
          _shapeCountsFromItemCounts(
            normalizedRecognizedCounts,
          ),
    );
    final enemyNuisanceResolution = _resolveEnemyNuisances(
      nuisances: enemyNuisances,
      recognizedShapeCounts: normalizedShapeCounts,
    );
    final remainingCounts = _remainingItemCountsFromShapeCounts(
      enemyNuisanceResolution.remainingCounts,
    );

    final activatedItems = <Item>[];
    var attackBonus = 0;
    var healAmount = 0;
    var endTurnBarrierAmount = 0;

    for (final item in equippedItems) {
      final shape = item.bonusShape;
      final remaining = remainingCounts[shape] ?? 0;
      if (remaining <= 0) continue;

      activatedItems.add(item);
      remainingCounts[shape] = remaining - 1;
      final specialBonus = item.specialBonus;
      switch (specialBonus.kind) {
        case ItemSpecialBonusKind.attack:
          attackBonus += specialBonus.amount;
          break;
        case ItemSpecialBonusKind.barrierOnTurnEnd:
          endTurnBarrierAmount += specialBonus.amount;
          break;
        case ItemSpecialBonusKind.heal:
          healAmount += specialBonus.amount;
          break;
      }
    }

    return BattleDrawingBonusResolution(
      bonus: BattleAttackDrawingBonus(
        attackBonus: attackBonus,
        healAmount: healAmount,
        endTurnBarrierAmount: endTurnBarrierAmount,
      ),
      penalty: enemyNuisanceResolution.penalty,
      activatedItems: List<Item>.unmodifiable(activatedItems),
      recognizedCounts: Map<ItemBonusShape, int>.unmodifiable(
        normalizedRecognizedCounts,
      ),
      recognizedShapeCounts: Map<BattleDrawingShape, int>.unmodifiable(
        normalizedShapeCounts,
      ),
      remainingCountsAfterNuisances: Map<ItemBonusShape, int>.unmodifiable(
        remainingCounts,
      ),
      enemyNuisanceResolution: enemyNuisanceResolution,
    );
  }

  Map<ItemBonusShape, int> _normalizeItemCounts(
    Map<ItemBonusShape, int> source,
  ) {
    return <ItemBonusShape, int>{
      for (final shape in ItemBonusShape.values)
        shape: (source[shape] ?? 0).clamp(0, 9999).toInt(),
    };
  }

  Map<BattleDrawingShape, int> _shapeCountsFromItemCounts(
    Map<ItemBonusShape, int> itemCounts,
  ) {
    return <BattleDrawingShape, int>{
      BattleDrawingShape.triangle:
          (itemCounts[ItemBonusShape.triangle] ?? 0).clamp(0, 9999).toInt(),
      BattleDrawingShape.square:
          (itemCounts[ItemBonusShape.square] ?? 0).clamp(0, 9999).toInt(),
      BattleDrawingShape.circle:
          (itemCounts[ItemBonusShape.circle] ?? 0).clamp(0, 9999).toInt(),
      BattleDrawingShape.scissors: 0,
    };
  }

  Map<BattleDrawingShape, int> _normalizeShapeCounts(
    Map<BattleDrawingShape, int> source,
  ) {
    return <BattleDrawingShape, int>{
      for (final shape in BattleDrawingShape.values)
        shape: (source[shape] ?? 0).clamp(0, 9999).toInt(),
    };
  }

  Map<ItemBonusShape, int> _remainingItemCountsFromShapeCounts(
    Map<BattleDrawingShape, int> shapeCounts,
  ) {
    return <ItemBonusShape, int>{
      for (final shape in ItemBonusShape.values)
        shape:
            (shapeCounts[shape.battleDrawingShape] ?? 0).clamp(0, 9999).toInt(),
    };
  }

  BattleDrawingEnemyNuisanceResolution _resolveEnemyNuisances({
    required List<BattleDrawingEnemyNuisance> nuisances,
    required Map<BattleDrawingShape, int> recognizedShapeCounts,
  }) {
    final remainingCounts = <BattleDrawingShape, int>{
      for (final entry in recognizedShapeCounts.entries)
        entry.key: entry.value.clamp(0, 9999).toInt(),
    };
    if (nuisances.isEmpty) {
      return BattleDrawingEnemyNuisanceResolution(
        remainingCounts: Map<BattleDrawingShape, int>.unmodifiable(
          remainingCounts,
        ),
      );
    }

    final resolvedNuisances = <BattleDrawingEnemyNuisance>[];
    final triggeredNuisances = <BattleDrawingEnemyNuisance>[];
    final consumedCounts = <BattleDrawingShape, int>{};
    var directDamage = 0;
    var barrierTransferAmount = 0;
    var healthTransferAmount = 0;
    var transferBuffs = false;

    for (final nuisance in nuisances) {
      final available = remainingCounts[nuisance.requiredShape] ?? 0;
      if (available > 0) {
        resolvedNuisances.add(nuisance);
        remainingCounts[nuisance.requiredShape] = available - 1;
        consumedCounts.update(
          nuisance.requiredShape,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        continue;
      }

      triggeredNuisances.add(nuisance);
      switch (nuisance.kind) {
        case BattleDrawingEnemyNuisanceKind.directDamage:
          directDamage += nuisance.amount;
          break;
        case BattleDrawingEnemyNuisanceKind.barrierTransfer:
          barrierTransferAmount += nuisance.amount;
          break;
        case BattleDrawingEnemyNuisanceKind.healthTransfer:
          healthTransferAmount += nuisance.amount;
          break;
        case BattleDrawingEnemyNuisanceKind.buffTransfer:
          transferBuffs = true;
          break;
      }
    }

    return BattleDrawingEnemyNuisanceResolution(
      nuisances: List<BattleDrawingEnemyNuisance>.unmodifiable(nuisances),
      resolvedNuisances:
          List<BattleDrawingEnemyNuisance>.unmodifiable(resolvedNuisances),
      triggeredNuisances:
          List<BattleDrawingEnemyNuisance>.unmodifiable(triggeredNuisances),
      consumedCounts: Map<BattleDrawingShape, int>.unmodifiable(consumedCounts),
      remainingCounts: Map<BattleDrawingShape, int>.unmodifiable(
        remainingCounts,
      ),
      penalty: BattleAttackDrawingPenalty(
        directDamage: directDamage,
        barrierTransferAmount: barrierTransferAmount,
        healthTransferAmount: healthTransferAmount,
        transferBuffs: transferBuffs,
      ),
    );
  }
}
