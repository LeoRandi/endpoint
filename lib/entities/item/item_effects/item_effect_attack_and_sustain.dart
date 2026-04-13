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
