part of '../item_effect.dart';

/// Describe el autobloqueo de emergencia que resuelve el controlador.
class EmergencyPlatingItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Placa de Emergencia.
  const EmergencyPlatingItemEffect()
      : super(
          description:
              'Bloquea automaticamente al inicio de turno con poca vida.',
        );

  @override
  String descriptionFor(Item item) {
    final amount = max(1, item.value);
    return '+$amount Barrera. Las primeras $amount veces en combate que empieces tu turno por debajo de la mitad de vida, bloqueas sin gastar tu turno.';
  }
}

/// Redirige los primeros debuffs recibidos hacia quien los envio.
class DeflectiveCapacitorItemEffect extends ItemEffect {
  /// Crea el efecto propio del Condensador Deflectivo.
  const DeflectiveCapacitorItemEffect()
      : super(
          description:
              'Redirige los primeros debuffs recibidos hacia la fuente.',
          hooks: const {
            ItemEffectHook.incomingStatusModifier,
          },
        );

  @override
  String descriptionFor(Item item) {
    return '+1 Barrera. Las primeras ${max(1, item.value)} veces que fueras a recibir un debuff en combate, se lo aplicas al enemigo.';
  }

  @override
  ItemIncomingStatusResolution onIncomingStatus({
    required Battler owner,
    required Battler source,
    required Item item,
    required BattlerStatus status,
  }) {
    final maxReflections = max(1, item.value);
    final usedReflections = owner.itemCombatFlagUseCount(
      item: item,
      kind: ItemCombatFlagKind.deflectiveCapacitorReflectedDebuff,
    );
    if (status.type != BattlerStatusType.debuff ||
        identical(owner, source) ||
        usedReflections >= maxReflections) {
      return ItemIncomingStatusResolution(
        owner: owner,
        source: source,
        status: status,
      );
    }

    final updatedOwner = owner.addItemCombatFlagUse(
      item: item,
      kind: ItemCombatFlagKind.deflectiveCapacitorReflectedDebuff,
    );
    final updatedSource = source.applyStatus(
      status.copyWith(),
      applyEquipmentModifiers: false,
    );
    return ItemIncomingStatusResolution(
      owner: updatedOwner,
      source: updatedSource,
      status: null,
    );
  }
}

/// Devuelve una descarga cuando la barrera del portador se rompe.
class ContingencySealItemEffect extends ItemEffect {
  /// Crea el efecto propio del Sello de Contingencia.
  const ContingencySealItemEffect()
      : super(
          description:
              'Cuando tu barrera se rompe, descarga la barrera ganada recientemente.',
          hooks: const {
            ItemEffectHook.receiveDamageResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    final rounds = max(1, item.value);
    return '+$rounds Barrera. Cuando se rompe tu Barrera, haces al agresor dano directo igual a la Barrera ganada en las ultimas $rounds rondas de este combate.';
  }

  @override
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    if (!owner.hasCombatFlag(Battler.barrierBrokenThisHitFlag)) {
      return ItemEffectResolution(owner: owner, opponent: source);
    }

    final reflectedDamage = owner.barrierGainedInRecentCombatRounds(
      max(1, item.value),
    );
    if (reflectedDamage <= 0) {
      return ItemEffectResolution(owner: owner, opponent: source);
    }

    return ItemEffectResolution(
      owner: owner,
      opponent: source.receiveDirectDamage(
        reflectedDamage,
        source: owner,
      ),
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
    var resolution = _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: target,
      status: InterferenciaStatus(remainingTurns: resolvedDuration),
    );
    var updatedOwner = resolution.owner;
    var updatedTarget = resolution.opponent;

    if (hadInterference && updatedTarget.currentBarrier > 0) {
      updatedTarget = updatedTarget.copyWith(
        currentBarrier: max(0, updatedTarget.currentBarrier - 1),
      );
    }

    return ItemEffectResolution(
      owner: updatedOwner,
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
              'Si no recibes daño durante tu turno, recuperas barrera al final.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.turnEnd,
            ItemEffectHook.receiveDamageResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al final de tu turno, si no has recibido daño, recuperas ${max(1, item.value)} de Barrera.';
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
      owner: _recoverBarrierWithoutCap(
        owner: owner,
        amount: item.value,
      ),
      opponent: opponent,
    );
  }
}

/// Convierte la accion de defender en una recarga defensiva inmediata.
class ContainmentCoilItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Bobina de Contencion.
  const ContainmentCoilItemEffect()
      : super(
          description: 'Al defender, recuperas barrera adicional.',
          hooks: const {
            ItemEffectHook.defendResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al defender, recuperas ${max(1, item.value)} de Barrera.';
  }

  @override
  ItemEffectResolution onDefendResolved({
    required Battler owner,
    required Battler opponent,
    required Item item,
  }) {
    return ItemEffectResolution(
      owner: _recoverBarrierWithoutCap(
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
          description: 'Al defender, si tienes Calentando, recuperas barrera.',
          hooks: const {
            ItemEffectHook.defendResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al defender, si tienes Calentando, recuperas ${max(1, item.value)} de Barrera.';
  }

  @override
  ItemEffectResolution onDefendResolved({
    required Battler owner,
    required Battler opponent,
    required Item item,
  }) {
    if (!owner.hasStatus(CalentandoStatus.statusId)) {
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
              'La primera vez que recibes daño cada turno, aplicas Fragilidad al agresor.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.receiveDamageResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'La primera vez que recibes daño cada turno, aplicas Fragilidad (+${max(1, item.value)} daño recibido en el siguiente ataque) al agresor.';
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

    return _applyStatusToOpponentFromOwner(
      owner: owner.addCombatFlag(triggeredFlag),
      opponent: source,
      status: FragilidadStatus(remainingTurns: max(1, item.value)),
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
