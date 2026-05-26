part of '../item_effect.dart';

/// Entrega Calentando una sola vez al comenzar el combate.
class ThermalTurbineItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Turbina Termica.
  const ThermalTurbineItemEffect()
      : super(
          description:
              'Al inicio del combate, ganas una reserva fuerte de Calentando.',
          hooks: const {
            ItemEffectHook.combatStart,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al inicio del combate, ganas ${max(1, item.value)} Calentando. Solo ocurre una vez por combate.';
  }

  @override
  ItemEffectResolution onCombatStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    RunRandomizer? randomizer,
  }) {
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

/// Describe la generacion de botin extra que resuelve la pantalla de recompensas.
class VirtualMailboxItemEffect extends ItemEffect {
  /// Crea el efecto comun de los Buzones Virtuales.
  const VirtualMailboxItemEffect()
      : super(
          description:
              'Al ganar un combate, anade un item aleatorio de su categoria a las recompensas si tienes espacio.',
        );

  @override
  String descriptionFor(Item item) {
    final focusLabel = _focusTagFor(item).label;
    final statLine = item.id == ItemId.buzonVirtualAzul
        ? '+1 PP mientras este equipado. '
        : '';
    return '${statLine}Al terminar un combate, si tienes espacio, ofrece un item ${item.rarity.label} aleatorio con tag $focusLabel en la pantalla de recompensas.';
  }

  EntityTag _focusTagFor(Item item) {
    switch (item.id) {
      case ItemId.buzonVirtualAzul:
        return item.rarity.index <= RarityTier.gray.index
            ? EntityTag.accesorio
            : EntityTag.ciclo;
      case ItemId.buzonVirtualRojo:
        return item.rarity.index <= RarityTier.gray.index
            ? EntityTag.ataque
            : EntityTag.quemadura;
      case ItemId.buzonVirtualVerde:
        return item.rarity.index <= RarityTier.green.index
            ? EntityTag.barrera
            : EntityTag.resonancia;
      default:
        return EntityTag.economia;
    }
  }
}

class TaladronItemEffect extends ItemEffect {
  const TaladronItemEffect()
      : super(
          description:
              'Al usarse: destruye las Murallas atravesadas despues de este punto.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse: Todas las Murallas atravesadas despues de este punto son destruidas.';
  }

  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    final itemPointKey = _assignedPointKeyForItem(owner: owner, item: item);
    if (itemPointKey == null) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final sequence = pattern.sequence;
    final startIndex =
        sequence.indexWhere((point) => point.key == itemPointKey);
    if (startIndex < 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final crossedWalls = opponent.combatWallsCrossedBy(
      sequence,
      startIndex: startIndex,
    );
    if (crossedWalls.isEmpty) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return _destroyOpponentWalls(
      owner: owner,
      opponent: opponent,
      walls: crossedWalls,
    );
  }
}

class CuboDinamitalicoItemEffect extends ItemEffect {
  const CuboDinamitalicoItemEffect()
      : super(
          description:
              'Al comienzo del combate, destruye cualquier Muralla adyacente a su posicion.',
          hooks: const {ItemEffectHook.combatStart},
        );

  @override
  String descriptionFor(Item item) {
    return 'Al comienzo del combate, destruye cualquier Muralla adyacente a su posicion.';
  }

  @override
  ItemEffectResolution onCombatStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    RunRandomizer? randomizer,
  }) {
    final point = _assignedPointForItem(owner: owner, item: item);
    if (point == null) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final adjacentWalls = opponent.combatWallsAdjacentTo(point);
    return _destroyOpponentWalls(
      owner: owner,
      opponent: opponent,
      walls: adjacentWalls,
    );
  }
}

class MedidorRoturaItemEffect extends ItemEffect {
  const MedidorRoturaItemEffect()
      : super(
          description: 'Ganas ataque por cada Muralla destruida este combate.',
          hooks: const {ItemEffectHook.calculatedStatModifier},
        );

  @override
  String descriptionFor(Item item) {
    return 'Ganas +${max(1, item.value)} ataque por cada Muralla destruida este combate.';
  }

  @override
  int modifyCalculatedStat({
    required Battler owner,
    required Item item,
    required BattlerStat stat,
    required int value,
  }) {
    if (stat != BattlerStat.attack) return value;

    return value + (max(1, item.value) * owner.combatDestroyedWallCount);
  }
}

