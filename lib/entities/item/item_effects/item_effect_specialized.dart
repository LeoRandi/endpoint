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

  /// Construye la descripcion visible del efecto usando el valor actual del item.
  @override
  String descriptionFor(Item item) {
    return 'Al inicio del combate, ganas ${max(1, item.value)} Calentando. Solo ocurre una vez por combate.';
  }

  /// Resuelve el disparo de inicio de turno para el portador del item.
  @override
  ItemEffectResolution onCombatStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    RandomSource? randomizer,
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
      owner: ownerWithFlag.runtimeApplyStatusFromSource(
        CalentandoStatus(value: amount),
        source: ownerWithFlag,
      ),
      opponent: opponent,
    );
  }
}

/// Consume Quemadura para convertirla en daño directo inmediato.
class SunExecutionBladeItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Hoja de Ejecucion Solar.
  const SunExecutionBladeItemEffect()
      : super(
          description:
              'Al usarse, consume la Quemadura del objetivo para infligir daño directo extra.',
          hooks: const {
            ItemEffectHook.patternUsed,
          },
        );

  /// Construye la descripcion visible del efecto usando el valor actual del item.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse, si el objetivo tiene Quemadura, la consume e inflige daño directo extra igual a su daño actual total + ${max(1, item.value)}.';
  }

  /// Reacciona justo despues de que el portador resuelva un ataque.
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
    final updatedTarget = target
        .removeStatus(QuemaduraStatus.statusId)
        .runtimeReceiveDirectDamage(
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

  /// Crea un efecto reutilizable que añade Quemadura al atacar.
  const QuemaduraOnAttackItemEffect({
    this.duration = QuemaduraStatus.defaultDuration,
  }) : super(
          description:
              'Al usarse: añade un efecto de Quemadura de 3 turnos de duracion.',
          hooks: const {
            ItemEffectHook.patternUsed,
          },
        );

  /// Genera la descripcion final usando la duracion actual del objeto equipado.
  @override
  String descriptionFor(Item item) {
    final resolvedDuration = max(1, item.value > 0 ? item.value : duration);
    return 'Al usarse: añade Quemadura durante $resolvedDuration turnos.';
  }

  /// Tras atacar, aplica una Quemadura nueva con la duracion configurada.
  @override
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
              'Al recibir un ataque: añade un efecto de Quemadura de 4 turnos de duracion.',
          hooks: const {
            ItemEffectHook.receiveDamageResolved,
          },
        );

  /// Genera la descripcion final usando la duracion actual del objeto equipado.
  @override
  String descriptionFor(Item item) {
    final resolvedDuration = max(1, item.value > 0 ? item.value : duration);
    return 'Al recibir un ataque: añade Quemadura al agresor durante $resolvedDuration turnos.';
  }

  /// Tras recibir un golpe, aplica Quemadura al enemigo que lo causo.
  @override
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

  /// Genera la descripcion final usando el value real del item equipado.
  @override
  String descriptionFor(Item item) {
    return 'Tus ataques infligen ${item.value} de daño adicional si el objetivo no tiene buffs.';
  }

  /// Suma daño solo cuando el objetivo esta completamente sin buffs.
  @override
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

  /// Genera la descripcion final usando el value real del item equipado.
  @override
  String descriptionFor(Item item) {
    return 'Reduce la Quemadura e Intoxicacion recibidas en ${item.value} al aplicarse.';
  }

  /// Resta duracion o value al estado recibido y puede cancelarlo si llega a cero.
  @override
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

  /// Explica a la UI cuanto income gana y cuanto HP maximo pierde el portador.
  @override
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

  /// Construye la descripcion visible del efecto usando el valor actual del item.
  @override
  String descriptionFor(Item item) {
    return 'Al terminar un combate equipado, aumenta su precio de venta en ${item.value}C.';
  }

  /// Aplica los cambios pendientes del item al cerrar el combate.
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

  /// Construye la descripcion visible del efecto usando el valor actual del item.
  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, si tienes al menos ${requiredMoney}C, recuperas ${max(1, item.value)} de Barrera.';
  }

  /// Resuelve el disparo de inicio de turno para el portador del item.
  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RandomSource? randomizer,
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
              'Al ganar un combate, añade un item aleatorio de su categoria a las recompensas si tienes espacio.',
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    final focusLabel = _focusTagFor(item).name;
    final statLine = item.id == ItemId.buzonVirtualAzul
        ? '+1 PP mientras este equipado. '
        : '';
    return '${statLine}Al terminar un combate, si tienes espacio, ofrece un item ${item.rarity.name.toUpperCase()} aleatorio con tag $focusLabel en la pantalla de recompensas.';
  }

  /// Decide que tag de recompensa debe buscar cada buzon segun su version.
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
  /// Crea el efecto de Taladron.
  const TaladronItemEffect()
      : super(
          description: 'Al usarse: destruye todas las Murallas de tu matriz.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse: todas las Murallas de tu matriz son destruidas.';
  }

  /// Reacciona cuando el item participa en el Patron usado.
  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    return _destroyOwnerBoardWalls(
      owner: owner,
      opponent: opponent,
      walls: owner.combatWallSegments,
      countForOwner: true,
    );
  }
}

