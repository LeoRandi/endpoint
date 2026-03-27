import '../_imports.dart';

/// Agrupa el estado final del portador y del rival tras resolver un efecto de item.
class ItemEffectResolution {
  final Battler owner;
  final Battler opponent;

  /// Crea una resolucion inmutable con ambos combatientes ya actualizados.
  const ItemEffectResolution({
    required this.owner,
    required this.opponent,
  });
}

/// Enumera los momentos en los que un item puede reaccionar a una habilidad.
enum ItemAbilityResolutionContext {
  manualActivation,
  attackResolved,
  receiveDamageResolved,
  turnStart,
  turnEnd,
}

/// Devuelve el estado resultante cuando un item modifica una activacion manual.
class ItemAbilityPreparationResolution {
  final Battler owner;
  final Battler opponent;
  final BattlerAbility ability;

  /// Crea una resolucion con el usuario, el rival y la habilidad ya ajustados.
  const ItemAbilityPreparationResolution({
    required this.owner,
    required this.opponent,
    required this.ability,
  });
}

/// Sirve como base comun para todos los hooks reactivos de los objetos equipados.
abstract class ItemEffect {
  final String description;

  /// Crea un efecto reutilizable con la descripcion base del item.
  const ItemEffect({
    required this.description,
  });

  /// Devuelve la descripcion mostrada por la UI, pudiendo usar el value del item.
  String descriptionFor(Item item) => description;