class MurallaAutomaticaItemEffect extends ItemEffect {
  const MurallaAutomaticaItemEffect()
      : super(
          description:
              'Al comienzo del combate, crea Murallas en la matriz enemiga.',
          hooks: const {ItemEffectHook.combatStart},
        );

  @override
  String descriptionFor(Item item) {
    return 'Al comienzo del combate, crea ${max(1, item.value)} Murallas en la matriz enemiga.';
  }

  @override
  ItemEffectResolution onCombatStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    RunRandomizer? randomizer,
  }) {
    final walls = _randomAvailableWalls(
      existingWalls: opponent.combatWallSegments,
      count: max(1, item.value),
      nextInt: randomizer?.nextInt ?? Random().nextInt,
    );
    return ItemEffectResolution(
      owner: owner,
      opponent: opponent.addCombatWalls(walls),
    );
  }
}

class LiteralPaywallItemEffect extends ItemEffect {
  const LiteralPaywallItemEffect()
      : super(
          description:
              'Al usarse: al final del turno, paga creditos para crear una Muralla para el enemigo.',
          hooks: const {ItemEffectHook.patternUsed, ItemEffectHook.turnEnd},
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse: al final del turno, paga ${max(0, item.value)} creditos si es posible para crear una Muralla para el enemigo.';
  }

  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    return ItemEffectResolution(
      owner: owner.addCombatFlag(
        CombatRuntimeFlag.item(
          itemFlag: ItemCombatFlagKind.literalPaywallPendingWall,
          itemId: item.id,
          itemInstanceId: item.instanceId,
          secondaryValue: max(0, item.value),
        ),
      ),
      opponent: opponent,
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

    final pendingFlags = owner.combatFlags.where((flag) {
      return flag.itemFlag == ItemCombatFlagKind.literalPaywallPendingWall &&
          flag.itemId == item.id &&
          flag.itemInstanceId == item.instanceId;
    }).toList(growable: false);
    if (pendingFlags.isEmpty) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    var updatedOwner = owner.removeItemCombatFlagsFor(
      item: item,
      kind: ItemCombatFlagKind.literalPaywallPendingWall,
    );
    var updatedOpponent = opponent;
    final nextInt = randomizer?.nextInt ?? Random().nextInt;
    for (final flag in pendingFlags) {
      final cost = max(0, flag.secondaryValue ?? item.value);
      if (!updatedOwner.canAfford(cost)) continue;

      final walls = _randomAvailableWalls(
        existingWalls: updatedOpponent.combatWallSegments,
        count: 1,
        nextInt: nextInt,
      );
      if (walls.isEmpty) continue;

      updatedOwner = updatedOwner.spendMoney(cost);
      updatedOpponent = updatedOpponent.addCombatWalls(walls);
    }

    return ItemEffectResolution(owner: updatedOwner, opponent: updatedOpponent);
  }
}

class PassCardItemEffect extends ItemEffect {
  const PassCardItemEffect()
      : super(
          description:
              'Al usarse, al final del turno paga creditos para desactivar las Murallas de tu matriz durante tu proximo turno.',
          hooks: const {
            ItemEffectHook.patternUsed,
            ItemEffectHook.turnStart,
            ItemEffectHook.turnEnd,
          },
        );

  @override
  String descriptionFor(Item item) {
    return '+1 BP mientras este equipado. Al usarse: al final del turno, paga ${max(0, item.value)} creditos si es posible. Durante tu proximo turno, las Murallas de tu matriz quedan desactivadas: se ven atenuadas y puedes atravesarlas.';
  }

  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    final cost = max(0, item.value);
    return ItemEffectResolution(
      owner: owner.addCombatFlag(
        CombatRuntimeFlag.item(
          itemFlag: ItemCombatFlagKind.passCardPendingPayment,
          itemId: item.id,
          itemInstanceId: item.instanceId,
          secondaryValue: cost,
        ),
      ),
      opponent: opponent,
    );
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