class CuboDinamitalicoItemEffect extends ItemEffect {
  /// Crea el efecto de CuboDinamitalico.
  const CuboDinamitalicoItemEffect()
      : super(
          description:
              'Al comienzo del combate, destruye cualquier Muralla de tu matriz adyacente a su posicion.',
          hooks: const {ItemEffectHook.combatStart},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al comienzo del combate, destruye cualquier Muralla de tu matriz adyacente a su posicion.';
  }

  /// Resuelve el disparo de inicio de combate para este efecto.
  @override
  ItemEffectResolution onCombatStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    RandomSource? randomizer,
  }) {
    final point = _assignedPointForItem(owner: owner, item: item);
    if (point == null) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final adjacentWalls = owner.combatWallsAdjacentTo(point);
    return _destroyOwnerBoardWalls(
      owner: owner,
      opponent: opponent,
      walls: adjacentWalls,
      countForOwner: true,
    );
  }
}

class MedidorRoturaItemEffect extends ItemEffect {
  /// Crea el efecto de MedidorRotura.
  const MedidorRoturaItemEffect()
      : super(
          description: 'Ganas ataque por cada Muralla destruida este combate.',
          hooks: const {ItemEffectHook.calculatedStatModifier},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Ganas +${max(1, item.value)} ataque por cada Muralla destruida este combate.';
  }

  /// Ajusta una stat calculada mientras el efecto esta activo.
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
  /// Crea el efecto de MurallaAutomatica.
  const MurallaAutomaticaItemEffect()
      : super(
          description:
              'Al comienzo del combate, crea Murallas en la matriz enemiga.',
          hooks: const {ItemEffectHook.combatStart},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al comienzo del combate, crea ${max(1, item.value)} Murallas en la matriz enemiga.';
  }

  /// Resuelve el disparo de inicio de combate para este efecto.
  @override
  ItemEffectResolution onCombatStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    RandomSource? randomizer,
  }) {
    final walls = _randomAvailableWalls(
      existingWalls: opponent.combatWallSegments,
      count: max(1, item.value),
      nextInt: randomizer?.nextInt ?? _firstAvailableIndex,
    );
    return ItemEffectResolution(
      owner: owner,
      opponent: opponent.addCombatWalls(walls),
    );
  }
}

class LiteralPaywallItemEffect extends ItemEffect {
  /// Crea el efecto de LiteralPaywall.
  const LiteralPaywallItemEffect()
      : super(
          description:
              'Al usarse: al final del turno, paga creditos para crear una Muralla para el enemigo.',
          hooks: const {ItemEffectHook.patternUsed, ItemEffectHook.turnEnd},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse: al final del turno, paga ${max(0, item.value)} creditos si es posible para crear una Muralla para el enemigo.';
  }

  /// Reacciona cuando el item participa en el Patron usado.
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

  /// Resuelve el disparo de final de turno para el portador.
  @override
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RandomSource? randomizer,
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
    final nextInt = randomizer?.nextInt ?? _firstAvailableIndex;
    for (final flag in pendingFlags) {
      final cost = max(0, flag.secondaryValue ?? item.value);
      if (!updatedOwner.canAfford(cost)) continue;

      final walls = _randomAvailableWalls(
        existingWalls: updatedOpponent.combatWallSegments,
        count: 1,
        nextInt: nextInt,
      );
      if (walls.isEmpty) continue;

      updatedOwner = updatedOwner.spendMoneyForItemEffect(cost);
      updatedOpponent = updatedOpponent.addCombatWalls(walls);
    }

    return ItemEffectResolution(owner: updatedOwner, opponent: updatedOpponent);
  }
}

class PassCardItemEffect extends ItemEffect {
  /// Crea el efecto de PassCard.
  const PassCardItemEffect()
      : super(
          description:
              'Al usarse, paga creditos para desactivar las Murallas de tu matriz.',
          hooks: const {
            ItemEffectHook.patternUsed,
          },
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return '+1 BP mientras este equipado. Al usarse: paga ${max(0, item.value)} creditos si es posible para desactivar todas las Murallas de tu matriz hasta el final del combate.';
  }

  /// Reacciona cuando el item participa en el Patron usado.
  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    final cost = max(0, item.value);
    if (!owner.canAfford(cost)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final paidOwner = owner.spendMoneyForItemEffect(cost);
    return _destroyOwnerBoardWalls(
      owner: paidOwner,
      opponent: opponent,
      walls: paidOwner.combatWallSegments,
      countForOwner: false,
    );
  }
}

class TonfasEscudoItemEffect extends ItemEffect {
  /// Crea el efecto de TonfasEscudo.
  const TonfasEscudoItemEffect()
      : super(
          description:
              'Puedes poner o mover una Muralla mas por turno, pero tienes -1 BP maximo.',
          hooks: const {
            ItemEffectHook.passive,
          },
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Puedes poner o mover una Muralla mas por turno para bloquear a tu oponente, pero -1 BP maximo.';
  }
}

