part of '../item_effect.dart';

/// Duplica el motor de Inercia generando ambas reservas al arrancar turno.
class InertiaCrownItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Corona de Inercia.
  const InertiaCrownItemEffect()
      : super(
          description:
              'Si tienes Inercia al inicio del turno, ganas ambas reservas.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, si tienes Inercia, ganas Reserva de Inercia: ATK (+${max(1, item.value)}) y Reserva de Inercia: Barrera (+${max(1, item.value)}).';
  }

  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn || !owner.hasStatus(InerciaStatus.statusId)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final resolvedValue = max(1, item.value);
    final ownerWithAttackReserve = owner.applyStatusFromSource(
      InerciaAtaqueStatus(value: resolvedValue),
      source: owner,
    );
    return ItemEffectResolution(
      owner: ownerWithAttackReserve.applyStatusFromSource(
        InerciaBarreraStatus(value: resolvedValue),
        source: ownerWithAttackReserve,
      ),
      opponent: opponent,
    );
  }
}

/// Entrega Calentando una sola vez al comenzar el primer turno propio del combate.
class ThermalTurbineItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Turbina Termica.
  const ThermalTurbineItemEffect()
      : super(
          description:
              'Al inicio del combate, ganas una reserva fuerte de Calentando.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al inicio del combate, ganas ${max(1, item.value)} Calentando. Solo ocurre una vez por combate.';
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
      ItemCombatFlagKind.thermalTurbineCombatStartTriggered,
    );
    if (owner.hasCombatFlag(triggeredFlag)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final amount = max(1, item.value);
    final currentStatus = owner.statusById(CalentandoStatus.statusId);
    final ownerWithFlag = owner.addCombatFlag(triggeredFlag);
    if (currentStatus is CalentandoStatus) {
      final resolvedStatus = currentStatus.resolved(ownerWithFlag);
      return ItemEffectResolution(
        owner: ownerWithFlag.applyStatus(
          resolvedStatus.copyWith(
            remainingTurns: max(
              resolvedStatus.remainingTurns,
              CalentandoStatus.defaultDuration,
            ),
            value: resolvedStatus.value + amount,
          ),
          applyEquipmentModifiers: false,
        ),
        opponent: opponent,
      );
    }

    return ItemEffectResolution(
      owner: ownerWithFlag.applyStatusFromSource(
        CalentandoStatus(value: amount),
        source: ownerWithFlag,
      ),
      opponent: opponent,
    );
  }
}

/// Consume Quemadura para convertirla en dano directo inmediato.
class SunExecutionBladeItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Hoja de Ejecucion Solar.
  const SunExecutionBladeItemEffect()
      : super(
          description:
              'Al usarse, consume la Quemadura del objetivo para infligir dano directo extra.',
          hooks: const {
            ItemEffectHook.patternUsed,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse, si el objetivo tiene Quemadura, la consume e inflige dano directo extra igual a su dano actual total + ${max(1, item.value)}.';
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final burnStatuses = target
        .statusesById(QuemaduraStatus.statusId)
        .whereType<QuemaduraStatus>()
        .toList(growable: false);
    if (burnStatuses.isEmpty) {
      return ItemEffectResolution(owner: owner, opponent: target);
    }

    final totalBurnDamage = burnStatuses.fold<int>(
      0,
      (sum, status) => sum + status.currentDamage(target),
    );
    final updatedTarget =
        target.removeStatus(QuemaduraStatus.statusId).receiveDirectDamage(
              totalBurnDamage + max(1, item.value),
              source: owner,
            );

    return ItemEffectResolution(
      owner: owner,
      opponent: updatedTarget,
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
              'Al usarse: anade un efecto de Quemadura de 3 turnos de duracion.',
          hooks: const {
            ItemEffectHook.patternUsed,
          },
        );

  @override

  /// Genera la descripcion final usando la duracion actual del objeto equipado.
  String descriptionFor(Item item) {
    final resolvedDuration = max(1, item.value > 0 ? item.value : duration);
    return 'Al usarse: anade Quemadura durante $resolvedDuration turnos.';
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
    return _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: target,
      status: QuemaduraStatus(remainingTurns: resolvedDuration),
    );
  }
}

