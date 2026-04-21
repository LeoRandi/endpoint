part of 'battler.dart';

extension BattlerAbilityManagement on Battler {
  /// Comprueba si el battler ya tiene una habilidad con ese id.
  bool hasAbility(BattlerAbility ability) {
    return abilityById(ability.id) != null;
  }

  /// Indica si el battler tiene al menos una habilidad.
  bool get hasAbilities => _derivedState.abilitiesById.isNotEmpty;

  /// Busca la habilidad activa con el id indicado.
  BattlerAbility? abilityById(BattlerAbilityId abilityId) {
    return _derivedState.abilitiesById[abilityId];
  }

  /// Indica si recibir esta habilidad acabaria mejorando una copia ya poseida.
  bool wouldUpgradeAbility(BattlerAbility ability) {
    final existingAbility = abilityById(ability.id);
    return existingAbility != null && existingAbility.canUpgrade;
  }

  /// Devuelve los ids de habilidad que registraron un hook concreto para el pipeline.
  List<BattlerAbilityId> abilityIdsForHook(BattlerAbilityHook hook) {
    return _derivedState.abilityIdsByHook[hook] ?? const <BattlerAbilityId>[];
  }

  /// Hace avanzar el cooldown de las habilidades al inicio del turno propio.
  Battler progressAbilityCooldownsOnTurnStart({
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn || abilities.isEmpty) return this;

    return copyWith(
      abilities: abilities
          .map((ability) => ability.tickCooldown())
          .toList(growable: false),
    );
  }

  /// Anade una habilidad nueva o mejora la existente si admite upgrade.
  Battler addAbility(BattlerAbility ability) {
    final existingIndex = abilities.indexWhere(
      (activeAbility) => activeAbility.id == ability.id,
    );
    if (existingIndex < 0) {
      return copyWith(
        abilities: List<BattlerAbility>.unmodifiable([
          ...abilities,
          ability,
        ]),
      );
    }

    final updatedAbilities = List<BattlerAbility>.from(abilities);
    updatedAbilities[existingIndex] =
        updatedAbilities[existingIndex].upgraded();

    return copyWith(
      abilities: List<BattlerAbility>.unmodifiable(updatedAbilities),
    );
  }

  /// Sustituye la version activa de una habilidad por la recibida.
  Battler updateAbility(BattlerAbility ability) {
    final updatedAbilities = List<BattlerAbility>.from(abilities);
    final existingIndex = updatedAbilities.indexWhere(
      (activeAbility) => activeAbility.id == ability.id,
    );
    if (existingIndex < 0) return this;

    updatedAbilities[existingIndex] = ability;
    return copyWith(
      abilities: List<BattlerAbility>.unmodifiable(updatedAbilities),
    );
  }

  /// Cambia una habilidad concreta por otra, manteniendo el orden visible.
  Battler replaceAbility({
    required BattlerAbility currentAbility,
    required BattlerAbility replacementAbility,
  }) {
    final updatedAbilities = List<BattlerAbility>.from(abilities);
    final existingIndex = updatedAbilities.indexWhere(
      (activeAbility) => activeAbility.id == currentAbility.id,
    );
    if (existingIndex < 0) return addAbility(replacementAbility);

    updatedAbilities[existingIndex] = replacementAbility.resetState();
    return copyWith(
      abilities: List<BattlerAbility>.unmodifiable(updatedAbilities),
    );
  }

  /// Resetea solo las habilidades manuales que pertenecen al contexto indicado.
  Battler resetAbilitiesForContext(
    BattlerAbilityActivationContext screenContext,
  ) {
    if (abilities.isEmpty) return this;

    return copyWith(
      abilities: abilities
          .map(
            (ability) => ability.manualActivationContext == screenContext
                ? ability.resetState()
                : ability,
          )
          .toList(growable: false),
    );
  }

  /// Resetea por completo el estado runtime de todas las habilidades.
  Battler resetAllAbilities() {
    if (abilities.isEmpty) return this;

    return copyWith(
      abilities: abilities
          .map((ability) => ability.resetState())
          .toList(growable: false),
    );
  }

  /// Devuelve el primer motivo por el que una activacion manual esta bloqueada.
  String? manualAbilityActivationBlockReason(
    BattlerAbilityActivationContext screenContext,
  ) {
    for (final status
        in statusesForHook(BattlerStatusHook.manualAbilityActivationBlocker)) {
      final resolvedStatus = status.resolved(this);
      final blockReason = resolvedStatus.manualAbilityActivationBlockReason(
        owner: this,
        screenContext: screenContext,
      );
      if (blockReason != null) {
        return blockReason;
      }
    }

    return null;
  }

  /// Indica si puede activarse una habilidad manual en este contexto.
  bool canActivateManualAbilities(
    BattlerAbilityActivationContext screenContext,
  ) {
    return manualAbilityActivationBlockReason(screenContext) == null;
  }
}