class ConstructionSealItemEffect extends ItemEffect {
  /// Crea el efecto de ConstructionSeal.
  const ConstructionSealItemEffect()
      : super(
          description:
              'Al principio de turno, te curas segun tus BP restantes. Al usarse, destruye una Muralla.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.patternUsed,
          },
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return '+4 BP mientras este equipado. Al principio de turno: te curas ${max(0, item.value)} veces tus BP restantes. Al usarse: destruye una Muralla en tu tablero o en el de tu enemigo.';
  }

  /// Resuelve el disparo de inicio de turno para el portador.
  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RandomSource? randomizer,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final remainingBp = max(
      0,
      BattlerRuntimeGateway.instance.maxBlockingPointsFor(owner) -
          opponent.combatWallSegments.length,
    );
    final healing = max(0, item.value) * remainingBp;
    return ItemEffectResolution(
      owner: healing > 0 ? owner.heal(healing) : owner,
      opponent: opponent,
    );
  }

  /// Reacciona cuando el item participa en el Patron usado.
  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
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

    final selectedIndex = pattern.randomSource?.nextInt(candidates.length) ?? 0;
    final selected = candidates[selectedIndex];
    if (selected.ownerBoard) {
      final resolution = _destroyOwnerBoardWalls(
        owner: updatedOwner,
        opponent: updatedOpponent,
        walls: [selected.wall],
        countForOwner: true,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    } else {
      final resolution = _destroyOpponentBoardWalls(
        owner: updatedOwner,
        opponent: updatedOpponent,
        walls: [selected.wall],
        countForOwner: true,
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

class BarbedShieldItemEffect extends ItemEffect {
  /// Crea el efecto de BarbedShield.
  const BarbedShieldItemEffect()
      : super(
          description:
              'Al usarse: hace daño al enemigo al final del turno segun las Murallas en ambas matrices.',
          hooks: const {ItemEffectHook.patternUsed, ItemEffectHook.turnEnd},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse: Hace daño al enemigo al final del turno igual a ${max(1, item.value)} veces el numero de Murallas en tu matriz y en la del enemigo.';
  }

  /// Reacciona cuando el item participa en el Patron usado.
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

  /// Resuelve el disparo de final de turno para el portador.
  @override
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RandomSource? randomizer,
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
          : opponent.runtimeReceiveDirectDamage(damage, source: owner),
    );
  }
}

class PilarAceroItemEffect extends ItemEffect {
  /// Crea el efecto de PilarAcero.
  const PilarAceroItemEffect()
      : super(
          description:
              'Al usarse: crea Murallas temporales alrededor de su punto.',
          hooks: const {ItemEffectHook.patternUsed, ItemEffectHook.turnEnd},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse: Crea Murallas al rededor de su punto al final del turno, que duran un turno, tanto en tu matriz como en la del enemigo.';
  }

  /// Reacciona cuando el item participa en el Patron usado.
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

  /// Resuelve el disparo de final de turno para el portador.
  @override
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RandomSource? randomizer,
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
  /// Crea el efecto de DuplicadorAtomos.
  const DuplicadorAtomosItemEffect()
      : super(
          description:
              'Al usarse: copia Murallas de tu matriz a la del enemigo.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse: Copia ${max(1, item.value)} Murallas en tu matriz a la de tu enemigo.';
  }

  /// Reacciona cuando el item participa en el Patron usado.
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
  /// Crea el efecto de CortinaHumo.
  const CortinaHumoItemEffect()
      : super(
          description:
              'Al usarse: mueve Murallas de tu matriz a la del enemigo.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse: Mueve ${max(1, item.value)} Murallas de tu matriz a la del enemigo.';
  }

  /// Reacciona cuando el item participa en el Patron usado.
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

ItemEffectResolution _destroyOwnerBoardWalls({
  required Battler owner,
  required Battler opponent,
  required Iterable<OperativePatternWallSegment> walls,
  bool countForOwner = false,
}) {
  final wallsToDestroy = walls.toList(growable: false);
  if (wallsToDestroy.isEmpty) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  final beforeCount = owner.combatWallSegments.length;
  var updatedOwner = owner.destroyCombatWalls(wallsToDestroy);
  final destroyedCount = beforeCount - updatedOwner.combatWallSegments.length;
  if (destroyedCount <= 0) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }
  updatedOwner =
      updatedOwner.recordRemovedWallBlockingPointDebt(destroyedCount);
  if (countForOwner) {
    updatedOwner = updatedOwner.recordDestroyedCombatWalls(destroyedCount);
  }

  return ItemEffectResolution(
    owner: updatedOwner,
    opponent: opponent,
  );
}

ItemEffectResolution _destroyOpponentBoardWalls({
  required Battler owner,
  required Battler opponent,
  required Iterable<OperativePatternWallSegment> walls,
  bool countForOwner = false,
}) {
  final wallsToDestroy = walls.toList(growable: false);
  if (wallsToDestroy.isEmpty) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  final beforeCount = opponent.combatWallSegments.length;
  var updatedOpponent = opponent.destroyCombatWalls(wallsToDestroy);
  final destroyedCount =
      beforeCount - updatedOpponent.combatWallSegments.length;
  if (destroyedCount <= 0) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }
  updatedOpponent =
      updatedOpponent.recordRemovedWallBlockingPointDebt(destroyedCount);
  final updatedOwner =
      countForOwner ? owner.recordDestroyedCombatWalls(destroyedCount) : owner;

  return ItemEffectResolution(
    owner: updatedOwner,
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

int _firstAvailableIndex(int _) => 0;

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

  /// Construye la descripcion visible del efecto usando el valor actual del item.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse, te curas ${max(1, item.value)} HP por cada item de otro arquetipo en tu inventario, hasta $healCap HP.';
  }

  /// Reacciona justo despues de que el portador resuelva un ataque.
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

  /// Construye la descripcion visible del efecto usando el valor actual del item.
  @override
  String descriptionFor(Item item) {
    return 'Obtienes +ATK igual a ${max(1, item.value)} + el numero de items de otro arquetipo que posees, hasta $attackCap.';
  }

  /// Ajusta una stat calculada del portador mientras el item este equipado.
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

class ShoppingChecklistItemEffect extends ItemEffect {
  /// Crea el efecto de ShoppingChecklist.
  const ShoppingChecklistItemEffect()
      : super(
          description:
              'Al inicio de tu turno, si has gastado creditos este combate, recuperas Barrera.',
          hooks: const {ItemEffectHook.turnStart},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, si has gastado creditos este combate, recuperas ${max(1, item.value)} de Barrera.';
  }

  /// Resuelve el disparo de inicio de turno para el portador.
  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RandomSource? randomizer,
  }) {
    if (!isOwnerTurn ||
        !owner.hasCombatFlag(
          const CombatRuntimeFlag.battler(
            BattlerCombatFlag.creditsSpentThisCombat,
          ),
        )) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }
    return ItemEffectResolution(
      owner: _recoverBarrier(owner: owner, amount: max(1, item.value)),
      opponent: opponent,
    );
  }
}

