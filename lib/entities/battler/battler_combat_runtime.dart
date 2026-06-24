part of 'battler.dart';

extension BattlerCombatRuntime on Battler {
  /// Comprueba si una flag de combate concreta sigue activa.
  bool hasCombatFlag(CombatRuntimeFlag flag) => combatFlags.contains(flag);

  /// Devuelve la ronda de combate que el controlador ha sincronizado.
  int get combatRound {
    for (final flag in combatFlags) {
      if (flag.battlerFlag == BattlerCombatFlag.currentRoundMarker) {
        return max(1, flag.value ?? 1);
      }
    }

    return 1;
  }

  /// Devuelve cuanta Barrera se ha perdido en el ultimo impacto resuelto.
  int get barrierLostThisHit {
    return _secondaryValueForBattlerFlag(BattlerCombatFlag.barrierLostThisHit);
  }

  /// Devuelve cuanta vida real se ha perdido en el ultimo impacto resuelto.
  int get healthLostThisHit {
    return _secondaryValueForBattlerFlag(BattlerCombatFlag.healthLostThisHit);
  }

  /// Devuelve el daño directo separado que ha causado Fragilidad en este golpe.
  int get fragilidadTriggeredThisHit {
    return _secondaryValueForBattlerFlag(
      BattlerCombatFlag.fragilidadTriggeredThisHit,
    );
  }

  /// BP que siguen consumidos por Murallas destruidas o desactivadas en esta matriz.
  int get removedWallBlockingPointDebt {
    return _secondaryValueForBattlerFlag(
      BattlerCombatFlag.removedWallBlockingPointDebt,
    );
  }

  /// Bonus plano que las pasivas de Resonancia añaden a su daño propio.
  int get resonanceDamageBonus {
    final ability = abilityById(BattlerAbilityId.masaCritica);
    if (ability == null || currentBarrier * 2 <= maxHealth) return 0;

    return max(0, ability.currentValue);
  }

  /// Indica si el ataque basico actual todavia tiene impactos pendientes.
  bool get hasPendingBasicAttackFollowUp {
    return hasCombatFlag(Battler.pendingBasicAttackFollowUpFlag);
  }

  /// Calcula el daño base de un ataque directo usando solo el ataque total del portador.
  int calculateDamageAgainst(Battler target) {
    // TODO: Apply thorns, damage reduction, and vampirism when their combat rules are defined.
    return max(1, calculatedStat(BattlerStat.attack));
  }

  /// Cura vida sin superar la vida maxima calculada actual.
  Battler heal(int amount) {
    final safeAmount = max(0, amount);
    return copyWith(health: min(maxHealth, health + safeAmount));
  }

