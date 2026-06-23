part of '../item_effect.dart';

int _halfUp(int value) => max(1, (max(0, value) + 1) ~/ 2);

int _predictedHpDamage({
  required Battler owner,
  required int damage,
}) {
  return max(0, damage - owner.currentBarrier);
}

int _incomingHpDamage({
  required Battler owner,
  required int damage,
  required DamageKind kind,
}) {
  if (kind == DamageKind.debuff) return max(0, damage);
  return _predictedHpDamage(owner: owner, damage: damage);
}

class ClavoDuelistaItemEffect extends ItemEffect {
  /// Crea el efecto de ClavoDuelista.
  const ClavoDuelistaItemEffect()
      : super(
          description:
              'Al usarse: si tienes mas HP que el enemigo, ganas Desafio.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse: si tienes mas HP que el enemigo, ganas ${item.value} Desafio.';
  }

  /// Reacciona cuando el item participa en el Patron usado.
  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    if (owner.health <= opponent.health) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.gainDesafio(item.value),
      opponent: opponent,
    );
  }
}

class VendasApretadasItemEffect extends ItemEffect {
  /// Crea el efecto de VendasApretadas.
  const VendasApretadasItemEffect()
      : super(
          description:
              'Al recibir daño: si perdiste HP, ganas Desafio. Una vez por turno.',
          hooks: const {
            ItemEffectHook.turnEnd,
            ItemEffectHook.incomingDamageEffect,
          },
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al recibir daño: si perdiste HP, ganas ${item.value} Desafio. Una vez por turno.';
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
    final triggeredFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.vendasApretadasTriggeredThisTurn,
    );
    final hpDamage = _incomingHpDamage(
      owner: owner,
      damage: damage,
      kind: kind,
    );
    if (hpDamage <= 0 || owner.hasCombatFlag(triggeredFlag)) {
      return BattlerIncomingDamageResolution(owner: owner, damage: damage);
    }

    return BattlerIncomingDamageResolution(
      owner: owner.addCombatFlag(triggeredFlag).gainDesafio(item.value),
      damage: damage,
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
    return ItemEffectResolution(
      owner: owner.removeItemCombatFlagsFor(
        item: item,
        kind: ItemCombatFlagKind.vendasApretadasTriggeredThisTurn,
      ),
      opponent: opponent,
    );
  }
}

class MarcaRetadorItemEffect extends ItemEffect {
  /// Crea el efecto de MarcaRetador.
  const MarcaRetadorItemEffect()
      : super(
          description:
              'Al inicio de tu turno: si estas por debajo del 50% HP, ganas Desafio.',
          hooks: const {ItemEffectHook.turnStart},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno: si estas por debajo del 50% HP, ganas ${item.value} Desafio.';
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
    if (!isOwnerTurn || owner.health * 2 >= owner.maxHealth) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.gainDesafio(item.value),
      opponent: opponent,
    );
  }
}

class HemomedidorItemEffect extends ItemEffect {
  /// Crea el efecto de Hemomedidor.
  const HemomedidorItemEffect()
      : super(
          description:
              'Al usarse: ganas Desafio por cada 10 HP faltantes, con maximo triple.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse: ganas ${item.value} Desafio por cada 10 HP faltantes, maximo ${item.value * 3}.';
  }

  /// Reacciona cuando el item participa en el Patron usado.
  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    final amount =
        min(item.value * 3, (_missingHealth(owner) ~/ 10) * item.value);
    if (amount <= 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.gainDesafio(amount),
      opponent: opponent,
    );
  }
}

class CarbonParaHeridasItemEffect extends ItemEffect {
  /// Crea el efecto de HeridaCarbonizada.
  const CarbonParaHeridasItemEffect()
      : super(
          description: 'Al recibir daño de Quemadura a tu HP: ganas Desafio.',
          hooks: const {ItemEffectHook.incomingDamageEffect},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al recibir daño de Quemadura a tu HP: ganas ${item.value} Desafio.';
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
    if (kind != DamageKind.burn ||
        _predictedHpDamage(owner: owner, damage: damage) <= 0) {
      return BattlerIncomingDamageResolution(owner: owner, damage: damage);
    }

    return BattlerIncomingDamageResolution(
      owner: owner.gainDesafio(item.value),
      damage: damage,
    );
  }
}