class LaCuentaItemEffect extends ItemEffect {
  static const attackBonus = 3;

  /// Crea el efecto de LaCuenta.
  const LaCuentaItemEffect()
      : super(
          description:
              'Las primeras veces que gastas creditos en combate preparas bonus de ataque.',
          hooks: const {
            ItemEffectHook.outgoingDamageModifier,
            ItemEffectHook.attackResolved,
          },
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Las primeras ${max(1, item.value)} veces por combate que gastas creditos, tu siguiente ataque gana +$attackBonus daño.';
  }

  /// Ajusta el daño saliente antes de aplicarlo.
  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damage,
  }) {
    final pending = owner.itemCombatFlagUseCount(
      item: item,
      kind: ItemCombatFlagKind.laCuentaPendingAttackBonus,
    );
    if (pending <= 0) return damage;
    return damage + attackBonus;
  }

  /// Reacciona justo despues de que el portador resuelva un ataque.
  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final matchingFlags = owner.combatFlags
        .where(
          (flag) =>
              flag.itemFlag == ItemCombatFlagKind.laCuentaPendingAttackBonus &&
              flag.itemId == item.id &&
              flag.itemInstanceId == item.instanceId,
        )
        .toList(growable: false);
    if (matchingFlags.isEmpty) {
      return ItemEffectResolution(owner: owner, opponent: target);
    }

    final updatedFlags = Set<CombatRuntimeFlag>.from(owner.combatFlags)
      ..remove(matchingFlags.first);
    return ItemEffectResolution(
      owner: owner.copyWith(
        combatFlags: Set<CombatRuntimeFlag>.unmodifiable(updatedFlags),
      ),
      opponent: target,
    );
  }
}

class CoinLauncherItemEffect extends ItemEffect {
  static const _creditCost = 2;

  const CoinLauncherItemEffect()
      : super(
          description:
              'Al usarse, gasta creditos para potenciar el ataque del Patron.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  @override
  String descriptionFor(Item item) {
    return 'Al usarse: paga $_creditCost creditos si es posible para dar +${max(1, item.value)} ataque al Patron.';
  }

  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    if (!owner.canAfford(_creditCost)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.spendMoneyForItemEffect(_creditCost),
      opponent: opponent,
      attackBonusDelta: max(1, item.value),
    );
  }
}

class SeguroBolsilloItemEffect extends ItemEffect {
  /// Crea el efecto de SeguroBolsillo.
  const SeguroBolsilloItemEffect()
      : super(
          description:
              'Una vez por combate, paga creditos para prevenir daño a la vida.',
          hooks: const {ItemEffectHook.incomingDamageEffect},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    final amount = max(1, item.value) * 2;
    return 'Una vez por combate, cuando fueras a perder HP, paga hasta ${amount}C para prevenir esa cantidad de daño a la vida.';
  }

  /// Intercepta daño entrante antes de que se aplique al portador.
  @override
  BattlerIncomingDamageResolution onIncomingDamage({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damage,
    required DamageKind kind,
  }) {
    if (damage <= owner.currentBarrier ||
        owner.hasCombatFlag(
            _itemCombatFlag(item, ItemCombatFlagKind.seguroBolsilloUsed))) {
      return BattlerIncomingDamageResolution(owner: owner, damage: damage);
    }
    final preventable =
        min(max(1, item.value) * 2, damage - owner.currentBarrier);
    final paid = min(preventable, owner.money);
    if (paid <= 0) {
      return BattlerIncomingDamageResolution(owner: owner, damage: damage);
    }
    return BattlerIncomingDamageResolution(
      owner: owner.spendMoneyForItemEffect(paid).addCombatFlag(
          _itemCombatFlag(item, ItemCombatFlagKind.seguroBolsilloUsed)),
      damage: max(0, damage - paid),
    );
  }
}

class BolsoR33mItemEffect extends ItemEffect {
  /// Crea el efecto de BolsoR33m.
  const BolsoR33mItemEffect()
      : super(
          description:
              'Las primeras veces que gastas creditos durante combate, recuperas el gasto inmediatamente.',
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Las primeras ${max(1, item.value)} veces por combate que gastas creditos durante combate, recuperas ese dinero inmediatamente.';
  }
}

