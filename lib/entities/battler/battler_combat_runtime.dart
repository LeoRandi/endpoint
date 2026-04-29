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

  /// Bonus plano que las pasivas de Resonancia anaden a su dano propio.
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

  /// Calcula dano de Resonancia aplicando bonuses pasivos relevantes.
  int resonanceDamageFor(int baseDamage) {
    return max(0, baseDamage + resonanceDamageBonus);
  }

  /// Aplica efectos que recompensan el dano infligido por Resonancia.
  Battler gainBarrierFromResonanceDamage(int damage) {
    final safeDamage = max(0, damage);
    if (safeDamage <= 0 ||
        !equippedItems.any((item) => item.id == ItemId.canonContrapresion)) {
      return this;
    }

    return gainCombatBarrier(safeDamage ~/ 2);
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
    required ItemCombatFlagKind kind,
  }) {
    return combatFlags.where((flag) {
      return flag.itemFlag == kind &&
          flag.itemId == item.id &&
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
    required ItemCombatFlagKind kind,
  }) {
    final nextUse = itemCombatFlagUseCount(item: item, kind: kind);
    return addCombatFlag(
      CombatRuntimeFlag.item(
        itemFlag: kind,
        itemId: item.id,
        itemInstanceId: item.instanceId,
        value: nextUse,
      ),
    );
  }

  /// Devuelve el primer valor asociado a una flag de item.
  int? itemCombatFlagValue({
    required Item item,
    required ItemCombatFlagKind kind,
  }) {
    for (final flag in combatFlags) {
      if (flag.itemFlag == kind &&
          flag.itemId == item.id &&
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
    required ItemCombatFlagKind kind,
  }) {
    final hasMatchingFlag = combatFlags.any((flag) {
      return flag.itemFlag == kind &&
          flag.itemId == item.id &&
          flag.itemInstanceId == item.instanceId;
    });
    if (!hasMatchingFlag) return this;

    final updatedFlags = Set<CombatRuntimeFlag>.from(combatFlags)
      ..removeWhere((flag) {
        return flag.itemFlag == kind &&
            flag.itemId == item.id &&
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

  int _secondaryValueForBattlerFlag(BattlerCombatFlag kind) {
    var total = 0;
    for (final flag in combatFlags) {
      if (flag.battlerFlag != kind) continue;
      total += max(0, flag.secondaryValue ?? flag.value ?? 0);
    }
    return total;
  }

  Battler _gainResonanceFromBarrierGain(int amount) {
    if (amount <= 0 || equippedItems.isEmpty) return this;

    var updatedOwner = this;
    final currentCombatRound = updatedOwner.combatRound;
    for (final item in equippedItems) {
      if (item.id != ItemId.nucleoPiezoelectrico) continue;

      final alreadyTriggered = updatedOwner.combatFlags.any((flag) {
        return flag.itemFlag ==
                ItemCombatFlagKind.nucleoPiezoelectricoTriggeredThisTurn &&
            flag.itemId == item.id &&
            flag.itemInstanceId == item.instanceId &&
            flag.value == currentCombatRound;
      });
      if (alreadyTriggered) continue;

      updatedOwner = updatedOwner
          .addCombatFlag(
            CombatRuntimeFlag.item(
              itemFlag:
                  ItemCombatFlagKind.nucleoPiezoelectricoTriggeredThisTurn,
              itemId: item.id,
              itemInstanceId: item.instanceId,
              value: currentCombatRound,
            ),
          )
          .gainResonance(max(1, item.value));
    }

    return updatedOwner;
  }
}