  /// Resuelve el efecto del item al inicio de turno.
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve el efecto del item al final de turno.
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Ajusta el dano saliente del portador antes de que se aplique.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damage,
  }) {
    return damage;
  }

  /// Ajusta el dano entrante del portador antes de que se aplique.
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damage,
  }) {
    return damage;
  }

  /// Ajusta una stat ya calculada del portador para efectos persistentes de equipo.
  int modifyCalculatedStat({
    required Battler owner,
    required Item item,
    required BattlerStat stat,
    required int value,
  }) {
    return value;
  }

  /// Ajusta cuantas veces se resuelve una accion de ataque basico.
  int modifyBasicAttackCount({
    required Battler owner,
    required Item item,
    required int count,
  }) {
    return count;
  }

  /// Resuelve efectos posteriores a que el portador termine un ataque.
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    return ItemEffectResolution(owner: owner, opponent: target);
  }

  /// Resuelve efectos posteriores a que el portador reciba dano.
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    return ItemEffectResolution(owner: owner, opponent: source);
  }

  /// Aplica efectos pasivos que deben reevaluarse sin un disparador puntual.
  ItemEffectResolution applyPassive({
    required Battler owner,
    required Battler opponent,
    required Item item,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Permite modificar una habilidad justo antes de su activacion manual real.
  ItemAbilityPreparationResolution onManualAbilityPreparing({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return ItemAbilityPreparationResolution(
      owner: owner,
      opponent: opponent,
      ability: ability,
    );
  }

  /// Reacciona a una habilidad ya resuelta para aplicar efectos posteriores.
  ItemEffectResolution onAbilityResolved({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlerAbility previousAbility,
    required BattlerAbility resolvedAbility,
    required ItemAbilityResolutionContext context,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Permite alterar o cancelar un estado antes de aplicarlo al objetivo.
  BattlerStatus? modifyOutgoingStatus({
    required Battler owner,
    required Battler target,
    required Item item,
    required BattlerStatus status,
  }) {
    return status;
  }

  /// Permite alterar o cancelar un estado recibido antes de que se aplique.
  BattlerStatus? modifyIncomingStatus({
    required Battler owner,
    required Battler source,
    required Item item,
    required BattlerStatus status,
  }) {
    return status;
  }

  /// Permite interceptar un golpe letal justo antes de que el portador muera.
  Battler onReceiveFatalDamage({
    required Battler owner,
    required Item item,
    required int incomingDamage,
  }) {
    return owner;
  }
}

/// Convierte el ataque basico en un doble golpe a cambio de reducir el ATK total.
class SunglassesItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para las Gafas de Sol.
  const SunglassesItemEffect()
      : super(
          description:
              'Tu ATK total se reduce a la mitad, redondeado hacia arriba y con minimo 1. A cambio, cada accion de ataque basico se resuelve dos veces.',
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
    final currentPoison = target.statusById('intoxicacion');
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

/// Aplica Quemadura al objetivo cada vez que el portador conecta un ataque.
class QuemaduraOnAttackItemEffect extends ItemEffect {
  final int duration;

  /// Crea un efecto reutilizable que anade Quemadura al atacar.
  const QuemaduraOnAttackItemEffect({
    this.duration = QuemaduraStatus.defaultDuration,
  }) : super(
          description:
              'Al atacar: anade un efecto de Quemadura de 3 turnos de duracion.',
        );

  @override

  /// Genera la descripcion final usando la duracion actual del objeto equipado.
  String descriptionFor(Item item) {
    final resolvedDuration = max(1, item.value > 0 ? item.value : duration);
    return 'Al atacar: anade Quemadura durante $resolvedDuration turnos.';
  }

  @override

  /// Tras atacar, aplica una Quemadura nueva con la duracion configurada.
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final resolvedDuration = max(1, item.value > 0 ? item.value : duration);
    return ItemEffectResolution(
      owner: owner,
      opponent: target.applyStatus(
        QuemaduraStatus(remainingTurns: resolvedDuration),
        source: owner,
      ),
    );
  }
}

/// Devuelve Quemadura al atacante cuando el portador recibe un golpe.
class QuemaduraOnHitReceivedItemEffect extends ItemEffect {
  final int duration;

  /// Crea un efecto reutilizable que castiga al rival al recibir dano.
  const QuemaduraOnHitReceivedItemEffect({
    this.duration = 4,
  }) : super(
          description:
              'Al recibir un ataque: anade un efecto de Quemadura de 4 turnos de duracion.',
        );

  @override

  /// Genera la descripcion final usando la duracion actual del objeto equipado.
  String descriptionFor(Item item) {
    final resolvedDuration = max(1, item.value > 0 ? item.value : duration);
    return 'Al recibir un ataque: anade Quemadura al agresor durante $resolvedDuration turnos.';
  }

  @override

  /// Tras recibir un golpe, aplica Quemadura al enemigo que lo causo.
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    final resolvedDuration = max(1, item.value > 0 ? item.value : duration);
    return ItemEffectResolution(
      owner: owner,
      opponent: source.applyStatus(
        QuemaduraStatus(remainingTurns: resolvedDuration),
        source: owner,
      ),
    );
  }
}

/// Reduce el cooldown de la primera habilidad manual resuelta en cada combate.
class CrackedBatteryItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para la Bateria Rajada.
  const CrackedBatteryItemEffect()
      : super(
          description:
              'La primera habilidad manual que se resuelve en combate reduce su cooldown restante.',
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'La primera habilidad manual que se resuelve en combate reduce su cooldown en ${item.value}.';
  }

  @override

  /// Detecta la primera entrada en cooldown y la acorta una sola vez por combate.
  ItemEffectResolution onAbilityResolved({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlerAbility previousAbility,
    required BattlerAbility resolvedAbility,
    required ItemAbilityResolutionContext context,
  }) {
    if (!owner.hasCombatFlag(Battler.combatActiveFlag)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }
    if (resolvedAbility.manualActivationContext !=
        BattlerAbilityActivationContext.battle) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }
    if (!_enteredCooldown(previousAbility, resolvedAbility)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final usedFlag = _itemFlag(item, 'battery_used');
    if (owner.hasCombatFlag(usedFlag)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final updatedAbility = resolvedAbility.reduceCooldown(item.value);
    return ItemEffectResolution(
      owner: owner.updateAbility(updatedAbility).addCombatFlag(usedFlag),
      opponent: opponent,
    );
  }
}

/// Aumenta el dano si el objetivo no tiene ningun buff activo.
class ImpactGlovesItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para los Guantes de Impacto.
  const ImpactGlovesItemEffect()
      : super(
          description:
              'Tus ataques infligen dano adicional si el objetivo no tiene buffs.',
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'Tus ataques infligen ${item.value} de dano adicional si el objetivo no tiene buffs.';
  }

  @override

  /// Suma dano solo cuando el objetivo esta completamente sin buffs.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damage,
  }) {
    final targetHasBuff = target.statuses.any(
      (status) => status.type == BattlerStatusType.buff,
    );
    if (targetHasBuff) return damage;

    return damage + item.value;
  }
}