class SelloMercanteItemEffect extends ItemEffect {
  /// Crea el efecto de SelloMercante.
  const SelloMercanteItemEffect()
      : super(
          description: 'Cuando ganas creditos, restauras vida.',
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Cuando ganas creditos, restauras ${max(1, item.value)} HP.';
  }
}

class CompraAgresivaItemEffect extends ItemEffect {
  /// Crea el efecto de CompraAgresiva.
  const CompraAgresivaItemEffect()
      : super(
          description:
              'Al final de tu turno, paga creditos para ganar Barrera. Tras tres pagos, ganas BP.',
          hooks: const {ItemEffectHook.turnEnd},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al final de tu turno, paga ${max(0, item.value)}C si es posible para ganar 3 Barrera. La primera vez por combate que este efecto se activa 3 veces, ganas +1 BP.';
  }

  /// Resuelve el disparo de final de turno para el portador.
  @override
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RandomSource? randomizer,
  }) {
    final cost = max(0, item.value);
    if (!isOwnerTurn || cost <= 0 || !owner.canAfford(cost)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    var updatedOwner = owner
        .spendMoneyForItemEffect(cost)
        .addItemCombatFlagUse(
          item: item,
          kind: ItemCombatFlagKind.compraAgresivaPaid,
        )
        .gainCombatBarrier(3);
    final paidCount = updatedOwner.itemCombatFlagUseCount(
      item: item,
      kind: ItemCombatFlagKind.compraAgresivaPaid,
    );
    final unlockFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.compraAgresivaBpUnlocked,
      1,
    );
    if (paidCount >= 3 && !updatedOwner.hasCombatFlag(unlockFlag)) {
      updatedOwner = updatedOwner.addCombatFlag(unlockFlag);
    }

    return ItemEffectResolution(owner: updatedOwner, opponent: opponent);
  }
}

class SubastaRelampagoItemEffect extends ItemEffect {
  /// Crea el efecto de SubastaRelampago.
  const SubastaRelampagoItemEffect()
      : super(
          description:
              'Permite activar un mismo punto dos veces y paga creditos la primera vez de cada turno.',
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Puedes activar el mismo punto dos veces en un Patron, repitiendo sus efectos Al usarse y sus bonus de ATK/Barrera. La primera vez de cada turno que repites un punto con item, ganas ${max(1, item.value)}C.';
  }
}

class BolsaRiesgoItemEffect extends ItemEffect {
  /// Crea el efecto de BolsaRiesgo.
  const BolsaRiesgoItemEffect()
      : super(
          description:
              'Al comienzo del combate ganas creditos y, al caer bajo media vida, los conviertes en daño.',
          hooks: const {
            ItemEffectHook.combatStart,
            ItemEffectHook.receiveDamageResolved,
          },
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al comienzo del combate, ganas ${max(1, item.value) * 2}C. La primera vez por combate que quedas por debajo del 50% HP, gastas hasta ${max(1, item.value) * 3}C para infligir ese daño directo.';
  }

  /// Resuelve el disparo de inicio de combate para este efecto.
  @override
  ItemEffectResolution onCombatStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    RandomSource? randomizer,
  }) {
    return ItemEffectResolution(
      owner: owner.earnMoney(max(1, item.value) * 2),
      opponent: opponent,
    );
  }

  /// Reacciona justo despues de que el portador reciba daño.
  @override
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    final triggerFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.bolsaRiesgoTriggered,
    );
    if (owner.hasCombatFlag(triggerFlag) ||
        owner.health * 2 >= owner.maxHealth ||
        owner.money <= 0) {
      return ItemEffectResolution(owner: owner, opponent: source);
    }
    final spent = min(owner.money, max(1, item.value) * 3);
    return ItemEffectResolution(
      owner: owner.spendMoneyForItemEffect(spent).addCombatFlag(triggerFlag),
      opponent: source.runtimeReceiveDirectDamage(spent, source: owner),
    );
  }
}

class CamaraArbitrajeItemEffect extends ItemEffect {
  /// Crea el efecto de CamaraArbitraje.
  const CamaraArbitrajeItemEffect()
      : super(
          description:
              'Reduce un debuff entrante pagando creditos y recupera Barrera.',
          hooks: const {ItemEffectHook.incomingStatusModifier},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Una vez por turno, cuando recibes un debuff, paga ${max(1, item.value) * 2}C para reducirlo en ${max(1, item.value)} y recuperar ${max(1, item.value) * 2} Barrera.';
  }

  /// Intercepta un estado entrante antes de aplicarlo al portador.
  @override
  ItemIncomingStatusResolution onIncomingStatus({
    required Battler owner,
    required Battler source,
    required Item item,
    required BattlerStatus status,
  }) {
    final cost = max(1, item.value) * 2;
    final flag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.deflectiveCapacitorReflectedDebuff,
      owner.combatRound,
    );
    if (status.type != BattlerStatusType.debuff ||
        owner.hasCombatFlag(flag) ||
        !owner.canAfford(cost)) {
      return ItemIncomingStatusResolution(
        owner: owner,
        source: source,
        status: status,
      );
    }

