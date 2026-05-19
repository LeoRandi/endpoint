part of 'battler.dart';

extension BattlerStatusManagement on Battler {
  /// Indica si el battler tiene al menos un estado activo.
  bool get hasStatuses => _derivedState.statusesById.isNotEmpty;

  /// Busca el primer estado activo con el id indicado.
  BattlerStatus? statusById(BattlerStatusId statusId) {
    final matchingStatuses = _derivedState.statusesById[statusId];
    if (matchingStatuses == null || matchingStatuses.isEmpty) return null;

    return matchingStatuses.first;
  }

  /// Devuelve todas las instancias activas que comparten un mismo id de estado.
  List<BattlerStatus> statusesById(BattlerStatusId statusId) {
    return _derivedState.statusesById[statusId] ?? const <BattlerStatus>[];
  }

  /// Devuelve solo los estados que declararon el hook pedido en su metadata tipada.
  List<BattlerStatus> statusesForHook(BattlerStatusHook hook) {
    return _derivedState.statusesByHook[hook] ?? const <BattlerStatus>[];
  }

  /// Comprueba si existe al menos una instancia del estado indicado.
  bool hasStatus(BattlerStatusId statusId) {
    return statusById(statusId) != null;
  }

  /// Devuelve la Resonancia acumulada durante el combate.
  int get resonanceValue {
    final status = statusById(ResonanciaStatus.statusId);
    if (status is! ResonanciaStatus) return 0;

    return max(0, status.resolved(this).value);
  }