class Juegosucio101ItemEffect extends ItemEffect {
  /// Crea el efecto de GuanteProvocacion.
  const Juegosucio101ItemEffect()
      : super(
          description:
              'Al usarse: ganas Desafio. Si el enemigo tiene un debuff, ganas el doble.',
          hooks: const {ItemEffectHook.patternUsed},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse: ganas ${item.value} Desafio. Si el enemigo tiene un debuff, ganas el doble.';
  }

  /// Reacciona cuando el item participa en el Patron usado.
  @override
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    final amount = _hasAnyDebuff(opponent) ? item.value * 2 : item.value;
    return ItemEffectResolution(
      owner: owner.gainDesafio(amount),
      opponent: opponent,
    );
  }
}

class ContratoDolorosoItemEffect extends ItemEffect {
  /// Crea el efecto de ContratoDoloroso.
  const ContratoDolorosoItemEffect()
      : super(
          description:
              'Al final de tu turno: si recibiste daño a tu HP este turno, ganas Desafio y la mitad como Barrera.',
          hooks: const {
            ItemEffectHook.incomingDamageEffect,
            ItemEffectHook.turnEnd,
          },
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al final de tu turno: si recibiste daño a tu HP este turno, ganas ${item.value} Desafio y ${_halfUp(item.value)} Barrera.';
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
    if (_incomingHpDamage(owner: owner, damage: damage, kind: kind) <= 0) {
      return BattlerIncomingDamageResolution(owner: owner, damage: damage);
    }

    return BattlerIncomingDamageResolution(
      owner: owner.addCombatFlag(
        _itemCombatFlag(
          item,
          ItemCombatFlagKind.contratoDolorosoDamagedThisTurn,
        ),
      ),
      damage: damage,
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
    final damagedFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.contratoDolorosoDamagedThisTurn,
    );
    var updatedOwner = owner;
    if (isOwnerTurn && owner.hasCombatFlag(damagedFlag)) {
      updatedOwner = _recoverBarrier(
        owner: updatedOwner.gainDesafio(item.value),
        amount: _halfUp(item.value),
      );
    }

    return ItemEffectResolution(
      owner: updatedOwner.removeCombatFlag(damagedFlag),
      opponent: opponent,
    );
  }
}

class YunqueCardiacoItemEffect extends ItemEffect {
  /// Crea el efecto de YunqueCardiaco.
  const YunqueCardiacoItemEffect()
      : super(
          description:
              'Al recibir daño a HP: convierte parte de ese daño en Desafio, evitandolo. Una vez por turno.',
          hooks: const {
            ItemEffectHook.incomingDamageEffect,
            ItemEffectHook.turnEnd,
          },
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al recibir daño a HP: convierte hasta ${item.value} de ese daño en Desafio, evitando ese daño hacia ti. Una vez por turno.';
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
    final triggeredFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.yunqueCardiacoTriggeredThisTurn,
    );
    final prevented = min(
      item.value,
      _incomingHpDamage(owner: owner, damage: damage, kind: kind),
    );
    if (prevented <= 0 || owner.hasCombatFlag(triggeredFlag)) {
      return BattlerIncomingDamageResolution(owner: owner, damage: damage);
    }

    return BattlerIncomingDamageResolution(
      owner: owner.addCombatFlag(triggeredFlag).gainDesafio(prevented),
      damage: max(0, damage - prevented),
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
    return ItemEffectResolution(
      owner: owner.removeItemCombatFlagsFor(
        item: item,
        kind: ItemCombatFlagKind.yunqueCardiacoTriggeredThisTurn,
      ),
      opponent: opponent,
    );
  }
}

class RevanchadoraItemEffect extends ItemEffect {
  /// Crea el efecto de Revanchadora.
  const RevanchadoraItemEffect()
      : super(
          description:
              'Cuando una Quemadura propia te hace daño, ganas Desafio igual a la mitad de ese daño y te curas.',
          hooks: const {ItemEffectHook.incomingDamageEffect},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Cuando una Quemadura propia te hace daño, ganas Desafio igual a la mitad de esa Quemadura y te curas ${item.value}.';
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
    final hpDamage = _incomingHpDamage(
      owner: owner,
      damage: damage,
      kind: kind,
    );
    if (kind != DamageKind.burn || hpDamage <= 0) {
      return BattlerIncomingDamageResolution(owner: owner, damage: damage);
    }

    return BattlerIncomingDamageResolution(
      owner: owner.gainDesafio(_halfUp(hpDamage)).heal(item.value),
      damage: damage,
    );
  }
}