    final pendingFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.passCardWallsDisabledNextTurn,
    );
    if (!owner.hasCombatFlag(pendingFlag)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.removeCombatFlag(pendingFlag).addCombatFlag(
            _itemCombatFlag(
              item,
              ItemCombatFlagKind.passCardWallsDisabledThisTurn,
            ),
          ),
      opponent: opponent,
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

    var updatedOwner = owner.removeItemCombatFlagsFor(
      item: item,
      kind: ItemCombatFlagKind.passCardWallsDisabledThisTurn,
    );

    final pendingPayments = updatedOwner.combatFlags.where((flag) {
      return flag.itemFlag == ItemCombatFlagKind.passCardPendingPayment &&
          flag.itemId == item.id &&
          flag.itemInstanceId == item.instanceId;
    }).toList(growable: false);
    if (pendingPayments.isEmpty) {
      return ItemEffectResolution(owner: updatedOwner, opponent: opponent);
    }

    updatedOwner = updatedOwner.removeItemCombatFlagsFor(
      item: item,
      kind: ItemCombatFlagKind.passCardPendingPayment,
    );
    for (final pendingPayment in pendingPayments) {
      final cost = max(0, pendingPayment.secondaryValue ?? item.value);
      if (!updatedOwner.canAfford(cost)) continue;

      updatedOwner = updatedOwner.spendMoney(cost).addCombatFlag(
            CombatRuntimeFlag.item(
              itemFlag: ItemCombatFlagKind.passCardWallsDisabledNextTurn,
              itemId: item.id,
              itemInstanceId: item.instanceId,
            ),
          );
    }

    return ItemEffectResolution(owner: updatedOwner, opponent: opponent);
  }
}

class TonfasEscudoItemEffect extends ItemEffect {
  const TonfasEscudoItemEffect()
      : super(
          description:
              'Puedes poner o mover una Muralla mas por turno, pero tienes -1 BP maximo.',
          hooks: const {
            ItemEffectHook.passive,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Puedes poner o mover una Muralla mas por turno para bloquear a tu oponente, pero -1 BP maximo.';
  }
}

class ConstructionSealItemEffect extends ItemEffect {
  const ConstructionSealItemEffect()
      : super(
          description:
              'Al principio de turno, te curas segun tus BP restantes. Al usarse, destruye una Muralla al final de tu turno.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.turnEnd,
          },
        );