  /// Suma Barrera temporal durante combate sin saltarse las invariantes del modelo.
  Battler gainCombatBarrier(
    int amount, {
    bool allowAboveMax = true,
  }) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0 ||
        isDefeated ||
        !hasCombatFlag(Battler.combatActiveFlag)) {
      return this;
    }

    final nextBarrier = currentBarrier + safeAmount;
    final updatedOwner = copyWith(
      currentBarrier:
          allowAboveMax ? nextBarrier : min(maxBarrier, nextBarrier),
    );
    return updatedOwner
        ._recordCombatBarrierGain(safeAmount)
        ._gainResonanceFromBarrierGain(safeAmount);
  }

  /// Calcula daño de Resonancia aplicando bonuses pasivos relevantes.
  int resonanceDamageFor(int baseDamage) {
    return max(0, baseDamage + resonanceDamageBonus);
  }

  /// Aplica efectos que recompensan el daño infligido por Resonancia.
  Battler gainBarrierFromResonanceDamage(int damage) {
    return this;
  }

  /// Sincroniza la ronda visible para efectos que necesitan historial temporal.
  Battler withCombatRound(int round) {
    final safeRound = max(1, round);
    final updatedFlags = Set<CombatRuntimeFlag>.from(combatFlags)
      ..removeWhere(
        (flag) => flag.battlerFlag == BattlerCombatFlag.currentRoundMarker,
      )
      ..add(
        CombatRuntimeFlag.battler(
          BattlerCombatFlag.currentRoundMarker,
          value: safeRound,
        ),
      );

    return copyWith(
      combatFlags: Set<CombatRuntimeFlag>.unmodifiable(updatedFlags),
    );
  }

  /// Suma cuanta Barrera se ha ganado durante las ultimas rondas de combate.
  int barrierGainedInRecentCombatRounds(int roundCount) {
    final safeRoundCount = max(1, roundCount);
    final currentCombatRound = combatRound;
    final oldestRound = max(1, currentCombatRound - safeRoundCount + 1);
    var total = 0;

    for (final flag in combatFlags) {
      if (flag.battlerFlag != BattlerCombatFlag.barrierGainMarker) continue;
      final round = flag.value;
      if (round == null || round < oldestRound || round > currentCombatRound) {
        continue;
      }
      total += max(0, flag.secondaryValue ?? 0);
    }

    return total;
  }

  /// Cuenta activaciones de un item concreto durante este combate.
  int itemCombatFlagUseCount({
    required Item item,
    required String kind,
  }) {
    return combatFlags.where((flag) {
      return flag.itemEffectKey == kind &&
          flag.itemKey == item.catalogKey &&
          flag.itemInstanceId == item.instanceId;
    }).length;
  }

  /// Cuenta activaciones globales de una flag de combate del battler.
  int battlerCombatFlagUseCount(BattlerCombatFlag kind) {
    return combatFlags.where((flag) => flag.battlerFlag == kind).length;
  }

  /// Registra una activacion adicional asociada a una flag global del battler.
  Battler addBattlerCombatFlagUse(BattlerCombatFlag kind) {
    final nextUse = battlerCombatFlagUseCount(kind);
    return addCombatFlag(
      CombatRuntimeFlag.battler(
        kind,
        value: nextUse,
      ),
    );
  }

  /// Registra una activacion adicional de un item para efectos limitados.
  Battler addItemCombatFlagUse({
    required Item item,
    required String kind,
  }) {
    final nextUse = itemCombatFlagUseCount(item: item, kind: kind);
    return addCombatFlag(
      CombatRuntimeFlag.item(
        itemEffectKey: kind,
        itemKey: item.catalogKey,
        itemInstanceId: item.instanceId,
        value: nextUse,
      ),
    );
  }

  /// Devuelve el primer valor asociado a una flag de item.
  int? itemCombatFlagValue({
    required Item item,
    required String kind,
  }) {
    for (final flag in combatFlags) {
      if (flag.itemEffectKey == kind &&
          flag.itemKey == item.catalogKey &&
          flag.itemInstanceId == item.instanceId) {
        return flag.value ?? flag.secondaryValue;
      }
    }

    return null;
  }

  /// Anade una flag de combate sin duplicarla.
  Battler addCombatFlag(CombatRuntimeFlag flag) {
    if (combatFlags.contains(flag)) return this;

    return copyWith(
      combatFlags: Set<CombatRuntimeFlag>.unmodifiable({
        ...combatFlags,
        flag,
      }),
    );
  }

  /// Elimina una flag de combate concreta si estaba activa.
  Battler removeCombatFlag(CombatRuntimeFlag flag) {
    if (!combatFlags.contains(flag)) return this;

    final updatedFlags = Set<CombatRuntimeFlag>.from(combatFlags)..remove(flag);
    return copyWith(
      combatFlags: Set<CombatRuntimeFlag>.unmodifiable(updatedFlags),
    );
  }

  /// Elimina todas las flags globales de un tipo concreto.
  Battler removeCombatFlagsFor(BattlerCombatFlag kind) {
    if (!combatFlags.any((flag) => flag.battlerFlag == kind)) {
      return this;
    }

    final updatedFlags = Set<CombatRuntimeFlag>.from(combatFlags)
      ..removeWhere((flag) => flag.battlerFlag == kind);
    return copyWith(
      combatFlags: Set<CombatRuntimeFlag>.unmodifiable(updatedFlags),
    );
  }

  /// Elimina todas las flags de una clase concreta asociadas a un item.
  Battler removeItemCombatFlagsFor({
    required Item item,
    required String kind,
  }) {
    final hasMatchingFlag = combatFlags.any((flag) {
      return flag.itemEffectKey == kind &&
          flag.itemKey == item.catalogKey &&
          flag.itemInstanceId == item.instanceId;
    });
    if (!hasMatchingFlag) return this;

    final updatedFlags = Set<CombatRuntimeFlag>.from(combatFlags)
      ..removeWhere((flag) {
        return flag.itemEffectKey == kind &&
            flag.itemKey == item.catalogKey &&
            flag.itemInstanceId == item.instanceId;
      });
    return copyWith(
      combatFlags: Set<CombatRuntimeFlag>.unmodifiable(updatedFlags),
    );
  }

  /// Limpia todas las flags temporales de combate.
  Battler clearCombatFlags() {
    if (combatFlags.isEmpty) return this;

    return copyWith(combatFlags: const <CombatRuntimeFlag>{});
  }

  /// Elimina todas las paredes y bloqueos generados por el combate actual.
  ///
  /// Tambien limpia paredes temporales pendientes y el contador de paredes
  /// destruidas para que el siguiente encuentro empiece sin deuda heredada.
  Battler clearCombatWalls() {
    if (combatWallSegments.isEmpty &&
        combatBlockedPointKeys.isEmpty &&
        temporaryCombatWallSegments.isEmpty &&
        queuedTemporaryCombatWallSegments.isEmpty &&
        combatDestroyedWallCount == 0) {
      return this;
    }

    return copyWith(
      combatWallSegments: const <OperativePatternWallSegment>[],
      combatBlockedPointKeys: const <String>{},
      temporaryCombatWallSegments: const <OperativePatternWallSegment>[],
      queuedTemporaryCombatWallSegments: const <OperativePatternWallSegment>[],
      combatDestroyedWallCount: 0,
    );
  }

  /// Genera paredes aleatorias entre puntos adyacentes del Patron operativo.
  ///
  /// Recibe la funcion de aleatoriedad desde fuera para mantener deterministas
  /// los controladores que ya poseen la semilla del combate.
  Battler seedRandomCombatWalls({
    required int count,
    required int Function(int max) nextInt,
  }) {
    final candidates = <OperativePatternWallSegment>[];
    for (final point in operativePatternPoints) {
      for (final delta in const [
        (x: 1, y: 0),
        (x: 0, y: 1),
      ]) {
        final neighbor = operativePatternPointAt(
          x: point.x + delta.x,
          y: point.y + delta.y,
        );
        if (neighbor == null) continue;
        candidates.add(OperativePatternWallSegment(a: point, b: neighbor));
      }
    }

    final remaining = List<OperativePatternWallSegment>.from(candidates);
    final picked = <OperativePatternWallSegment>[];
    while (picked.length < count && remaining.isNotEmpty) {
      picked.add(remaining.removeAt(nextInt(remaining.length)));
    }

    return addCombatWalls(picked);
  }

  /// Agrega paredes al combate sin duplicar segmentos ya registrados.
  Battler addCombatWalls(Iterable<OperativePatternWallSegment> walls) {
    final nextWalls = _mergedWalls(combatWallSegments, walls);
    if (_sameWallKeys(combatWallSegments, nextWalls)) return this;

    return copyWith(combatWallSegments: nextWalls);
  }

  /// Bloquea puntos del Patron durante el combate si existen en la grilla.
  ///
  /// Las claves desconocidas se ignoran para que efectos generados por datos
  /// antiguos no rompan la reconstruccion del Battler.
  Battler addCombatBlockedPoints(Iterable<String> pointKeys) {
    final nextPointKeys = Set<String>.from(combatBlockedPointKeys);
    for (final pointKey in pointKeys) {
      if (operativePatternPointsByKey.containsKey(pointKey)) {
        nextPointKeys.add(pointKey);
      }
    }
    if (_sameStringSets(combatBlockedPointKeys, nextPointKeys)) return this;

    return copyWith(
      combatBlockedPointKeys: Set<String>.unmodifiable(nextPointKeys),
    );
  }

  /// Prepara paredes temporales para activarlas al inicio del siguiente tramo.
  Battler queueTemporaryCombatWalls(
    Iterable<OperativePatternWallSegment> walls,
  ) {
    final nextWalls = _mergedWalls(queuedTemporaryCombatWallSegments, walls);
    if (_sameWallKeys(queuedTemporaryCombatWallSegments, nextWalls)) {
      return this;
    }

    return copyWith(queuedTemporaryCombatWallSegments: nextWalls);
  }

  /// Mueve las paredes temporales pendientes al conjunto activo del combate.
  ///
  /// Las paredes activadas tambien se conservan por separado para poder
  /// retirarlas limpiamente cuando expire su ventana temporal.
  Battler activateQueuedTemporaryCombatWalls() {
    if (queuedTemporaryCombatWallSegments.isEmpty) return this;

    final queuedWalls = queuedTemporaryCombatWallSegments;
    return copyWith(
      combatWallSegments: _mergedWalls(combatWallSegments, queuedWalls),
      temporaryCombatWallSegments:
          _mergedWalls(temporaryCombatWallSegments, queuedWalls),
      queuedTemporaryCombatWallSegments: const <OperativePatternWallSegment>[],
    );
  }

  /// Retira del combate las paredes marcadas como temporales.
  Battler expireTemporaryCombatWalls() {
    if (temporaryCombatWallSegments.isEmpty) return this;

    final temporaryKeys =
        temporaryCombatWallSegments.map((wall) => wall.key).toSet();
    return copyWith(
      combatWallSegments: combatWallSegments
          .where((wall) => !temporaryKeys.contains(wall.key))
          .toList(growable: false),
      temporaryCombatWallSegments: const <OperativePatternWallSegment>[],
    );
  }

  /// Destruye paredes activas y las purga tambien de las listas temporales.
  ///
  /// El contador de destruccion se registra por separado para que el llamador
  /// pueda decidir si un efecto debe convertir esas paredes en otro beneficio.
  Battler destroyCombatWalls(Iterable<OperativePatternWallSegment> walls) {
    final keysToDestroy = walls.map((wall) => wall.key).toSet();
    if (keysToDestroy.isEmpty) return this;

    final beforeCount = combatWallSegments.length;
    final nextWalls = combatWallSegments
        .where((wall) => !keysToDestroy.contains(wall.key))
        .toList(growable: false);
    final destroyedCount = beforeCount - nextWalls.length;
    if (destroyedCount <= 0) return this;

    return copyWith(
      combatWallSegments: nextWalls,
      temporaryCombatWallSegments: temporaryCombatWallSegments
          .where((wall) => !keysToDestroy.contains(wall.key))
          .toList(growable: false),
      queuedTemporaryCombatWallSegments: queuedTemporaryCombatWallSegments
          .where((wall) => !keysToDestroy.contains(wall.key))
          .toList(growable: false),
    );
  }

  /// Acumula cuantas paredes fueron destruidas por efectos del combate.
  Battler recordDestroyedCombatWalls(int count) {
    final safeCount = max(0, count);
    if (safeCount <= 0) return this;

    return copyWith(
      combatDestroyedWallCount: combatDestroyedWallCount + safeCount,
    );
  }

  /// Registra la deuda de puntos bloqueados removidos al destruir paredes.
  ///
  /// Cada pared equivale a tres puntos para mantener la conversion centralizada
  /// y evitar que cada habilidad replique la misma aritmetica.
  Battler recordRemovedWallBlockingPointDebt(int wallCount) {
    final safeWallCount = max(0, wallCount);
    if (safeWallCount <= 0) return this;

    return addCombatFlag(
      CombatRuntimeFlag.battler(
        BattlerCombatFlag.removedWallBlockingPointDebt,
        secondaryValue: safeWallCount * 3,
      ),
    );
  }

  /// Devuelve las paredes activas que comparten extremo con el punto indicado.
  List<OperativePatternWallSegment> combatWallsAdjacentTo(
    OperativePatternPoint point,
  ) {
    return combatWallSegments.where((wall) {
      return wall.a == point || wall.b == point;
    }).toList(growable: false);
  }

  /// Busca paredes que el trayecto normalizado del Patron cruza.
  ///
  /// El indice inicial permite revisar solo el tramo recien agregado cuando la
  /// interfaz construye el Patron paso a paso.
  List<OperativePatternWallSegment> combatWallsCrossedBy(
    List<OperativePatternPoint> points, {
    int startIndex = 0,
  }) {
    final sequence = OperativePatternRequirement.normalizedSequence(points);
    if (sequence.length < 2) return const <OperativePatternWallSegment>[];

    final crossed = <OperativePatternWallSegment>{};
    final connectedKeys = _connectedCombatWallKeys(combatWallSegments);
    for (var i = max(0, startIndex); i < sequence.length - 1; i++) {
      final from = sequence[i];
      final to = sequence[i + 1];
      for (final wall in combatWallSegments) {
        if (wall.blocks(
          from,
          to,
          isConnected: connectedKeys.contains(wall.key),
        )) {
          crossed.add(wall);
        }
      }
    }
    return List<OperativePatternWallSegment>.unmodifiable(crossed);
  }

  /// Acumula la Barrera ganada en esta ronda para efectos reactivos posteriores.
  Battler _recordCombatBarrierGain(int amount) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0 || !hasCombatFlag(Battler.combatActiveFlag)) {
      return this;
    }

    final currentCombatRound = combatRound;
    var previousAmount = 0;
    final updatedFlags = Set<CombatRuntimeFlag>.from(combatFlags);
    updatedFlags.removeWhere((flag) {
      final isRoundMarker =
          flag.battlerFlag == BattlerCombatFlag.barrierGainMarker &&
              flag.value == currentCombatRound;
      if (isRoundMarker) {
        previousAmount += max(0, flag.secondaryValue ?? 0);
      }
      return isRoundMarker;
    });
    updatedFlags.add(
      CombatRuntimeFlag.battler(
        BattlerCombatFlag.barrierGainMarker,
        value: currentCombatRound,
        secondaryValue: previousAmount + safeAmount,
      ),
    );

    return copyWith(
      combatFlags: Set<CombatRuntimeFlag>.unmodifiable(updatedFlags),
    );
  }

  /// Une dos listas de paredes usando la clave estable de sus extremos.
  List<OperativePatternWallSegment> _mergedWalls(
    Iterable<OperativePatternWallSegment> first,
    Iterable<OperativePatternWallSegment> second,
  ) {
    final byKey = <String, OperativePatternWallSegment>{};
    for (final wall in first) {
      byKey[wall.key] = wall;
    }
    for (final wall in second) {
      byKey[wall.key] = wall;
    }
    return List<OperativePatternWallSegment>.unmodifiable(byKey.values);
  }

  /// Compara dos colecciones de paredes sin depender de su orden.
  bool _sameWallKeys(
    Iterable<OperativePatternWallSegment> first,
    Iterable<OperativePatternWallSegment> second,
  ) {
    final firstKeys = first.map((wall) => wall.key).toSet();
    final secondKeys = second.map((wall) => wall.key).toSet();
    return firstKeys.length == secondKeys.length &&
        firstKeys.containsAll(secondKeys);
  }

  /// Compara dos conjuntos de texto evitando crear colecciones intermedias.
  bool _sameStringSets(Set<String> first, Set<String> second) {
    return first.length == second.length && first.containsAll(second);
  }

  /// Identifica paredes que forman parte de una cadena conectada.
  ///
  /// Las paredes conectadas usan un area de bloqueo ligeramente mas amplia para
  /// que el jugador no pueda atravesar visualmente un cruce entre segmentos.
  Set<String> _connectedCombatWallKeys(
    Iterable<OperativePatternWallSegment> walls,
  ) {
    final endpointCounts = <String, int>{};
    for (final wall in walls) {
      endpointCounts.update(wall.a.key, (count) => count + 1,
          ifAbsent: () => 1);
      endpointCounts.update(wall.b.key, (count) => count + 1,
          ifAbsent: () => 1);
    }
    return {
      for (final wall in walls)
        if ((endpointCounts[wall.a.key] ?? 0) > 1 ||
            (endpointCounts[wall.b.key] ?? 0) > 1)
          wall.key,
    };
  }

  /// Suma el valor secundario de flags de combate del Battler indicadas.
  ///
  /// Cuando una flag antigua no trae valor secundario se usa su valor principal
  /// como compatibilidad hacia atras.
  int _secondaryValueForBattlerFlag(BattlerCombatFlag kind) {
    var total = 0;
    for (final flag in combatFlags) {
      if (flag.battlerFlag != kind) continue;
      total += max(0, flag.secondaryValue ?? flag.value ?? 0);
    }
    return total;
  }

  /// Convierte la primera ganancia de Barrera de cada ronda en Resonancia si procede.
  Battler _gainResonanceFromBarrierGain(int amount) {
    return this;
  }
}