  /// Acumula Resonancia como buff temporal de combate.
  Battler gainResonance(int amount) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0 || isDefeated) return this;

    return applyStatus(
      ResonanciaStatus(value: safeAmount),
      applyEquipmentModifiers: false,
    );
  }

  /// Consume hasta la cantidad indicada de Resonancia acumulada.
  Battler spendResonance(int amount) {
    final safeAmount = max(0, amount);
    final currentStatus = statusById(ResonanciaStatus.statusId);
    if (safeAmount <= 0 || currentStatus is! ResonanciaStatus) {
      return this;
    }

    final nextValue = max(0, currentStatus.resolved(this).value - safeAmount);
    if (nextValue <= 0) {
      return removeStatusInstance(currentStatus);
    }

    return replaceStatusInstance(
      currentStatus: currentStatus,
      replacement: currentStatus.copyWith(value: nextValue),
    );
  }

  /// Limpia toda la Resonancia acumulada y devuelve la cantidad consumida.
  Battler clearResonance() {
    return removeStatus(ResonanciaStatus.statusId);
  }

  /// Devuelve el Desafio acumulado durante el combate.
  int get desafioValue {
    final status = statusById(DesafioStatus.statusId);
    if (status is! DesafioStatus) return 0;

    return max(0, status.resolved(this).value);
  }

  /// Acumula Desafio como buff temporal de combate.
  Battler gainDesafio(int amount) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0 || isDefeated) return this;

    return applyStatus(
      DesafioStatus(value: safeAmount),
      applyEquipmentModifiers: false,
    );
  }

  /// Limpia solo las instancias de estado ya caducadas y deja el resto intacto.
  Battler pruneExpiredStatuses() {
    return _removeExpiredStatuses();
  }

  /// Aplica un estado nuevo resolviendo stacking, reemplazos y hooks de estado.
  Battler applyStatus(
    BattlerStatus status, {
    bool applyEquipmentModifiers = false,
  }) {
    var updatedOwner = this;
    BattlerStatus? instancedStatus = status.copyWith();

    if (instancedStatus.isExpired) {
      return updatedOwner;
    }

    final activeStatuses = List<BattlerStatus>.from(
      updatedOwner.statusesForHook(BattlerStatusHook.statusApplied),
    );

    for (final activeStatus in activeStatuses) {
      if (instancedStatus == null) break;

      final resolvedStatus = activeStatus.resolved(updatedOwner);
      final resolution = resolvedStatus.onStatusApplied(
        owner: updatedOwner,
        appliedStatus: instancedStatus,
      );
      updatedOwner = resolution.owner;
      instancedStatus = resolution.appliedStatus.copyWith();
    }

    if (instancedStatus == null || instancedStatus.isExpired) {
      return updatedOwner._removeExpiredStatuses();
    }

    final resolvedInstancedStatus = instancedStatus;
    final updatedStatuses = List<BattlerStatus>.from(updatedOwner.statuses);
    if (resolvedInstancedStatus.canStack) {
      updatedOwner = updatedOwner._healFromCalentandoGain(
        previousStatus: null,
        nextStatus: resolvedInstancedStatus,
      );
      updatedStatuses.add(resolvedInstancedStatus);
      return updatedOwner
          .copyWith(
            statuses: List<BattlerStatus>.unmodifiable(updatedStatuses),
          )
          ._removeExpiredStatuses();
    }

    final existingIndex = updatedStatuses.indexWhere(
      (activeStatus) =>
          activeStatus.id == resolvedInstancedStatus.id &&
          !activeStatus.canStack,
    );

    if (existingIndex >= 0) {
      updatedOwner = updatedOwner._healFromCalentandoGain(
        previousStatus: updatedStatuses[existingIndex],
        nextStatus: resolvedInstancedStatus,
      );
      updatedStatuses[existingIndex] = resolvedInstancedStatus;
    } else {
      updatedOwner = updatedOwner._healFromCalentandoGain(
        previousStatus: null,
        nextStatus: resolvedInstancedStatus,
      );
      updatedStatuses.add(resolvedInstancedStatus);
    }

    return updatedOwner
        .copyWith(statuses: List<BattlerStatus>.unmodifiable(updatedStatuses))
        ._removeExpiredStatuses();
  }

  Battler _healFromCalentandoGain({
    required BattlerStatus? previousStatus,
    required BattlerStatus nextStatus,
  }) {
    if (nextStatus.id != CalentandoStatus.statusId) return this;

    final ability = abilityById(BattlerAbilityId.encendidoBrutal);
    if (ability == null) return this;

    final previousValue = previousStatus?.resolved(this).value ?? 0;
    final gainedValue = max(0, nextStatus.resolved(this).value - previousValue);
    if (gainedValue <= 0) return this;

    final divisor = max(1, ability.currentValue);
    return heal(max(1, (gainedValue / divisor).ceil()));
  }

  /// Elimina todas las instancias del estado indicado.
  Battler removeStatus(BattlerStatusId statusId) {
    if (!this.hasStatus(statusId)) return this;

    final updatedStatuses = statuses
        .where((status) => status.id != statusId)
        .toList(growable: false);
    return copyWith(
      statuses: List<BattlerStatus>.unmodifiable(updatedStatuses),
    );
  }

  /// Elimina una instancia concreta de estado comparando referencia o valores runtime.
  Battler removeStatusInstance(BattlerStatus status) {
    final updatedStatuses = List<BattlerStatus>.from(statuses);
    final matchingIndex = updatedStatuses.indexWhere(
      (activeStatus) =>
          identical(activeStatus, status) ||
          (activeStatus.runtimeType == status.runtimeType &&
              activeStatus.id == status.id &&
              activeStatus.remainingTurns == status.remainingTurns &&
              activeStatus.value == status.value),
    );
    if (matchingIndex < 0) return this;

    updatedStatuses.removeAt(matchingIndex);
    return copyWith(
      statuses: List<BattlerStatus>.unmodifiable(updatedStatuses),
    );
  }

  /// Sustituye una instancia concreta de estado por otra ya resuelta.
  Battler replaceStatusInstance({
    required BattlerStatus currentStatus,
    required BattlerStatus replacement,
  }) {
    final updatedStatuses = List<BattlerStatus>.from(statuses);
    final matchingIndex = updatedStatuses.indexWhere(
      (activeStatus) =>
          identical(activeStatus, currentStatus) ||
          (activeStatus.runtimeType == currentStatus.runtimeType &&
              activeStatus.id == currentStatus.id &&
              activeStatus.remainingTurns == currentStatus.remainingTurns &&
              activeStatus.value == currentStatus.value),
    );
    if (matchingIndex < 0) return this;

    updatedStatuses[matchingIndex] = replacement;
    return copyWith(
      statuses: List<BattlerStatus>.unmodifiable(updatedStatuses),
    );
  }

  /// Reduce en uno la duracion de todos los estados temporales y limpia los caducados.
  Battler decrementStatusDurations() {
    if (statuses.isEmpty) return this;

    final updatedStatuses = statuses
        .map(
          (status) => status.copyWith(
            remainingTurns: max(0, status.remainingTurns - 1),
          ),
        )
        .where((status) => !status.isExpired)
        .toList(growable: false);
    return copyWith(
      statuses: List<BattlerStatus>.unmodifiable(updatedStatuses),
    );
  }

  /// Elimina todos los estados que no deben sobrevivir fuera del combate.
  Battler clearCombatStatuses() {
    if (statuses.every((status) => status.persistsOutsideCombat)) {
      return this;
    }

    return copyWith(
      statuses: List<BattlerStatus>.unmodifiable(
        statuses
            .where((status) => status.persistsOutsideCombat)
            .toList(growable: false),
      ),
    );
  }
}
