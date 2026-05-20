part of '../item_effect.dart';

/// Convierte el ataque basico en un doble golpe a cambio de diluir bonus de items.
class SunglassesItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para las Gafas de Sol.
  const SunglassesItemEffect()
      : super(
          description:
              'Cada accion de ataque basico se resuelve dos veces, pero los bonus de items, adyacencias y patrones se reducen a la mitad, redondeando hacia arriba.',
          hooks: const {
            ItemEffectHook.basicAttackCountModifier,
          },
        );

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

/// Marca el objeto que concede Desafio antes del primer ataque del combate.
class GuanteRetoItemEffect extends ItemEffect {
  /// Crea el efecto descriptivo de Guante de Reto.
  const GuanteRetoItemEffect()
      : super(
          description:
              'La primera vez por combate que atacas, ganas Desafio antes del ataque.',
        );

  @override
  String descriptionFor(Item item) {
    return 'La primera vez por combate que atacas, ganas ${max(1, item.value)} Desafio antes del ataque.';
  }
}

/// Marca el objeto que permite a Desafio atravesar parte de la Barrera.
class VisorAperturaItemEffect extends ItemEffect {
  /// Crea el efecto descriptivo de Visor de Apertura.
  const VisorAperturaItemEffect()
      : super(
          description:
              'Los golpes directos de Desafio ignoran parte de la Barrera enemiga.',
        );

  @override
  String descriptionFor(Item item) {
    return 'Los golpes directos de Desafio ignoran hasta ${max(1, item.value)} de Barrera enemiga.';
  }
}

/// Marca el objeto que mejora futuros Desafios cuando provocan contraataque.
class SeguroRotoItemEffect extends ItemEffect {
  /// Crea el efecto descriptivo de Seguro Roto.
  const SeguroRotoItemEffect()
      : super(
          description:
              'Cuando un Desafio provoca un contraataque enemigo, tus siguientes Desafios mejoran durante este combate.',
        );

  @override
  String descriptionFor(Item item) {
    return 'Cuando un Desafio provoca un contraataque enemigo, ganas Desafio Excitante (+${max(1, item.value)} a tus siguientes Desafios en este combate).';
  }
}

/// Marca el objeto que convierte sobrevivir contraataques en mejores Desafios.
class AceleradorRetoItemEffect extends ItemEffect {
  /// Crea el efecto descriptivo de Acelerador de Reto.
  const AceleradorRetoItemEffect()
      : super(
          description:
              'Al sobrevivir a contraataques provocados por Desafio, mejora tus siguientes Desafios.',
        );

  @override
  String descriptionFor(Item item) {
    return 'La primera ${max(1, item.value)} vez por combate que sobrevives a un contraataque provocado por Desafio, ganas Desafio Excitante (+${max(1, item.value)}).';
  }
}

/// Marca el objeto que responde con un ataque tras un contraataque de Desafio.
class UltimaPalabraItemEffect extends ItemEffect {
  /// Crea el efecto descriptivo de Ultima Palabra.
  const UltimaPalabraItemEffect()
      : super(
          description:
              'Una vez por turno, despues de recibir un contraataque provocado por Desafio, atacas inmediatamente.',
        );

  @override
  String descriptionFor(Item item) {
    return 'Una vez por turno, despues de recibir un contraataque provocado por Desafio, atacas inmediatamente al enemigo con +${max(0, item.value)} al ataque.';
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
              'Al usarse: intoxica el enemigo en 1, o aumenta su Intoxicacion en 1.',
          hooks: const {
            ItemEffectHook.patternUsed,
          },
        );

  @override