  @override
  String descriptionFor(Item item) {
    return '+4 BP mientras este equipado. Al principio de turno: te curas ${max(0, item.value)} veces tus BP restantes. Al usarse: al final de tu turno, destruye una Muralla en tu tablero o en el de tu enemigo.';
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

    final remainingBp = max(
      0,
      OperativePatternCombatRules.maxBlockingPointsFor(owner) -
          opponent.combatWallSegments.length,
    );
    final healing = max(0, item.value) * remainingBp;
    return ItemEffectResolution(
      owner: healing > 0 ? owner.heal(healing) : owner,
      opponent: opponent,
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

    var updatedOwner = owner;
    var updatedOpponent = opponent;
    final candidates = <({bool ownerBoard, OperativePatternWallSegment wall})>[
      for (final wall in updatedOwner.combatWallSegments)
        (ownerBoard: true, wall: wall),
      for (final wall in updatedOpponent.combatWallSegments)
        (ownerBoard: false, wall: wall),
    ];
    if (candidates.isEmpty) {
      return ItemEffectResolution(
        owner: updatedOwner,
        opponent: updatedOpponent,
      );
    }

    final nextInt = randomizer?.nextInt ?? Random().nextInt;
    final selected = candidates[nextInt(candidates.length)];
    if (selected.ownerBoard) {
      updatedOwner = updatedOwner.destroyCombatWalls([selected.wall]);
    } else {
      updatedOpponent = updatedOpponent.destroyCombatWalls([selected.wall]);
    }
    updatedOwner = updatedOwner.recordDestroyedCombatWalls(1);

    return ItemEffectResolution(
      owner: updatedOwner,
      opponent: updatedOpponent,
    );
  }
}

class BarbedShieldItemEffect extends ItemEffect {
  const BarbedShieldItemEffect()
      : super(
          description:
              'Al usarse: hace dano al enemigo al final del turno segun las Murallas en ambas matrices.',
          hooks: const {ItemEffectHook.patternUsed, ItemEffectHook.turnEnd},
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse: Hace dano al enemigo al final del turno igual a ${max(1, item.value)} veces el numero de Murallas en tu matriz y en la del enemigo.';
  }

  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    return ItemEffectResolution(
      owner: owner.addCombatFlag(
        CombatRuntimeFlag.item(
          itemFlag: ItemCombatFlagKind.barbedShieldPendingDamage,
          itemId: item.id,
          itemInstanceId: item.instanceId,
          secondaryValue: max(1, item.value),
        ),
      ),
      opponent: opponent,
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

    final pendingFlags = owner.combatFlags.where((flag) {
      return flag.itemFlag == ItemCombatFlagKind.barbedShieldPendingDamage &&
          flag.itemId == item.id &&
          flag.itemInstanceId == item.instanceId;
    }).toList(growable: false);
    if (pendingFlags.isEmpty) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final multiplier = pendingFlags.fold<int>(
      0,
      (total, flag) => total + max(1, flag.secondaryValue ?? item.value),
    );
    final wallCount =
        owner.combatWallSegments.length + opponent.combatWallSegments.length;
    final damage = multiplier * wallCount;
    return ItemEffectResolution(
      owner: owner.removeItemCombatFlagsFor(
        item: item,
        kind: ItemCombatFlagKind.barbedShieldPendingDamage,
      ),
      opponent: damage <= 0
          ? opponent
          : opponent.receiveDirectDamage(damage, source: owner),
    );
  }
}

class PilarAceroItemEffect extends ItemEffect {
  const PilarAceroItemEffect()
      : super(
          description:
              'Al usarse: crea Murallas temporales alrededor de su punto.',
          hooks: const {ItemEffectHook.patternUsed, ItemEffectHook.turnEnd},
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse: Crea Murallas al rededor de su punto al final del turno, que duran un turno, tanto en tu matriz como en la del enemigo.';
  }

  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    final point = _assignedPointForItem(owner: owner, item: item);
    if (point == null) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final walls = _wallsAroundPoint(point);
    return ItemEffectResolution(
      owner: owner.queueTemporaryCombatWalls(walls),
      opponent: opponent.queueTemporaryCombatWalls(walls),
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

    return ItemEffectResolution(
      owner: owner
          .expireTemporaryCombatWalls()
          .activateQueuedTemporaryCombatWalls(),
      opponent: opponent
          .expireTemporaryCombatWalls()
          .activateQueuedTemporaryCombatWalls(),
    );
  }
}

class DuplicadorAtomosItemEffect extends ItemEffect {
  const DuplicadorAtomosItemEffect()
      : super(
          description:
              'Al usarse: copia Murallas de tu matriz a la del enemigo.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse: Copia ${max(1, item.value)} Murallas en tu matriz a la de tu enemigo.';
  }

  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    return ItemEffectResolution(
      owner: owner,
      opponent: opponent.addCombatWalls(
        owner.combatWallSegments.take(max(1, item.value)),
      ),
    );
  }
}

class CortinaHumoItemEffect extends ItemEffect {
  const CortinaHumoItemEffect()
      : super(
          description:
              'Al usarse: mueve Murallas de tu matriz a la del enemigo.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse: Mueve ${max(1, item.value)} Murallas de tu matriz a la del enemigo.';
  }

  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    final movedWalls = owner.combatWallSegments
        .take(max(1, item.value))
        .toList(growable: false);
    if (movedWalls.isEmpty) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.destroyCombatWalls(movedWalls),
      opponent: opponent.addCombatWalls(movedWalls),
    );
  }
}

ItemEffectResolution _destroyOpponentWalls({
  required Battler owner,
  required Battler opponent,
  required Iterable<OperativePatternWallSegment> walls,
}) {
  final wallsToDestroy = walls.toList(growable: false);
  if (wallsToDestroy.isEmpty) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  final beforeCount = opponent.combatWallSegments.length;
  final updatedOpponent = opponent.destroyCombatWalls(wallsToDestroy);
  final destroyedCount =
      beforeCount - updatedOpponent.combatWallSegments.length;
  return ItemEffectResolution(
    owner: owner.recordDestroyedCombatWalls(destroyedCount),
    opponent: updatedOpponent,
  );
}