    final reduction = max(1, item.value);
    final reducedStatus = status.copyWith(
      value: max(0, status.value - reduction),
      remainingTurns: max(0, status.remainingTurns - reduction),
    );
    return ItemIncomingStatusResolution(
      owner: owner
          .spendMoneyForItemEffect(cost)
          .gainCombatBarrier(cost)
          .addCombatFlag(flag),
      source: source,
      status: reducedStatus.value <= 0 && reducedStatus.remainingTurns <= 0
          ? null
          : reducedStatus,
    );
  }
}

class BancoAmbulanteItemEffect extends ItemEffect {
  static const requiredMoney = 20;

  /// Crea el efecto de BancoAmbulante.
  const BancoAmbulanteItemEffect()
      : super(
          description:
              'Convierte caja alta en Barrera, invierte en Patrones grandes y genera creditos al final del turno.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.prePatternAttack,
            ItemEffectHook.attackResolved,
            ItemEffectHook.turnEnd,
          },
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, si tienes al menos ${requiredMoney}C, ganas ${max(1, item.value)} Barrera. Cuando usas un Patron con 5+ puntos de item, puedes gastar hasta ${max(1, item.value)}C para sumar ese valor dividido entre ATK y Barrera. Al final de tu turno, ganas ${max(1, item.value)}C.';
  }

  /// Resuelve el disparo de inicio de turno para el portador.
  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RandomSource? randomizer,
  }) {
    if (!isOwnerTurn || owner.money < requiredMoney) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }
    return ItemEffectResolution(
      owner: owner.gainCombatBarrier(max(1, item.value)),
      opponent: opponent,
    );
  }

  /// Resuelve efectos antes de aplicar el ataque generado por Patron.
  @override
  ItemEffectResolution onPrePatternAttack({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    if (pattern.usedItemPointCount < 5 || owner.money <= 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }
    final spent = min(owner.money, max(1, item.value));
    final attackBoost = (spent + 1) ~/ 2;
    final barrierBoost = spent ~/ 2;
    var updatedOwner =
        owner.spendMoneyForItemEffect(spent).addItemCombatFlagUse(
              item: item,
              kind: ItemCombatFlagKind.bancoAmbulantePatternSpendThisTurn,
            );
    if (barrierBoost > 0) {
      updatedOwner = updatedOwner.gainCombatBarrier(barrierBoost);
    }
    if (attackBoost > 0) {
      updatedOwner = _boostItemAttackForCombat(
        owner: updatedOwner,
        item: item,
        amount: attackBoost,
      );
    }
    return ItemEffectResolution(owner: updatedOwner, opponent: opponent);
  }

  /// Resuelve el disparo de final de turno para el portador.
  @override
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RandomSource? randomizer,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }
    return ItemEffectResolution(
      owner: owner.earnMoney(max(1, item.value)),
      opponent: opponent,
    );
  }

  /// Reacciona justo despues de que el portador resuelva un ataque.
  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    if (item.combatItemBonusBoost <= 0) {
      return ItemEffectResolution(owner: owner, opponent: target);
    }
    return ItemEffectResolution(
      owner: _replaceOwnedItem(
        owner: owner,
        currentItem: item,
        replacement: item.clearCombatAugments(),
      ),
      opponent: target,
    );
  }
}

class NivelPrecisionItemEffect extends ItemEffect {
  /// Crea el efecto de NivelPrecision.
  const NivelPrecisionItemEffect()
      : super(
          description:
              'Al usarse, si el bonus final de ATK y Barrera del Patron son iguales, suma valor a ambos.',
          hooks: const {ItemEffectHook.prePatternAttack},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse: si el bonus final de ATK y Barrera del Patron son iguales, suma ${max(1, item.value)} a ambos antes del ataque.';
  }

  /// Resuelve efectos antes de aplicar el ataque generado por Patron.
  @override
  ItemEffectResolution onPrePatternAttack({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    if (pattern.attackBonus != pattern.barrierBonus) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final amount = max(1, item.value);
    return ItemEffectResolution(
      owner: owner,
      opponent: opponent,
      attackBonusDelta: amount,
      barrierBonusDelta: amount,
    );
  }
}

class MekaYunqueItemEffect extends ItemEffect {
  /// Crea el efecto de MekaYunque.
  const MekaYunqueItemEffect()
      : super(
          description:
              'Al usarse con un Patron grande, mejora temporalmente un item General.',
          hooks: const {ItemEffectHook.prePatternAttack},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'La primera vez por combate que usas un Patron con 6+ puntos de item, mejora temporalmente en ${max(1, item.value)} el item General equipado de menor rareza.';
  }

  /// Resuelve efectos antes de aplicar el ataque generado por Patron.
  @override
  ItemEffectResolution onPrePatternAttack({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    final triggerFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.mekaYunqueTriggered,
    );
    if (pattern.usedItemPointCount < 6 || owner.hasCombatFlag(triggerFlag)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final generalItems = owner.equippedItems
        .where(
          (equipped) =>
              equipped.hasArchetypeAffinity(ItemArchetypeAffinity.general),
        )
        .toList(growable: false);
    if (generalItems.isEmpty) {
      return ItemEffectResolution(
        owner: owner.addCombatFlag(triggerFlag),
        opponent: opponent,
      );
    }

    final selected = generalItems.reduce((best, equipped) {
      if (equipped.rarity.index != best.rarity.index) {
        return equipped.rarity.index < best.rarity.index ? equipped : best;
      }
      final bestIndex = owner.equippedItems.indexOf(best);
      final equippedIndex = owner.equippedItems.indexOf(equipped);
      return equippedIndex < bestIndex ? equipped : best;
    });

    return ItemEffectResolution(
      owner: _replaceOwnedItem(
        owner: owner.addCombatFlag(triggerFlag),
        currentItem: selected,
        replacement: _boostGeneralItemForCombat(
          item: selected,
          amount: max(1, item.value),
        ),
      ),
      opponent: opponent,
    );
  }
}

class SonicaltropsItemEffect extends ItemEffect {
  /// Crea el efecto de Sonicaltrops.
  const SonicaltropsItemEffect()
      : super(
          description:
              'Al inicio del combate, interfiere el primer Patron del rival.',
          hooks: const {ItemEffectHook.combatStart},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Durante el primer turno del oponente, da -${max(1, item.value)} al bonus de ATK y Barrera de su Patron.';
  }