  /// Genera la descripcion final usando el valor actual del objeto equipado.
  String descriptionFor(Item item) {
    final resolvedAmount = max(1, item.value > 0 ? item.value : amount);
    return 'Al usarse: aplica o aumenta Intoxicacion en $resolvedAmount.';
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
    return _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: target,
      status: currentPoison is IntoxicacionStatus
          ? currentPoison.copyWith(
              value: currentPoison.value + resolvedAmount,
            )
          : IntoxicacionStatus(value: resolvedAmount),
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

/// Cura al portador solo cuando realiza una accion de defensa.
class HealOnDefendItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para objetos que se activan al bloquear.
  const HealOnDefendItemEffect()
      : super(
          description: 'Al usarse, recuperas una cantidad fija de vida.',
          hooks: const {
            ItemEffectHook.patternUsed,
          },
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'Al usarse, recuperas ${item.value} HP.';
  }

  @override

  /// Cura al portador justo despues de resolver la accion de bloquear.
  ItemEffectResolution onDefendResolved({
    required Battler owner,
    required Battler opponent,
    required Item item,
  }) {
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

  /// Restaura barrera sin aplicar tope maximo.
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
      owner: owner.gainCombatBarrier(amount),
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
              'Al inicio de tu turno, si tu barrera esta por debajo de un minimo, se ajusta a esa cantidad.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, si tienes menos de ${max(1, item.value)} de Barrera, la subes hasta esa cantidad.';
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
              'Al usarse, si el objetivo queda al 50% de HP o menos, recuperas vida.',
          hooks: const {
            ItemEffectHook.patternUsed,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse, si el objetivo queda al 50% de HP o menos, recuperas ${item.value} HP.';
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
              'Al recibir daño mientras sigues teniendo barrera, aplicas Conmocion al agresor.',
          hooks: const {
            ItemEffectHook.receiveDamageResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al recibir daño mientras conservas Barrera, aplicas Conmocion (-${item.value} daño) al agresor.';
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

    return _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: source,
      status: ConmocionStatus(value: max(1, item.value)),
    );
  }
}

/// Mezcla veneno y remate ligero cuando el objetivo ya esta intoxicado.
class ToxicScalpelItemEffect extends ItemEffect {
  /// Crea el efecto propio del Bisturi Toxico.
  const ToxicScalpelItemEffect()
      : super(
          description:
              'Al usarse aplica Intoxicacion y castiga extra a objetivos ya intoxicados.',
          hooks: const {
            ItemEffectHook.patternUsed,
          },
        );

  @override
  String descriptionFor(Item item) {
    final resolvedAmount = max(1, item.value);
    return 'Al usarse: aplica o aumenta Intoxicacion en $resolvedAmount. Si el objetivo ya estaba intoxicado, infliges $resolvedAmount daño directo extra.';
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

    var resolution = _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: target,
      status: currentPoison is IntoxicacionStatus
          ? currentPoison.copyWith(
              value: currentPoison.value + resolvedAmount,
            )
          : IntoxicacionStatus(value: resolvedAmount),
    );
    var updatedOwner = resolution.owner;
    var updatedTarget = resolution.opponent;

    if (hadPoison) {
      updatedTarget = updatedTarget.receiveDirectDamage(
        resolvedAmount,
        source: updatedOwner,
      );
    }

    return ItemEffectResolution(
      owner: updatedOwner,
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
              'Al usarse, una vez por turno, si el objetivo tiene un debuff, ganas creditos y recuperas barrera.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.patternUsed,
          },
        );

  @override
  String descriptionFor(Item item) {
    final resolvedValue = max(1, item.value);
    return 'Al usarse, una vez por turno, si el objetivo tiene un debuff, ganas ${resolvedValue}C y recuperas $resolvedValue de Barrera.';
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
              'Al usarse, si el enemigo tiene un debuff, recuperas barrera.',
          hooks: const {
            ItemEffectHook.patternUsed,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse, si el enemigo tiene un debuff, recuperas ${max(1, item.value)} de Barrera.';
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
              'Al usarse, ganas Potencia igual a tu Barrera total actual.',
          hooks: const {
            ItemEffectHook.patternUsed,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse, ganas Potencia con un bonus de daño igual a tu Barrera total actual para el siguiente golpe.';
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
      owner: owner.applyStatusFromSource(
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
              'Al usarse, una vez por turno, infliges dano directo extra y te aplicas Quemadura.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.patternUsed,
          },
        );

  @override
  String descriptionFor(Item item) {
    final resolvedValue = max(1, item.value);
    return 'Al usarse, una vez por turno, infliges ${resolvedValue * 2} de dano directo extra y te aplicas Quemadura durante $resolvedValue turnos.';
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
    final updatedOwner =
        owner.addCombatFlag(triggeredFlag).applyStatusFromSource(
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

/// Convierte la vida faltante en una amenaza ofensiva inmediata durante el primer ataque del turno.
class UltimaMarchaItemEffect extends ItemEffect {
  /// Crea el efecto propio de Ultima Marcha.
  const UltimaMarchaItemEffect()
      : super(
          description:
              'Al usarse, una vez por turno, infliges dano extra segun la vida que te falta.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.outgoingDamageModifier,
            ItemEffectHook.patternUsed,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse, una vez por turno, infliges dano adicional igual al maximo entre ${max(1, item.value)} y un cuarto de tu vida faltante.';
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
