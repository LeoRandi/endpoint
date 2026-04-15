part of '../item_effect.dart';

/// Convierte el ataque basico en un doble golpe a cambio de reducir el ATK total.
class SunglassesItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para las Gafas de Sol.
  const SunglassesItemEffect()
      : super(
          description:
              'Tu ATK total se reduce a la mitad, redondeado hacia arriba y con minimo 1. A cambio, cada accion de ataque basico se resuelve dos veces.',
          hooks: const {
            ItemEffectHook.calculatedStatModifier,
            ItemEffectHook.basicAttackCountModifier,
          },
        );

  @override

  /// Reduce el ATK final del portador para equilibrar el doble golpe.
  int modifyCalculatedStat({
    required Battler owner,
    required Item item,
    required BattlerStat stat,
    required int value,
  }) {
    if (stat != BattlerStat.attack) return value;

    return max(1, (value + 1) ~/ 2);
  }

  @override

  /// Anade un ataque extra a cada accion de ataque basico.
  int modifyBasicAttackCount({
    required Battler owner,
    required Item item,
    required int count,
  }) {
    return count + 1;
  }
}

/// Aplica Intoxicacion al objetivo o refuerza la que ya tenga.
class IntoxicarOnAttackItemEffect extends ItemEffect {
  final int amount;

  /// Crea un efecto reutilizable que intoxica al golpear.
  const IntoxicarOnAttackItemEffect({
    this.amount = 1,
  }) : super(
          description:
              'Al atacar: intoxica el enemigo en 1, o aumenta su valor de Intoxicacion en 1.',
          hooks: const {
            ItemEffectHook.attackResolved,
          },
        );

  @override

  /// Genera la descripcion final usando el valor actual del objeto equipado.
  String descriptionFor(Item item) {
    final resolvedAmount = max(1, item.value > 0 ? item.value : amount);
    return 'Al atacar: aplica o aumenta Intoxicacion en $resolvedAmount.';
  }

  @override

  /// Tras atacar, suma Intoxicacion existente o crea una nueva instancia.
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final resolvedAmount = max(1, item.value > 0 ? item.value : amount);
    final currentPoison = target.statusById(IntoxicacionStatus.statusId);
    final updatedTarget = currentPoison is IntoxicacionStatus
        ? target.applyStatus(
            currentPoison.copyWith(
              value: currentPoison.value + resolvedAmount,
            ),
            source: owner,
          )
        : target.applyStatus(
            IntoxicacionStatus(value: resolvedAmount),
            source: owner,
          );

    return ItemEffectResolution(
      owner: owner,
      opponent: updatedTarget,
    );
  }
}

/// Cura al portador al inicio de cada turno propio mientras siga equipado.
class RegenerativeShieldItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para escudos con regeneracion pasiva.
  const RegenerativeShieldItemEffect()
      : super(
          description:
              'Al inicio de tu turno, te curas una cantidad fija de vida.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, recuperas ${item.value} HP.';
  }

  @override

  /// Cura al portador al comenzar su propio turno.
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
      owner: owner.heal(item.value),
      opponent: opponent,
    );
  }
}

/// Recupera barrera al inicio del turno propio con una cantidad fija.
class RecoverBarrierOnTurnStartItemEffect extends ItemEffect {
  final int amount;

  /// Crea un efecto reutilizable para objetos que regeneran barrera de combate.
  const RecoverBarrierOnTurnStartItemEffect({
    required this.amount,
  }) : super(
          description:
              'Al inicio de tu turno, recuperas una cantidad fija de barrera.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override

  /// Genera la descripcion final usando la cantidad configurada para este item.
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, recuperas $amount de Barrera.';
  }

  @override

  /// Restaura barrera sin sobrepasar la barrera maxima calculada del portador.
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
      owner: owner.copyWith(
        currentBarrier: min(
          owner.maxBarrier,
          owner.currentBarrier + amount,
        ),
      ),
      opponent: opponent,
    );
  }
}

/// Refresca la barrera hasta un minimo al inicio del turno propio.
class RefreshMinimumBarrierOnTurnStartItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para objetos que garantizan un suelo de barrera.
  const RefreshMinimumBarrierOnTurnStartItemEffect()
      : super(
          description:
              'Al inicio de tu turno, si tu barrera esta por debajo de un minimo, se ajusta a ese valor.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, si tienes menos de ${max(1, item.value)} de Barrera, la subes hasta ese valor.';
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
      owner: _refreshMinimumBarrier(
        owner: owner,
        value: item.value,
      ),
      opponent: opponent,
    );
  }
}