  /// Resuelve el disparo de inicio de combate para este efecto.
  @override
  ItemEffectResolution onCombatStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    RandomSource? randomizer,
  }) {
    return ItemEffectResolution(
      owner: owner,
      opponent: opponent.addCombatFlag(
        CombatRuntimeFlag.item(
          itemFlag: ItemCombatFlagKind.sonicaltropsOpeningPenalty,
          itemId: item.id,
          itemInstanceId: item.instanceId,
          secondaryValue: max(1, item.value),
        ),
      ),
    );
  }
}

/// Aplica una mejora temporal de combate a cualquier item generalista.
///
/// El boost queda marcado en `combatItemBonusBoost` para que [Item.clearCombatAugments]
/// pueda revertirlo al cerrar el encuentro.
Item _boostGeneralItemForCombat({
  required Item item,
  required int amount,
}) {
  final safeAmount = max(0, amount);
  if (safeAmount <= 0) return item;

  final statModifiers = Map<BattlerStat, int>.from(item.statModifiers);
  for (final entry in item.statModifiers.entries) {
    if (entry.value <= 0) continue;
    statModifiers[entry.key] = entry.value + safeAmount;
  }

  final adjacencyBonuses = item.patternAdjacencyBonuses
      .map(
        (bonus) => OperativePatternAdjacencyBonus(
          direction: bonus.direction,
          requiredTag: bonus.requiredTag,
          kind: bonus.kind,
          amount: bonus.amount + safeAmount,
        ),
      )
      .toList(growable: false);

  return item.copyWith(
    value:
        item.effect != null && item.value > 0 ? item.value + safeAmount : null,
    statModifiers: statModifiers,
    patternBonusAmountOverride:
        item.hasPatternBonus ? item.patternBonusAmount + safeAmount : null,
    patternAdjacencyBonuses: adjacencyBonuses,
    hasPatternAura: true,
    combatItemBonusBoost: item.combatItemBonusBoost + safeAmount,
  );
}

/// Mejora temporalmente el ATK de una instancia equipada concreta.
///
/// Solo reemplaza el item si sigue equipado en el owner actual, lo que evita
/// tocar copias obsoletas conservadas por overlays o resoluciones previas.
Battler _boostItemAttackForCombat({
  required Battler owner,
  required Item item,
  required int amount,
}) {
  final safeAmount = max(0, amount);
  if (safeAmount <= 0) return owner;

  final index = owner.equippedItems.indexOf(item);
  if (index < 0) return owner;

  final boostedStats = Map<BattlerStat, int>.from(item.statModifiers);
  boostedStats.update(
    BattlerStat.attack,
    (current) => current + safeAmount,
    ifAbsent: () => safeAmount,
  );
  final updatedItems = List<Item>.from(owner.equippedItems);
  updatedItems[index] = item.copyWith(
    statModifiers: boostedStats,
    combatItemBonusBoost: item.combatItemBonusBoost + safeAmount,
  );
  return owner.copyWith(equippedItems: List<Item>.unmodifiable(updatedItems));
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

  /// Genera la descripcion final usando el value real del item equipado.
  @override
  String descriptionFor(Item item) {
    return 'Las Quemaduras que aplicas duran ${item.value} turno mas. Al final de tu turno te aplicas Quemadura (${item.value}).';
  }

  /// Extiende solo las Quemaduras que el portador aplica a otros objetivos.
  @override
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

  /// Al cerrar el turno propio, aplica una Quemadura al usuario.
  @override
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RandomSource? randomizer,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.runtimeApplyStatusFromSource(
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

  /// Genera la descripcion final usando la vida con la que deja al portador.
  @override
  String descriptionFor(Item item) {
    return 'Una vez por combate evita la muerte y te deja en ${max(1, item.value)} HP.';
  }

  /// Intercepta el daño letal y aplica la proteccion una sola vez por combate.
  @override
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

  /// Limpia la proteccion temporal al inicio del siguiente turno propio.
  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RandomSource? randomizer,
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
  /// Crea el efecto de VialRoto.
  const VialRotoItemEffect()
      : super(
          description: 'Al principio del combate, aplica Contagio al enemigo.',
          hooks: const {ItemEffectHook.combatStart},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al principio del combate, aplica ${max(1, item.value)} Contagio al enemigo.';
  }

  /// Resuelve el disparo de inicio de combate para este efecto.
  @override
  ItemEffectResolution onCombatStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    RandomSource? randomizer,
  }) {
    return _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: ContagioStatus(value: max(1, item.value)),
    );
  }
}