/// Devuelve Quemadura al atacante cuando el portador recibe un golpe.
class QuemaduraOnHitReceivedItemEffect extends ItemEffect {
  final int duration;

  /// Crea un efecto reutilizable que castiga al rival al recibir daño.
  const QuemaduraOnHitReceivedItemEffect({
    this.duration = 4,
  }) : super(
          description:
              'Al recibir un ataque: anade un efecto de Quemadura de 4 turnos de duracion.',
          hooks: const {
            ItemEffectHook.receiveDamageResolved,
          },
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
    return _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: source,
      status: QuemaduraStatus(remainingTurns: resolvedDuration),
    );
  }
}

/// Aumenta el daño si el objetivo no tiene ningun buff activo.
class ImpactGlovesItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para los Guantes de Impacto.
  const ImpactGlovesItemEffect()
      : super(
          description:
              'Tus ataques infligen daño adicional si el objetivo no tiene buffs.',
          hooks: const {
            ItemEffectHook.outgoingDamageModifier,
          },
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'Tus ataques infligen ${item.value} de daño adicional si el objetivo no tiene buffs.';
  }

  @override

  /// Suma daño solo cuando el objetivo esta completamente sin buffs.
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
          hooks: const {
            ItemEffectHook.incomingStatusModifier,
          },
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

/// No aporta potencia directa, pero se revaloriza cada vez que sobrevives con el equipado.
class PagareRevalorizableItemEffect extends ItemEffect {
  /// Crea el efecto propio del Pagare Revalorizable.
  const PagareRevalorizableItemEffect()
      : super(
          description:
              'No hace nada en combate. Al terminar un combate equipado, aumenta su precio de venta.',
          hooks: const {
            ItemEffectHook.combatEnd,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al terminar un combate equipado, aumenta su precio de venta en ${item.value}C.';
  }

  @override
  Battler onCombatEnd({
    required Battler owner,
    required Item item,
  }) {
    return _replaceOwnedItem(
      owner: owner,
      currentItem: item,
      replacement: item.copyWith(
        sellValueBonus: item.sellValueBonus + item.value,
      ),
    );
  }
}

/// Convierte caja operativa en una pequena reposicion defensiva estable.
class MochilaStronkboxItemEffect extends ItemEffect {
  static const requiredMoney = 10;