/// Cura un poco al portador cuando deja al objetivo en rango de remate.
class RescueBladeItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Cuchilla de Rescate.
  const RescueBladeItemEffect()
      : super(
          description:
              'Si el objetivo queda al 50% de HP o menos, recuperas vida.',
          hooks: const {
            ItemEffectHook.attackResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al atacar, si el objetivo queda al 50% de HP o menos, recuperas ${item.value} HP.';
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    if (target.maxHealth <= 0 || target.health * 2 > target.maxHealth) {
      return ItemEffectResolution(owner: owner, opponent: target);
    }

    return ItemEffectResolution(
      owner: owner.heal(item.value),
      opponent: target,
    );
  }
}

/// Castiga al agresor si el portador consigue mantener parte de su barrera.
class ShockMeshItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Malla de Choque.
  const ShockMeshItemEffect()
      : super(
          description:
              'Al recibir dano mientras sigues teniendo barrera, aplicas Conmocion al agresor.',
          hooks: const {
            ItemEffectHook.receiveDamageResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al recibir dano mientras conservas Barrera, aplicas Conmocion (-${item.value} dano) al agresor.';
  }

  @override
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    if (damageTaken <= 0 || owner.currentBarrier <= 0) {
      return ItemEffectResolution(owner: owner, opponent: source);
    }

    return ItemEffectResolution(
      owner: owner,
      opponent: source.applyStatus(
        ConmocionStatus(value: max(1, item.value)),
        source: owner,
      ),
    );
  }
}

/// Mezcla veneno y remate ligero cuando el objetivo ya esta intoxicado.
class ToxicScalpelItemEffect extends ItemEffect {
  /// Crea el efecto propio del Bisturi Toxico.
  const ToxicScalpelItemEffect()
      : super(
          description:
              'Al atacar aplica Intoxicacion y castiga extra a objetivos ya intoxicados.',
          hooks: const {
            ItemEffectHook.attackResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    final resolvedAmount = max(1, item.value);
    return 'Al atacar: aplica o aumenta Intoxicacion en $resolvedAmount. Si el objetivo ya estaba intoxicado, infliges $resolvedAmount dano directo extra.';
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final resolvedAmount = max(1, item.value);
    final currentPoison = target.statusById(IntoxicacionStatus.statusId);
    final hadPoison = currentPoison is IntoxicacionStatus;

    var updatedTarget = hadPoison
        ? target.applyStatus(
            currentPoison.copyWith(
              value: currentPoison.value + resolvedAmount,
            ),
            source: owner,
          )
        : target.applyStatus(
            IntoxicacionStatus(value: resolvedAmount),
            source: owner,
          );

    if (hadPoison) {
      updatedTarget = updatedTarget.receiveDirectDamage(
        resolvedAmount,
        source: owner,
      );
    }

    return ItemEffectResolution(
      owner: owner,
      opponent: updatedTarget,
    );
  }
}

/// Monetiza el primer golpe de cada turno sobre objetivos ya desestabilizados.
class SuccionaCreditosItemEffect extends ItemEffect {
  /// Crea el efecto propio de SuccionaCreditos.
  const SuccionaCreditosItemEffect()
      : super(
          description:
              'La primera vez por turno que atacas a un objetivo con un debuff, ganas creditos y recuperas barrera.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.attackResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    final resolvedValue = max(1, item.value);
    return 'La primera vez por turno que atacas a un objetivo con un debuff, ganas ${resolvedValue}C y recuperas ${resolvedValue} de Barrera.';
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
      ItemCombatFlagKind.succionaCreditosTriggeredThisTurn,
    );
    return ItemEffectResolution(
      owner: owner.removeCombatFlag(triggeredFlag),
      opponent: opponent,
    );
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final triggeredFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.succionaCreditosTriggeredThisTurn,
    );
    if (owner.hasCombatFlag(triggeredFlag) || !_hasAnyDebuff(target)) {
      return ItemEffectResolution(owner: owner, opponent: target);
    }

    final resolvedValue = max(1, item.value);
    final updatedOwner = _recoverBarrier(
      owner: owner.addCombatFlag(triggeredFlag).earnMoney(resolvedValue),
      amount: resolvedValue,
    );

    return ItemEffectResolution(
      owner: updatedOwner,
      opponent: target,
    );
  }
}

