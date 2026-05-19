part of '../item_effect.dart';

/// Alterna bonus de barrera o ataque segun el momento del ciclo.
class GafasFotocromaticasItemEffect extends ItemEffect {
  /// Crea el efecto de las Gafas Fotocromaticas.
  const GafasFotocromaticasItemEffect()
      : super(
          description:
              'De dia otorga barrera y de noche convierte el reflejo en ataque.',
          hooks: const {
            ItemEffectHook.calculatedStatModifier,
          },
        );

  @override
  String descriptionFor(Item item) {
    final amount = max(1, item.value);
    return 'De dia: +$amount Barrera. De noche: +$amount ATK.';
  }

  @override
  int modifyCalculatedStat({
    required Battler owner,
    required Item item,
    required BattlerStat stat,
    required int value,
  }) {
    final cycleContext = cycleContextFor(owner);
    final amount = max(1, item.value);

    if (stat == BattlerStat.barrier && cycleContext.isDay) {
      return value + amount;
    }
    if (stat == BattlerStat.attack && cycleContext.isNight) {
      return value + amount;
    }

    return value;
  }
}

/// Convierte la fase diurna en recarga defensiva y la nocturna en Potencia.
class BateriaCrepuscularItemEffect extends ItemEffect {
  /// Crea el efecto de la Bateria Crepuscular.
  const BateriaCrepuscularItemEffect()
      : super(
          description:
              'De dia repone barrera y de noche carga Potencia al arrancar turno.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override
  String descriptionFor(Item item) {
    final amount = max(1, item.value);
    return 'Al inicio de tu turno, de dia recuperas $amount de Barrera y de noche ganas Potencia (+$amount).';
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

    final cycleContext = cycleContextFor(owner);
    final amount = max(1, item.value);
    var updatedOwner = owner;

    if (cycleContext.isDay) {
      updatedOwner = _recoverBarrier(
        owner: updatedOwner,
        amount: amount,
      );
    }
    if (cycleContext.isNight) {
      updatedOwner = updatedOwner.applyStatusFromSource(
        PotenciaStatus(value: amount),
        source: updatedOwner,
      );
    }

    return ItemEffectResolution(
      owner: updatedOwner,
      opponent: opponent,
    );
  }
}

/// Emite un pulso al final del turno: cura de dia o castiga de noche.
class RelojDeTurnoItemEffect extends ItemEffect {
  /// Crea el efecto del Reloj de Turno.
  const RelojDeTurnoItemEffect()
      : super(
          description:
              'Marca el cierre del turno con curacion diurna o daño nocturno.',
          hooks: const {
            ItemEffectHook.turnEnd,
          },
        );

  @override
  String descriptionFor(Item item) {
    final amount = max(1, item.value);
    return 'Al final de tu turno, de dia te curas $amount HP y de noche infliges $amount de daño directo.';
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

    final cycleContext = cycleContextFor(owner);
    final amount = max(1, item.value);
    var updatedOwner = owner;
    var updatedOpponent = opponent;

    if (cycleContext.isDay) {
      updatedOwner = updatedOwner.heal(amount);
    }
    if (cycleContext.isNight) {
      updatedOpponent = updatedOpponent.receiveDirectDamage(
        amount,
        source: updatedOwner,
      );
    }

    return ItemEffectResolution(
      owner: updatedOwner,
      opponent: updatedOpponent,
    );
  }
}

/// Senala al rival al defender de dia o lo expone al atacar de noche.
class FaroNoctivagoItemEffect extends ItemEffect {
  /// Crea el efecto del Faro Noctivago.
  const FaroNoctivagoItemEffect()
      : super(
          description:
              'De dia aplica Conmocion al usarse y de noche deja el blanco expuesto.',
          hooks: const {
            ItemEffectHook.patternUsed,
          },
        );

  @override
  String descriptionFor(Item item) {
    final amount = max(1, item.value);
    return 'Al usarse: de dia aplica Conmocion ($amount). De noche acumula Fragilidad ($amount).';
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final cycleContext = cycleContextFor(owner);
    if (!cycleContext.isNight) {
      return ItemEffectResolution(owner: owner, opponent: target);
    }

    return _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: target,
      status: FragilidadStatus(value: max(1, item.value)),
    );
  }

  @override
  ItemEffectResolution onDefendResolved({
    required Battler owner,
    required Battler opponent,
    required Item item,
  }) {
    final cycleContext = cycleContextFor(owner);
    if (!cycleContext.isDay) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: ConmocionStatus(value: max(1, item.value)),
    );
  }
}

/// Refuerza la defensa de dia y la presion ofensiva de noche.
class PrismaCircadianoItemEffect extends ItemEffect {
  /// Crea el efecto del Prisma Circadiano.
  const PrismaCircadianoItemEffect()
      : super(
          description:
              'De dia recorta daño recibido y de noche suma daño saliente.',
          hooks: const {
            ItemEffectHook.outgoingDamageModifier,
            ItemEffectHook.incomingDamageModifier,
          },
        );

  @override
  String descriptionFor(Item item) {
    final amount = max(1, item.value);
    return 'De dia reduces en $amount el daño recibido. De noche tus ataques infligen $amount de daño adicional.';
  }

  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damage,
  }) {
    final cycleContext = cycleContextFor(owner);
    if (!cycleContext.isNight) {
      return damage;
    }

    return damage + max(1, item.value);
  }

  @override
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damage,
  }) {
    final cycleContext = cycleContextFor(owner);
    if (!cycleContext.isDay) {
      return damage;
    }

    return max(0, damage - max(1, item.value));
  }
}

/// Alterna entre defensa y ataque, y fija el ritmo para el resto de efectos de Ciclo.
class EclipseMantleItemEffect extends ItemEffect {
  /// Crea el efecto del Manto de Eclipse.
  const EclipseMantleItemEffect()
      : super(
          description:
              'Alterna su bonus entre barrera y ataque, marcando el ritmo del resto del Ciclo.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.calculatedStatModifier,
          },
        );

  @override
  String descriptionFor(Item item) {
    final amount = max(1, item.value);
    return 'Cada turno propio alterna entre +$amount Barrera y +$amount ATK. Tus efectos de Ciclo siguen ese ritmo.';
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

    final initializedFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.eclipseMantleInitialized,
    );
    final nightFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.eclipseMantleNightMode,
    );

    if (!owner.hasCombatFlag(initializedFlag)) {
      return ItemEffectResolution(
        owner: owner.addCombatFlag(initializedFlag).removeCombatFlag(nightFlag),
        opponent: opponent,
      );
    }

    final updatedOwner = owner.hasCombatFlag(nightFlag)
        ? owner.removeCombatFlag(nightFlag)
        : owner.addCombatFlag(nightFlag);
    return ItemEffectResolution(
      owner: updatedOwner,
      opponent: opponent,
    );
  }

  @override
  int modifyCalculatedStat({
    required Battler owner,
    required Item item,
    required BattlerStat stat,
    required int value,
  }) {
    final cycleContext = cycleContextFor(owner);
    final amount = max(1, item.value);

    if (stat == BattlerStat.barrier && cycleContext.isDay) {
      return value + amount;
    }
    if (stat == BattlerStat.attack && cycleContext.isNight) {
      return value + amount;
    }

    return value;
  }
}