  /// Crea el efecto propio de la Mochila Stronkbox.
  const MochilaStronkboxItemEffect()
      : super(
          description:
              'Al inicio de tu turno, si conservas suficiente dinero, recuperas barrera.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, si tienes al menos ${requiredMoney}C, recuperas ${max(1, item.value)} de Barrera.';
  }

  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn || owner.money < requiredMoney) {
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

/// Premia guardar mercancia ajena en el inventario con curacion ofensiva.
class MuestrarioContrabandoItemEffect extends ItemEffect {
  static const healCap = 10;

  /// Crea el efecto propio del Muestrario de Contrabando.
  const MuestrarioContrabandoItemEffect()
      : super(
          description:
              'Al usarse, convierte el contrabando sin equipar en curacion inmediata.',
          hooks: const {
            ItemEffectHook.patternUsed,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse, te curas ${max(1, item.value)} HP por cada item de otro arquetipo en tu inventario, hasta $healCap HP.';
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final foreignInventoryItems = _countForeignInventoryItemsForMercante(owner);
    if (foreignInventoryItems <= 0) {
      return ItemEffectResolution(owner: owner, opponent: target);
    }

    final healAmount = min(
      healCap,
      max(1, item.value) * foreignInventoryItems,
    );
    return ItemEffectResolution(
      owner: owner.heal(healAmount),
      opponent: target,
    );
  }
}

/// Convierte el catalogo ajeno acumulado en pegada ofensiva permanente.
class RoperaUnidaItemEffect extends ItemEffect {
  static const attackCap = 8;

  /// Crea el efecto propio de la Ropera Unida.
  const RoperaUnidaItemEffect()
      : super(
          description:
              'Otorga ataque adicional segun la mercancia ajena que guardas.',
          hooks: const {
            ItemEffectHook.calculatedStatModifier,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Obtienes +ATK igual a ${max(1, item.value)} + el numero de items de otro arquetipo que posees, hasta $attackCap.';
  }

  @override
  int modifyCalculatedStat({
    required Battler owner,
    required Item item,
    required BattlerStat stat,
    required int value,
  }) {
    if (stat != BattlerStat.attack) return value;

    final foreignOwnedItems = _countForeignOwnedItemsForMercante(owner);
    final attackBonus = min(
      attackCap,
      max(1, item.value) + foreignOwnedItems,
    );
    return value + attackBonus;
  }
}

/// Alarga las Quemaduras aplicadas y a cambio quema al propio portador al final de turno.
class PortableOvenItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para el Horno Portatil.
  const PortableOvenItemEffect()
      : super(
          description:
              'Tus Quemaduras duran mas, pero te quemas al final de tu turno.',
          hooks: const {
            ItemEffectHook.turnEnd,
            ItemEffectHook.outgoingStatusModifier,
          },
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
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.applyStatusFromSource(
        QuemaduraStatus(remainingTurns: item.value),
        source: owner,
      ),
      opponent: opponent,
    );
  }
}

/// Evita una muerte por combate y deja al portador con vida.
class OperativeBlackBoxItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para la Caja Negra del Operativo.
  const OperativeBlackBoxItemEffect()
      : super(
          description:
              'Una vez por combate evita la muerte y deja al portador con vida.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.fatalDamage,
          },
        );

  @override

  /// Genera la descripcion final usando la vida con la que deja al portador.
  String descriptionFor(Item item) {
    return 'Una vez por combate evita la muerte y te deja en ${max(1, item.value)} HP.';
  }

  @override

  /// Intercepta el daño letal y aplica la proteccion una sola vez por combate.
  Battler onReceiveFatalDamage({
    required Battler owner,
    required Item item,
    required int incomingDamage,
  }) {
    if (!owner.hasCombatFlag(Battler.combatActiveFlag)) return owner;

    final usedFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.operativeBlackBoxUsed,
    );
    final protectionFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.operativeBlackBoxProtection,
    );
    final recoveredHealth = max(1, item.value);

    if (owner.hasCombatFlag(protectionFlag)) {
      return owner.copyWith(health: recoveredHealth);
    }

    if (owner.hasCombatFlag(usedFlag)) return owner;

    return owner
        .copyWith(health: recoveredHealth)
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
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final protectionFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.operativeBlackBoxProtection,
    );
    if (!owner.hasCombatFlag(protectionFlag)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.removeCombatFlag(protectionFlag),
      opponent: opponent,
    );
  }
}

/// Enumera los estados "nuevos" que pueden ser aplicados por objetos.
enum ItemStatusEffectKind {
  calentando,
  conmocion,
  fragilidad,
  inercia,
  inerciaAtaque,
  inerciaBarrera,
}

/// Identifica en que momento del combate un objeto genera uno de esos estados.
enum ItemStatusEffectTrigger {
  attackTarget,
  attackOwner,
  attackOwnerReinforce,
  receiveDamageSource,
  receiveDamageOwner,
  turnStartOwnerRefreshMinimum,
  turnStartOwnerIfMissing,
}

/// Aplica estados reutilizando una unica pieza de logica segun trigger y tipo.
class StatusItemEffect extends ItemEffect {
  final ItemStatusEffectKind kind;
  final ItemStatusEffectTrigger trigger;