class EmbudoMejorasItemEffect extends ItemEffect {
  /// Crea el efecto de EmbudoMejoras.
  const EmbudoMejorasItemEffect()
      : super(
          description:
              'Al final de tu turno: elimina tus buffos y convierte su value en Desafio.',
          hooks: const {ItemEffectHook.turnEnd},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al final de tu turno: elimina tus buffos y convierte su value en Desafio, en un ratio de ${item.value} a 1.';
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

    var totalBuffValue = 0;
    var updatedOwner = owner;
    final removableBuffs = owner.statuses.where((status) {
      return status.type == BattlerStatusType.buff &&
          status.id != DesafioStatus.statusId &&
          status.id != DesafioExcitanteStatus.statusId;
    }).toList(growable: false);

    for (final buff in removableBuffs) {
      totalBuffValue += max(0, buff.resolved(updatedOwner).value);
      updatedOwner = updatedOwner.removeStatusInstance(buff);
    }

    final amount = totalBuffValue ~/ max(1, item.value);
    if (amount > 0) {
      updatedOwner = updatedOwner.gainDesafio(amount);
    }

    return ItemEffectResolution(owner: updatedOwner, opponent: opponent);
  }
}

class ArnesTacticoItemEffect extends ItemEffect {
  /// Crea el efecto de ArnesTactico.
  const ArnesTacticoItemEffect()
      : super(
          description:
              'Al recibir daño de Quemadura: ganas Potencia. Una vez por turno, al purgar tu Potencia, recibes la mitad en Desafio.',
          hooks: const {
            ItemEffectHook.incomingDamageEffect,
            ItemEffectHook.turnEnd,
          },
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al recibir daño de Quemadura: ganas ${item.value} Potencia. Una vez por turno, al purgar tu Potencia, recibes la mitad en Desafio.';
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
    if (kind != DamageKind.burn || damage <= 0) {
      return BattlerIncomingDamageResolution(owner: owner, damage: damage);
    }

    final trackedFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.arnesTacticoPotenciaTracked,
      item.value,
    );
    final updatedOwner = owner
        .applyStatus(
          PotenciaStatus(value: item.value),
          applyEquipmentModifiers: false,
        )
        .addCombatFlag(trackedFlag);
    return BattlerIncomingDamageResolution(
      owner: updatedOwner,
      damage: damage,
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
    final tracked = owner.itemCombatFlagValue(
      item: item,
      kind: ItemCombatFlagKind.arnesTacticoPotenciaTracked,
    );
    final triggeredFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.arnesTacticoDesafioTriggeredThisTurn,
    );
    var updatedOwner = owner;
    if (isOwnerTurn &&
        tracked != null &&
        !owner.hasStatus(PotenciaStatus.statusId) &&
        !owner.hasCombatFlag(triggeredFlag)) {
      updatedOwner = updatedOwner
          .addCombatFlag(triggeredFlag)
          .gainDesafio(_halfUp(tracked));
    }

    updatedOwner = updatedOwner
        .removeItemCombatFlagsFor(
          item: item,
          kind: ItemCombatFlagKind.arnesTacticoPotenciaTracked,
        )
        .removeItemCombatFlagsFor(
          item: item,
          kind: ItemCombatFlagKind.arnesTacticoDesafioTriggeredThisTurn,
        );
    return ItemEffectResolution(owner: updatedOwner, opponent: opponent);
  }
}

class MandibultimatumItemEffect extends ItemEffect {
  /// Crea el efecto de Mandibultimatum.
  const MandibultimatumItemEffect()
      : super(
          description:
              'Al usarse: consume Quemadura propia para recibir ese daño a la HP y ganar el doble en Desafio antes del ataque.',
          hooks: const {ItemEffectHook.prePatternAttack},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al usarse: consumes hasta ${item.value} Quemadura propia para recibir ese daño a la HP, y ganar el doble en Desafio ANTES de resolver el ataque.';
  }