class PlumaSepticaItemEffect extends ItemEffect {
  /// Crea el efecto de PlumaSeptica.
  const PlumaSepticaItemEffect()
      : super(
          description: 'Al usarse: aplica debuffos aleatorios al enemigo.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse: aplica ${max(1, item.value)} veces un debuff aleatorio al enemigo.';
  }

  /// Reacciona cuando el item participa en el Patron usado.
  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;
    final randomizer = pattern.randomSource;

    for (var i = 0; i < max(1, item.value); i++) {
      final status = switch (randomizer?.nextInt(4) ?? i % 4) {
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
  /// Crea el efecto de LanzaSucia.
  const LanzaSuciaItemEffect()
      : super(
          description:
              'Al usarse contra un enemigo con debuff, aplica Contagio.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse contra un enemigo con debuff, aplica ${max(1, item.value)} Contagio.';
  }

  /// Reacciona cuando el item participa en el Patron usado.
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
  /// Crea el efecto de AmpollaInestable.
  const AmpollaInestableItemEffect()
      : super(
          description:
              'Al usarse: aplica Contagio. Si ya tenia Contagio, aplica Fragilidad.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    final amount = max(1, item.value);
    return 'Al usarse: aplica $amount Contagio. Si el enemigo ya tenia Contagio, aplica ${amount * 2} Fragilidad.';
  }

  /// Reacciona cuando el item participa en el Patron usado.
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
  /// Crea el efecto de TuboCultivo.
  const TuboCultivoItemEffect()
      : super(
          description:
              'Al final de tu turno: si el enemigo tiene 2+ debuffos, aplica Contagio.',
          hooks: const {ItemEffectHook.turnEnd},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al final de tu turno: si el enemigo tiene 2+ debuffos, aplica ${max(1, item.value)} Contagio.';
  }

  /// Resuelve el disparo de final de turno para el portador.
  @override
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RandomSource? randomizer,
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
  /// Crea el efecto de CyberCerbatana.
  const CyberCerbatanaItemEffect()
      : super(
          description: 'Al usarse: aplica o aumenta Contagio al enemigo.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse: aplica ${max(1, item.value)} Contagio al enemigo, o aumenta el Contagio enemigo en ${max(1, item.value)}.';
  }

  /// Reacciona cuando el item participa en el Patron usado.
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
  /// Crea el efecto de ProtocoloBrote.
  const ProtocoloBroteItemEffect()
      : super(
          description:
              'Cuando Contagio enemigo llega a 0 al activarse, aplica Intoxicacion.',
          hooks: const {ItemEffectHook.contagioValueLost},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Cuando Contagio enemigo llega a 0 al activarse, aplica ${max(1, item.value)} Intoxicacion.';
  }

  /// Reacciona cuando Contagio pierde valor durante el combate.
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
  /// Crea el efecto de IncubadoraPortatil.
  const IncubadoraPortatilItemEffect()
      : super(
          description:
              'Al principio del combate, aplica Contagio. Cuando Contagio enemigo se activa, ganas Barrera.',
          hooks: const {
            ItemEffectHook.combatStart,
            ItemEffectHook.contagioValueLost,
          },
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al principio del combate, aplica ${max(1, item.value)} Contagio. Cada vez que Contagio enemigo se activa, recuperas 3 Barrera.';
  }

  /// Resuelve el disparo de inicio de combate para este efecto.
  @override
  ItemEffectResolution onCombatStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    RandomSource? randomizer,
  }) {
    return _applyStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: ContagioStatus(value: max(1, item.value)),
    );
  }

  /// Reacciona cuando Contagio pierde valor durante el combate.
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

/// Cuenta debuffs activos sin filtrar por purgabilidad.
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

  /// Construye la descripcion visible del efecto usando el valor actual del item.
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

  /// Resuelve el disparo de inicio de turno para el portador del item.
  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RandomSource? randomizer,
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

  /// Reacciona justo despues de que el portador resuelva un ataque.
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

  /// Reacciona justo despues de que el portador reciba daño.
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

  /// Aplica el estado construido al portador segun la politica del trigger.
  Battler _applyToOwner({
    required Battler owner,
    required Battler source,
    required Item item,
  }) {
    final status = _buildStatus(item);

    switch (trigger) {
      case ItemStatusEffectTrigger.turnStartOwnerIfMissing:
        if (owner.hasStatus(status.id)) return owner;

        return owner.runtimeApplyStatusFromSource(
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
        return refreshedOwner.runtimeApplyStatusFromSource(
          status,
          source: source,
        );
      case ItemStatusEffectTrigger.attackOwnerReinforce:
        if (kind != ItemStatusEffectKind.calentando) {
          return owner.runtimeApplyStatusFromSource(
            status,
            source: source,
          );
        }

        final currentStatus = owner.statusById(CalentandoStatus.statusId);
        if (currentStatus is! CalentandoStatus) {
          return owner.runtimeApplyStatusFromSource(
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
        return owner.runtimeApplyStatusFromSource(
          status,
          source: source,
        );
      case ItemStatusEffectTrigger.attackTarget:
      case ItemStatusEffectTrigger.receiveDamageSource:
        return owner;
    }
  }

  /// Construye la instancia concreta de estado usando el value actual del item.
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

  /// Describe el estado en lenguaje compacto para la descripcion del item.
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