  /// Crea un efecto parametrico para objetos que solo introducen estados.
  const StatusItemEffect({
    required this.kind,
    required this.trigger,
  }) : super(
          description: 'Aplica un estado contextual.',
          hooks: trigger == ItemStatusEffectTrigger.attackTarget ||
                  trigger == ItemStatusEffectTrigger.attackOwner ||
                  trigger == ItemStatusEffectTrigger.attackOwnerReinforce
              ? const {
                  ItemEffectHook.patternUsed,
                }
              : trigger == ItemStatusEffectTrigger.receiveDamageSource ||
                      trigger == ItemStatusEffectTrigger.receiveDamageOwner
                  ? const {
                      ItemEffectHook.receiveDamageResolved,
                    }
                  : const {
                      ItemEffectHook.turnStart,
                    },
        );

  @override
  String descriptionFor(Item item) {
    final phrase = _statusPhrase(item);

    switch (trigger) {
      case ItemStatusEffectTrigger.attackTarget:
        return 'Al usarse: aplica $phrase al enemigo.';
      case ItemStatusEffectTrigger.attackOwner:
        return 'Al usarse: ganas $phrase.';
      case ItemStatusEffectTrigger.attackOwnerReinforce:
        return 'Al usarse: genera o aumenta $phrase.';
      case ItemStatusEffectTrigger.receiveDamageSource:
        return 'Al recibir daño: aplica $phrase al agresor.';
      case ItemStatusEffectTrigger.receiveDamageOwner:
        return 'Al recibir daño: ganas $phrase.';
      case ItemStatusEffectTrigger.turnStartOwnerRefreshMinimum:
        return 'Al inicio de tu turno, recuperas $phrase.';
      case ItemStatusEffectTrigger.turnStartOwnerIfMissing:
        return 'Al inicio de tu turno, si no lo tienes, ganas $phrase.';
    }
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

    switch (trigger) {
      case ItemStatusEffectTrigger.turnStartOwnerRefreshMinimum:
      case ItemStatusEffectTrigger.turnStartOwnerIfMissing:
        return ItemEffectResolution(
          owner: _applyToOwner(
            owner: owner,
            source: owner,
            item: item,
          ),
          opponent: opponent,
        );
      case ItemStatusEffectTrigger.attackTarget:
      case ItemStatusEffectTrigger.attackOwner:
      case ItemStatusEffectTrigger.attackOwnerReinforce:
      case ItemStatusEffectTrigger.receiveDamageSource:
      case ItemStatusEffectTrigger.receiveDamageOwner:
        return ItemEffectResolution(owner: owner, opponent: opponent);
    }
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    switch (trigger) {
      case ItemStatusEffectTrigger.attackTarget:
        return _applyStatusToOpponentFromOwner(
          owner: owner,
          opponent: target,
          status: _buildStatus(item),
        );
      case ItemStatusEffectTrigger.attackOwner:
      case ItemStatusEffectTrigger.attackOwnerReinforce:
        return ItemEffectResolution(
          owner: _applyToOwner(
            owner: owner,
            source: owner,
            item: item,
          ),
          opponent: target,
        );
      case ItemStatusEffectTrigger.receiveDamageSource:
      case ItemStatusEffectTrigger.receiveDamageOwner:
      case ItemStatusEffectTrigger.turnStartOwnerRefreshMinimum:
      case ItemStatusEffectTrigger.turnStartOwnerIfMissing:
        return ItemEffectResolution(owner: owner, opponent: target);
    }
  }