  /// Resuelve efectos antes de aplicar el ataque generado por Patron.
  @override
  ItemEffectResolution onPrePatternAttack({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    var remainingToConsume = max(0, item.value);
    var updatedOwner = owner;
    final burns = owner
        .statusesById(QuemaduraStatus.statusId)
        .whereType<QuemaduraStatus>()
        .toList(growable: false);

    for (final burn in burns) {
      if (remainingToConsume <= 0) break;

      final consumed = min(remainingToConsume, burn.remainingTurns);
      remainingToConsume -= consumed;
      final nextTurns = burn.remainingTurns - consumed;
      updatedOwner = nextTurns <= 0
          ? updatedOwner.removeStatusInstance(burn)
          : updatedOwner.replaceStatusInstance(
              currentStatus: burn,
              replacement: burn.copyWith(remainingTurns: nextTurns),
            );
    }

    final consumedTotal = item.value - remainingToConsume;
    if (consumedTotal <= 0) {
      return ItemEffectResolution(owner: updatedOwner, opponent: opponent);
    }

    updatedOwner = _loseHealthDirectly(
      owner: updatedOwner,
      amount: consumedTotal,
    ).gainDesafio(consumedTotal * 2);
    return ItemEffectResolution(owner: updatedOwner, opponent: opponent);
  }
}

class EstandarteUltimoSolItemEffect extends ItemEffect {
  /// Crea el efecto de EstandarteUltimoSol.
  const EstandarteUltimoSolItemEffect()
      : super(
          description:
              'Al inicio de tu turno: ganas Desafio por cada 5 HP faltantes. Si tienes Quemadura, ganas esa cantidad como Barrera.',
          hooks: const {ItemEffectHook.turnStart},
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno: ganas ${item.value} Desafio por cada 5 HP faltantes. Si tienes Quemadura, ganas esa misma cantidad de Barrera.';
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

    final amount = (_missingHealth(owner) ~/ 5) * item.value;
    if (amount <= 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    var updatedOwner = owner.gainDesafio(amount);
    if (owner.hasStatus(QuemaduraStatus.statusId)) {
      updatedOwner = _recoverBarrier(owner: updatedOwner, amount: amount);
    }

    return ItemEffectResolution(owner: updatedOwner, opponent: opponent);
  }
}

class MotorMartirioItemEffect extends ItemEffect {
  /// Crea el efecto de MotorMartirio.
  const MotorMartirioItemEffect()
      : super(
          description:
              'Al recibir daño a HP o daño de Quemadura: ganas Desafio igual al daño, hasta un maximo por turno. Al final del turno, si tienes suficiente Desafio, te curas.',
          hooks: const {
            ItemEffectHook.incomingDamageEffect,
            ItemEffectHook.turnEnd,
          },
        );

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Item item) {
    return 'Al recibir daño a HP, o daño de Quemadura: ganas Desafio igual al daño recibido, max ${item.value} por turno. Al final del turno, si tienes ${item.value}+ Desafio, te curas ${item.value} HP.';
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
    final previous = owner.itemCombatFlagValue(
          item: item,
          kind: ItemCombatFlagKind.motorMartirioDamageThisTurn,
        ) ??
        0;
    final remainingCap = max(0, item.value - previous);
    final hpDamage = _incomingHpDamage(
      owner: owner,
      damage: damage,
      kind: kind,
    );
    final amount =
        min(remainingCap, kind == DamageKind.burn ? damage : hpDamage);
    if (amount <= 0) {
      return BattlerIncomingDamageResolution(owner: owner, damage: damage);
    }

    final updatedOwner = owner
        .removeItemCombatFlagsFor(
          item: item,
          kind: ItemCombatFlagKind.motorMartirioDamageThisTurn,
        )
        .addCombatFlag(
          _itemCombatFlag(
            item,
            ItemCombatFlagKind.motorMartirioDamageThisTurn,
            previous + amount,
          ),
        )
        .gainDesafio(amount);
    return BattlerIncomingDamageResolution(
      owner: updatedOwner,
      damage: damage,
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
    var updatedOwner = owner;
    if (isOwnerTurn && owner.desafioValue >= item.value) {
      updatedOwner = updatedOwner.heal(item.value);
    }

    return ItemEffectResolution(
      owner: updatedOwner.removeItemCombatFlagsFor(
        item: item,
        kind: ItemCombatFlagKind.motorMartirioDamageThisTurn,
      ),
      opponent: opponent,
    );
  }
}