String? _assignedPointKeyForItem({
  required Battler owner,
  required Item item,
}) {
  final instanceKey = item.instanceId;
  if (instanceKey != null) {
    final pointKey = owner.patternItemPointKeys[instanceKey];
    if (pointKey != null) return pointKey;
  }
  return owner.patternItemPointKeys[item.id.name];
}

OperativePatternPoint? _assignedPointForItem({
  required Battler owner,
  required Item item,
}) {
  final pointKey = _assignedPointKeyForItem(owner: owner, item: item);
  if (pointKey == null) return null;

  for (final point in operativePatternPoints) {
    if (point.key == pointKey) return point;
  }
  return null;
}

List<OperativePatternWallSegment> _wallsAroundPoint(
  OperativePatternPoint point,
) {
  final walls = <OperativePatternWallSegment>[];
  for (final delta in const [
    (x: 0, y: 1),
    (x: 1, y: 0),
    (x: 0, y: -1),
    (x: -1, y: 0),
  ]) {
    final neighbor = operativePatternPointAt(
      x: point.x + delta.x,
      y: point.y + delta.y,
    );
    if (neighbor == null) continue;
    walls.add(OperativePatternWallSegment(a: point, b: neighbor));
  }
  return List<OperativePatternWallSegment>.unmodifiable(walls);
}

List<OperativePatternWallSegment> _randomAvailableWalls({
  required Iterable<OperativePatternWallSegment> existingWalls,
  required int count,
  required int Function(int max) nextInt,
}) {
  final existingKeys = existingWalls.map((wall) => wall.key).toSet();
  final candidates = <OperativePatternWallSegment>[];
  for (final point in operativePatternPoints) {
    for (final delta in const [
      (x: 1, y: 0),
      (x: 0, y: 1),
    ]) {
      final neighbor = operativePatternPointAt(
        x: point.x + delta.x,
        y: point.y + delta.y,
      );
      if (neighbor == null) continue;

      final wall = OperativePatternWallSegment(a: point, b: neighbor);
      if (!existingKeys.contains(wall.key)) {
        candidates.add(wall);
      }
    }
  }

  final remaining = List<OperativePatternWallSegment>.from(candidates);
  final picked = <OperativePatternWallSegment>[];
  while (picked.length < count && remaining.isNotEmpty) {
    picked.add(remaining.removeAt(nextInt(remaining.length)));
  }
  return List<OperativePatternWallSegment>.unmodifiable(picked);
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

class VialRotoItemEffect extends ItemEffect {
  const VialRotoItemEffect()
      : super(
          description: 'Al principio del combate, aplica Contagio al enemigo.',
          hooks: const {ItemEffectHook.combatStart},
        );

  @override
  String descriptionFor(Item item) {
    return 'Al principio del combate, aplica ${max(1, item.value)} Contagio al enemigo.';
  }

  @override
  ItemEffectResolution onCombatStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    RunRandomizer? randomizer,
  }) {
    return _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: ContagioStatus(value: max(1, item.value)),
    );
  }
}

class PlumaSepticaItemEffect extends ItemEffect {
  const PlumaSepticaItemEffect()
      : super(
          description: 'Al usarse: aplica debuffos aleatorios al enemigo.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse: aplica ${max(1, item.value)} veces un debuff aleatorio al enemigo.';
  }

  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;
    final randomizer = RunRandomizer();

    for (var i = 0; i < max(1, item.value); i++) {
      final status = switch (randomizer.nextInt(4)) {
        0 => const QuemaduraStatus(remainingTurns: 1),
        1 => const IntoxicacionStatus(value: 1),
        2 => const FragilidadStatus(value: 1),
        _ => const ConmocionStatus(value: 1),
      };
      final resolution = _applyStatusToOpponentFromOwner(
        owner: updatedOwner,
        opponent: updatedOpponent,
        status: status,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return ItemEffectResolution(
      owner: updatedOwner,
      opponent: updatedOpponent,
    );
  }
}

class LanzaSuciaItemEffect extends ItemEffect {
  const LanzaSuciaItemEffect()
      : super(
          description:
              'Al usarse contra un enemigo con debuff, aplica Contagio.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse contra un enemigo con debuff, aplica ${max(1, item.value)} Contagio.';
  }

  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    if (!_hasAnyDebuff(opponent)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: ContagioStatus(value: max(1, item.value)),
    );
  }
}