/// Convierte la defensa en una ventana de aguante contra objetivos debilitados.
class KunaiAnchoItemEffect extends ItemEffect {
  /// Crea el efecto propio del Kunai Ancho.
  const KunaiAnchoItemEffect()
      : super(
          description:
              'Al defender, si el enemigo tiene un debuff, recuperas barrera.',
          hooks: const {
            ItemEffectHook.defendResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al defender, si el enemigo tiene un debuff, recuperas ${max(1, item.value)} de Barrera.';
  }

  @override
  ItemEffectResolution onDefendResolved({
    required Battler owner,
    required Battler opponent,
    required Item item,
  }) {
    if (!_hasAnyDebuff(opponent)) {
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

/// Convierte la defensa en una carga ofensiva para el siguiente golpe.
class MagnetiCHammerItemEffect extends ItemEffect {
  /// Crea el efecto propio de la M(agneti)C Hammer.
  const MagnetiCHammerItemEffect()
      : super(
          description:
              'Al defender, ganas Potencia igual a tu Barrera total actual.',
          hooks: const {
            ItemEffectHook.defendResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al defender, ganas Potencia con un bonus de dano igual a tu Barrera total actual para el siguiente golpe.';
  }

  @override
  ItemEffectResolution onDefendResolved({
    required Battler owner,
    required Battler opponent,
    required Item item,
  }) {
    final potencyValue = max(0, owner.currentBarrier);
    if (potencyValue <= 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.applyStatus(
        PotenciaStatus(value: potencyValue),
        source: owner,
      ),
      opponent: opponent,
    );
  }
}

/// Convierte el primer ataque del turno en una sobrecarga brutal a cambio de autoinfligirse Quemadura.
class ClavoReactorItemEffect extends ItemEffect {
  /// Crea el efecto propio del Clavo Reactor.
  const ClavoReactorItemEffect()
      : super(
          description:
              'La primera vez por turno que atacas, infliges dano directo extra y te aplicas Quemadura.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.attackResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    final resolvedValue = max(1, item.value);
    return 'La primera vez por turno que atacas, infliges ${resolvedValue * 2} de dano directo extra y te aplicas Quemadura durante $resolvedValue turnos.';
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
      ItemCombatFlagKind.clavoReactorTriggeredThisTurn,
    );
    return ItemEffectResolution(
      owner: owner.removeCombatFlag(triggeredFlag),
      opponent: opponent,
    );
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final triggeredFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.clavoReactorTriggeredThisTurn,
    );
    if (owner.hasCombatFlag(triggeredFlag)) {
      return ItemEffectResolution(owner: owner, opponent: target);
    }

    final resolvedValue = max(1, item.value);
    final updatedOwner = owner.addCombatFlag(triggeredFlag).applyStatus(
          QuemaduraStatus(remainingTurns: resolvedValue),
          source: owner,
        );
    final updatedTarget = target.receiveDirectDamage(
      resolvedValue * 2,
      source: owner,
    );

    return ItemEffectResolution(
      owner: updatedOwner,
      opponent: updatedTarget,
    );
  }
}

/// Convierte vida directa en una gran reserva temporal de ataque.
class BombaMiocardicaItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Bomba Miocardica.
  const BombaMiocardicaItemEffect()
      : super(
          description:
              'Al inicio de tu turno, pierdes vida y ganas una gran Reserva de Inercia: ATK.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override
  String descriptionFor(Item item) {
    final resolvedValue = max(1, item.value);
    return 'Al inicio de tu turno, pierdes $resolvedValue HP y ganas Reserva de Inercia: ATK (+${resolvedValue * 2}).';
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

    final resolvedValue = max(1, item.value);
    final updatedOwner = _loseHealthDirectly(
      owner: owner,
      amount: resolvedValue,
    );
    if (updatedOwner.health <= 0) {
      return ItemEffectResolution(owner: updatedOwner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: updatedOwner.applyStatus(
        InerciaAtaqueStatus(value: resolvedValue * 2),
        source: updatedOwner,
      ),
      opponent: opponent,
    );
  }
}

/// Convierte la vida faltante en una amenaza ofensiva inmediata durante el primer ataque del turno.
class UltimaMarchaItemEffect extends ItemEffect {
  /// Crea el efecto propio de Ultima Marcha.
  const UltimaMarchaItemEffect()
      : super(
          description:
              'La primera vez por turno que atacas, infliges dano extra segun la vida que te falta.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.outgoingDamageModifier,
            ItemEffectHook.attackResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'La primera vez por turno que atacas, infliges dano adicional igual al maximo entre ${max(1, item.value)} y un cuarto de tu vida faltante.';
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
      ItemCombatFlagKind.ultimaMarchaTriggeredThisTurn,
    );
    return ItemEffectResolution(
      owner: owner.removeCombatFlag(triggeredFlag),
      opponent: opponent,
    );
  }

  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damage,
  }) {
    final triggeredFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.ultimaMarchaTriggeredThisTurn,
    );
    if (owner.hasCombatFlag(triggeredFlag)) {
      return damage;
    }

    final bonusDamage = max(
      max(1, item.value),
      _missingHealth(owner) ~/ 4,
    );
    return damage + bonusDamage;
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final triggeredFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.ultimaMarchaTriggeredThisTurn,
    );
    if (owner.hasCombatFlag(triggeredFlag)) {
      return ItemEffectResolution(owner: owner, opponent: target);
    }

    return ItemEffectResolution(
      owner: owner.addCombatFlag(triggeredFlag),
      opponent: target,
    );
  }
}