/// Reduce la potencia de Quemadura e Intoxicacion al recibirlas.
class ChemicalFilterItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para el Filtro Quimico.
  const ChemicalFilterItemEffect()
      : super(
          description:
              'Reduce la Quemadura e Intoxicacion recibidas al aplicarse.',
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'Reduce la Quemadura e Intoxicacion recibidas en ${item.value} al aplicarse.';
  }

  @override

  /// Resta duracion o value al estado recibido y puede cancelarlo si llega a cero.
  BattlerStatus? modifyIncomingStatus({
    required Battler owner,
    required Battler source,
    required Item item,
    required BattlerStatus status,
  }) {
    if (status is QuemaduraStatus) {
      final nextTurns = max(0, status.remainingTurns - item.value);
      if (nextTurns <= 0) return null;

      return status.copyWith(remainingTurns: nextTurns);
    }

    if (status is IntoxicacionStatus) {
      final nextValue = max(0, status.value - item.value);
      if (nextValue <= 0) return null;

      return status.copyWith(value: nextValue);
    }

    return status;
  }
}

/// Solo cambia stats del item, asi que aqui solo personaliza la descripcion.
class BillingModuleItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para el Modulo de Cobro.
  const BillingModuleItemEffect()
      : super(
          description: 'Aumenta los ingresos, pero reduce la vida maxima.',
        );

  @override

  /// Explica a la UI cuanto income gana y cuanto HP maximo pierde el portador.
  String descriptionFor(Item item) {
    final healthPenalty = item.maxHealthPercentModifier.abs();
    final incomeGain = item.incomeModifier;
    final sign = item.maxHealthPercentModifier > 0 ? '+' : '-';

    return '+$incomeGain INCOME mientras este equipado. $sign$healthPenalty% HP MAX mientras este equipado.';
  }
}

/// Alarga las Quemaduras aplicadas y a cambio quema al propio portador al final de turno.
class PortableOvenItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para el Horno Portatil.
  const PortableOvenItemEffect()
      : super(
          description:
              'Tus Quemaduras duran mas, pero te quemas al final de tu turno.',
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'Las Quemaduras que aplicas duran ${item.value} turno mas. Al final de tu turno te aplicas Quemadura (${item.value}).';
  }

  @override

  /// Extiende solo las Quemaduras que el portador aplica a otros objetivos.
  BattlerStatus? modifyOutgoingStatus({
    required Battler owner,
    required Battler target,
    required Item item,
    required BattlerStatus status,
  }) {
    if (status is! QuemaduraStatus) return status;

    return status.copyWith(
      remainingTurns: status.remainingTurns + item.value,
    );
  }

  @override

  /// Al cerrar el turno propio, aplica una Quemadura al usuario.
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.applyStatus(
        QuemaduraStatus(remainingTurns: item.value),
        source: owner,
      ),
      opponent: opponent,
    );
  }
}

/// Cura al usuario cada vez que una habilidad suya entra en cooldown.
class ParasiticCapacitorItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para el Capacitador Parasitario.
  const ParasiticCapacitorItemEffect()
      : super(
          description:
              'Cuando una habilidad entra en cooldown, recuperas vida.',
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'Cuando una habilidad entra en cooldown, te curas ${item.value} HP.';
  }

  @override

  /// Detecta entradas en cooldown y cura al instante al portador.
  ItemEffectResolution onAbilityResolved({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlerAbility previousAbility,
    required BattlerAbility resolvedAbility,
    required ItemAbilityResolutionContext context,
  }) {
    if (!_enteredCooldown(previousAbility, resolvedAbility)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.heal(item.value),
      opponent: opponent,
    );
  }
}