class AmpollaInestableItemEffect extends ItemEffect {
  const AmpollaInestableItemEffect()
      : super(
          description:
              'Al usarse: aplica Contagio. Si ya tenia Contagio, aplica Fragilidad.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  @override
  String descriptionFor(Item item) {
    final amount = max(1, item.value);
    return 'Al usarse: aplica $amount Contagio. Si el enemigo ya tenia Contagio, aplica ${amount * 2} Fragilidad.';
  }

  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    final hadContagio = opponent.hasStatus(ContagioStatus.statusId);
    final contagioResolution = _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: ContagioStatus(value: max(1, item.value)),
    );
    if (!hadContagio) return contagioResolution;

    return _applyStatusToOpponentFromOwner(
      owner: contagioResolution.owner,
      opponent: contagioResolution.opponent,
      status: FragilidadStatus(value: max(1, item.value) * 2),
    );
  }
}

class TuboCultivoItemEffect extends ItemEffect {
  const TuboCultivoItemEffect()
      : super(
          description:
              'Al final de tu turno: si el enemigo tiene 2+ debuffos, aplica Contagio.',
          hooks: const {ItemEffectHook.turnEnd},
        );

  @override
  String descriptionFor(Item item) {
    return 'Al final de tu turno: si el enemigo tiene 2+ debuffos, aplica ${max(1, item.value)} Contagio.';
  }

  @override
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn || _debuffCount(opponent) < 2) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: ContagioStatus(value: max(1, item.value)),
    );
  }
}

class CyberCerbatanaItemEffect extends ItemEffect {
  const CyberCerbatanaItemEffect()
      : super(
          description: 'Al usarse: aplica o aumenta Contagio al enemigo.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse: aplica ${max(1, item.value)} Contagio al enemigo, o aumenta el Contagio enemigo en ${max(1, item.value)}.';
  }

  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    return _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: ContagioStatus(value: max(1, item.value)),
    );
  }
}

class ProtocoloBroteItemEffect extends ItemEffect {
  const ProtocoloBroteItemEffect()
      : super(
          description:
              'Cuando Contagio enemigo llega a 0 al activarse, aplica Intoxicacion.',
          hooks: const {ItemEffectHook.contagioValueLost},
        );

  @override
  String descriptionFor(Item item) {
    return 'Cuando Contagio enemigo llega a 0 al activarse, aplica ${max(1, item.value)} Intoxicacion.';
  }

  @override
  ItemEffectResolution onContagioValueLost({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required int lostValue,
    required bool isOwnerContagioCarrier,
    required bool wasRemoved,
    required BattlerStatus triggerStatus,
  }) {
    if (isOwnerContagioCarrier || !wasRemoved) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: IntoxicacionStatus(value: max(1, item.value)),
    );
  }
}

class IncubadoraPortatilItemEffect extends ItemEffect {
  const IncubadoraPortatilItemEffect()
      : super(
          description:
              'Al principio del combate, aplica Contagio. Cuando Contagio enemigo se activa, ganas Barrera.',
          hooks: const {
            ItemEffectHook.combatStart,
            ItemEffectHook.contagioValueLost,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al principio del combate, aplica ${max(1, item.value)} Contagio. Cada vez que Contagio enemigo se activa, recuperas 3 Barrera.';
  }

  @override
  ItemEffectResolution onCombatStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    RunRandomizer? randomizer,
  }) {
    return _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: ContagioStatus(value: max(1, item.value)),
    );
  }

  @override
  ItemEffectResolution onContagioValueLost({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required int lostValue,
    required bool isOwnerContagioCarrier,
    required bool wasRemoved,
    required BattlerStatus triggerStatus,
  }) {
    if (isOwnerContagioCarrier) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _recoverBarrier(owner: owner, amount: 3),
      opponent: opponent,
    );
  }
}

int _debuffCount(Battler battler) {
  return battler.statuses
      .where((status) => status.type == BattlerStatusType.debuff)
      .length;
}

/// Enumera los estados "nuevos" que pueden ser aplicados por objetos.
enum ItemStatusEffectKind {
  calentando,
  conmocion,
  fragilidad,
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
    }
  }
}
