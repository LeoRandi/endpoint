part of '../item_effect.dart';

/// Convierte el turno sin barrera en un blindaje temporal minimo.
class DeflectiveCapacitorItemEffect extends ItemEffect {
  /// Crea el efecto propio del Condensador Deflectivo.
  const DeflectiveCapacitorItemEffect()
      : super(
          description:
              'Si empiezas tu turno sin barrera, recuperas Blindaje Temporal.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, si estas a 0 de Barrera, recuperas Blindaje Temporal (${max(1, item.value)} de absorcion).';
  }

  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn || owner.currentBarrier > 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _refreshMinimumBlindajeTemporal(
        owner: owner,
        value: item.value,
      ),
      opponent: opponent,
    );
  }
}

/// Aplica interferencia y erosiona barrera si el objetivo ya estaba bloqueado.
class InterferenceCannonItemEffect extends ItemEffect {
  /// Crea el efecto propio del Canon de Interferencia.
  const InterferenceCannonItemEffect()
      : super(
          description:
              'Al atacar aplica Interferencia y castiga barreras ya comprometidas.',
          hooks: const {
            ItemEffectHook.attackResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al atacar: aplica Interferencia durante ${max(1, item.value)} turnos. Si el objetivo ya la tenia, ademas pierde 1 de Barrera.';
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final resolvedDuration = max(1, item.value);
    final hadInterference = target.hasStatus(InterferenciaStatus.statusId);
    var updatedTarget = target.applyStatus(
      InterferenciaStatus(remainingTurns: resolvedDuration),
      source: owner,
    );

    if (hadInterference && updatedTarget.currentBarrier > 0) {
      updatedTarget = updatedTarget.copyWith(
        currentBarrier: max(0, updatedTarget.currentBarrier - 1),
      );
    }

    return ItemEffectResolution(
      owner: owner,
      opponent: updatedTarget,
    );
  }
}

/// Premia los turnos en los que el portador sale ileso.
class ResponseFrameItemEffect extends ItemEffect {
  /// Crea el efecto propio del Bastidor de Respuesta.
  const ResponseFrameItemEffect()
      : super(
          description:
              'Si no recibes dano durante tu turno, recuperas barrera al final.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.turnEnd,
            ItemEffectHook.receiveDamageResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al final de tu turno, si no has recibido dano, recuperas ${max(1, item.value)} de Barrera.';
  }

  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final damagedFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.responseFrameDamagedThisTurn,
    );
    return ItemEffectResolution(
      owner: owner.removeCombatFlag(damagedFlag),
      opponent: opponent,
    );
  }

  @override
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    if (damageTaken <= 0) {
      return ItemEffectResolution(owner: owner, opponent: source);
    }

    final damagedFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.responseFrameDamagedThisTurn,
    );
    return ItemEffectResolution(
      owner: owner.addCombatFlag(damagedFlag),
      opponent: source,
    );
  }

  @override
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final damagedFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.responseFrameDamagedThisTurn,
    );
    if (owner.hasCombatFlag(damagedFlag)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _recoverBarrier(
        owner: owner,
        amount: item.value,
      ),
      opponent: opponent,
    );
  }
}

/// Convierte una ofensiva sobrecalentada en aguante extra.
class OverloadAnchorItemEffect extends ItemEffect {
  /// Crea el efecto propio del Ancla de Sobrecarga.
  const OverloadAnchorItemEffect()
      : super(
          description:
              'Al final de tu turno, si tienes Calentando, recuperas barrera.',
          hooks: const {
            ItemEffectHook.turnEnd,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al final de tu turno, si tienes Calentando, recuperas ${max(1, item.value)} de Barrera.';
  }

  @override
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn || !owner.hasStatus(CalentandoStatus.statusId)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _recoverBarrier(
        owner: owner,
        amount: item.value,
      ),
      opponent: opponent,
    );
  }
}

/// Solo castiga el primer golpe recibido en cada turno propio.
class ReboundLensItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Lente de Rebote.
  const ReboundLensItemEffect()
      : super(
          description:
              'La primera vez que recibes dano cada turno, aplicas Fragilidad al agresor.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.receiveDamageResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'La primera vez que recibes dano cada turno, aplicas Fragilidad (+${max(1, item.value)} dano recibido en el siguiente ataque) al agresor.';
  }

  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final triggeredFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.reboundLensTriggeredThisTurn,
    );
    return ItemEffectResolution(
      owner: owner.removeCombatFlag(triggeredFlag),
      opponent: opponent,
    );
  }

  @override
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    if (damageTaken <= 0) {
      return ItemEffectResolution(owner: owner, opponent: source);
    }

    final triggeredFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.reboundLensTriggeredThisTurn,
    );
    if (owner.hasCombatFlag(triggeredFlag)) {
      return ItemEffectResolution(owner: owner, opponent: source);
    }

    return ItemEffectResolution(
      owner: owner.addCombatFlag(triggeredFlag),
      opponent: source.applyStatus(
        FragilidadStatus(remainingTurns: max(1, item.value)),
        source: owner,
      ),
    );
  }
}

/// Convierte ingresos estables en una recuperacion defensiva muy contenida.
class CapaDelContrabandistaItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Capa del Contrabandista.
  const CapaDelContrabandistaItemEffect()
      : super(
          description:
              'Al inicio de tu turno, si el enemigo tiene un debuff, recuperas barrera segun tu income actual.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, si el enemigo tiene un debuff, recuperas Barrera igual a tu INCOME actual, hasta un maximo de ${max(1, item.value)}.';
  }

  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn || !_hasAnyDebuff(opponent)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final recoveredBarrier = min(
      max(0, owner.income),
      max(1, item.value),
    );
    return ItemEffectResolution(
      owner: _recoverBarrier(
        owner: owner,
        amount: recoveredBarrier,
      ),
      opponent: opponent,
    );
  }
}

/// Disipa poco a poco debuffs aleatorios mientras el portador siga operativo.
class MamparaPortatilItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Mampara Portatil.
  const MamparaPortatilItemEffect()
      : super(
          description:
              'Al inicio de tu turno, reduce turnos de debuffs propios de forma aleatoria.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, reduces 1 turno de un debuff aleatorio ${max(1, item.value)} veces.';
  }

  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _reduceRandomPurgeableDebuffs(
        owner: owner,
        repetitions: max(1, item.value),
        randomizer: randomizer,
      ),
      opponent: opponent,
    );
  }
}

/// Limpia turnos de todos los debuffs purgables cada inicio de turno.
class CeramicaPurgadoraItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Ceramica Purgadora.
  const CeramicaPurgadoraItemEffect()
      : super(
          description:
              'Al inicio de tu turno, reduce la duracion de todos tus debuffs.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, reduces ${max(1, item.value)} turnos de todos tus debuffs purgables.';
  }

  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _reduceAllPurgeableDebuffs(
        owner: owner,
        amount: max(1, item.value),
      ),
      opponent: opponent,
    );
  }
}