/// Potencia la primera activacion manual de cada combate.
class EclipseMantleItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para el Manto de Eclipse.
  const EclipseMantleItemEffect()
      : super(
          description:
              'La primera activacion manual de cada combate obtiene un bonus al value.',
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'La primera activacion manual de cada combate obtiene +${item.value} al value.';
  }

  @override

  /// Aumenta temporalmente el value de la primera habilidad manual del combate.
  ItemAbilityPreparationResolution onManualAbilityPreparing({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    if (screenContext != BattlerAbilityActivationContext.battle ||
        !owner.hasCombatFlag(Battler.combatActiveFlag)) {
      return ItemAbilityPreparationResolution(
        owner: owner,
        opponent: opponent,
        ability: ability,
      );
    }

    final usedFlag = _itemFlag(item, 'eclipse_used');
    if (owner.hasCombatFlag(usedFlag)) {
      return ItemAbilityPreparationResolution(
        owner: owner,
        opponent: opponent,
        ability: ability,
      );
    }

    final boostedAbility = ability.addRuntimeValueBonus(item.value);
    final updatedOwner =
        owner.updateAbility(boostedAbility).addCombatFlag(usedFlag);

    return ItemAbilityPreparationResolution(
      owner: updatedOwner,
      opponent: opponent,
      ability: boostedAbility,
    );
  }
}

/// Evita una muerte por combate, deja 1 HP y refresca todas las habilidades.
class OperativeBlackBoxItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para la Caja Negra del Operativo.
  const OperativeBlackBoxItemEffect()
      : super(
          description:
              'Una vez por combate evita la muerte, deja 1 HP y refresca todas las habilidades.',
        );

  @override

  /// Genera la descripcion final usando la vida con la que deja al portador.
  String descriptionFor(Item item) {
    return 'Una vez por combate evita la muerte, te deja en ${max(1, item.value)} HP y refresca todas las habilidades.';
  }

  @override

  /// Intercepta el dano letal y aplica la proteccion una sola vez por combate.
  Battler onReceiveFatalDamage({
    required Battler owner,
    required Item item,
    required int incomingDamage,
  }) {
    if (!owner.hasCombatFlag(Battler.combatActiveFlag)) return owner;

    final usedFlag = _itemFlag(item, 'black_box_used');
    final protectionFlag = _itemFlag(item, 'black_box_protection');
    final recoveredHealth = max(1, item.value);

    if (owner.hasCombatFlag(protectionFlag)) {
      return owner.copyWith(health: recoveredHealth);
    }

    if (owner.hasCombatFlag(usedFlag)) return owner;

    return owner
        .copyWith(health: recoveredHealth)
        .resetAllAbilities()
        .addCombatFlag(usedFlag)
        .addCombatFlag(protectionFlag);
  }

  @override

  /// Limpia la proteccion temporal al inicio del siguiente turno propio.
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final protectionFlag = _itemFlag(item, 'black_box_protection');
    if (!owner.hasCombatFlag(protectionFlag)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.removeCombatFlag(protectionFlag),
      opponent: opponent,
    );
  }
}

/// Comprueba si una habilidad ha pasado de estar lista a estar en cooldown.
bool _enteredCooldown(
  BattlerAbility previousAbility,
  BattlerAbility resolvedAbility,
) {
  return !previousAbility.isOnCooldown && resolvedAbility.isOnCooldown;
}

/// Genera flags de combate estables para que cada item controle usos por instancia.
String _itemFlag(Item item, String suffix) {
  return '${item.instanceId ?? item.id.name}_$suffix';
}