  @override
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    switch (trigger) {
      case ItemStatusEffectTrigger.receiveDamageSource:
        return _applyStatusToOpponentFromOwner(
          owner: owner,
          opponent: source,
          status: _buildStatus(item),
        );
      case ItemStatusEffectTrigger.receiveDamageOwner:
        return ItemEffectResolution(
          owner: _applyToOwner(
            owner: owner,
            source: owner,
            item: item,
          ),
          opponent: source,
        );
      case ItemStatusEffectTrigger.attackTarget:
      case ItemStatusEffectTrigger.attackOwner:
      case ItemStatusEffectTrigger.attackOwnerReinforce:
      case ItemStatusEffectTrigger.turnStartOwnerRefreshMinimum:
      case ItemStatusEffectTrigger.turnStartOwnerIfMissing:
        return ItemEffectResolution(owner: owner, opponent: source);
    }
  }

  Battler _applyToOwner({
    required Battler owner,
    required Battler source,
    required Item item,
  }) {
    final status = _buildStatus(item);

    switch (trigger) {
      case ItemStatusEffectTrigger.turnStartOwnerIfMissing:
        if (owner.hasStatus(status.id)) return owner;

        return owner.applyStatusFromSource(
          status,
          source: source,
        );
      case ItemStatusEffectTrigger.turnStartOwnerRefreshMinimum:
        final currentStatus = owner.statusById(status.id);
        if (currentStatus != null &&
            currentStatus.resolved(owner).value >= status.value) {
          return owner;
        }

        final refreshedOwner =
            currentStatus == null ? owner : owner.removeStatus(status.id);
        return refreshedOwner.applyStatusFromSource(
          status,
          source: source,
        );
      case ItemStatusEffectTrigger.attackOwnerReinforce:
        if (kind != ItemStatusEffectKind.calentando) {
          return owner.applyStatusFromSource(
            status,
            source: source,
          );
        }

        final currentStatus = owner.statusById(CalentandoStatus.statusId);
        if (currentStatus is! CalentandoStatus) {
          return owner.applyStatusFromSource(
            status,
            source: source,
          );
        }

        return owner.applyStatus(
          currentStatus.copyWith(
            value: currentStatus.value + status.value,
            remainingTurns: max(
              currentStatus.remainingTurns,
              status.remainingTurns,
            ),
          ),
          applyEquipmentModifiers: false,
        );
      case ItemStatusEffectTrigger.attackOwner:
      case ItemStatusEffectTrigger.receiveDamageOwner:
        return owner.applyStatusFromSource(
          status,
          source: source,
        );
      case ItemStatusEffectTrigger.attackTarget:
      case ItemStatusEffectTrigger.receiveDamageSource:
        return owner;
    }
  }

  BattlerStatus _buildStatus(Item item) {
    final resolvedValue = max(1, item.value);

    switch (kind) {
      case ItemStatusEffectKind.calentando:
        return CalentandoStatus(value: resolvedValue);
      case ItemStatusEffectKind.conmocion:
        return ConmocionStatus(value: resolvedValue);
      case ItemStatusEffectKind.fragilidad:
        return FragilidadStatus(value: resolvedValue);
      case ItemStatusEffectKind.inercia:
        return InerciaStatus(value: resolvedValue);
      case ItemStatusEffectKind.inerciaAtaque:
        return InerciaAtaqueStatus(value: resolvedValue);
      case ItemStatusEffectKind.inerciaBarrera:
        return InerciaBarreraStatus(value: resolvedValue);
    }
  }

  String _statusPhrase(Item item) {
    final resolvedValue = max(1, item.value);

    switch (kind) {
      case ItemStatusEffectKind.calentando:
        return 'Calentando (+$resolvedValue daño)';
      case ItemStatusEffectKind.conmocion:
        return 'Conmocion (-$resolvedValue daño en el siguiente ataque)';
      case ItemStatusEffectKind.fragilidad:
        return 'Fragilidad ($resolvedValue acumulacion)';
      case ItemStatusEffectKind.inercia:
        return 'Inercia (+$resolvedValue por acumulacion)';
      case ItemStatusEffectKind.inerciaAtaque:
        return 'Reserva de Inercia: ATK (+$resolvedValue)';
      case ItemStatusEffectKind.inerciaBarrera:
        return 'Reserva de Inercia: Barrera (+$resolvedValue)';
    }
  }
}
