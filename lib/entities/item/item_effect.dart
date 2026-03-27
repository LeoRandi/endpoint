import '_imports.dart';

class ItemEffectResolution {
  final Battler owner;
  final Battler opponent;

  const ItemEffectResolution({
    required this.owner,
    required this.opponent,
  });
}

enum ItemAbilityResolutionContext {
  manualActivation,
  attackResolved,
  receiveDamageResolved,
  turnStart,
  turnEnd,
}

class ItemAbilityPreparationResolution {
  final Battler owner;
  final Battler opponent;
  final BattlerAbility ability;

  const ItemAbilityPreparationResolution({
    required this.owner,
    required this.opponent,
    required this.ability,
  });
}

abstract class ItemEffect {
  final String description;

  const ItemEffect({
    required this.description,
  });

  String descriptionFor(Item item) => description;

  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damage,
  }) {
    return damage;
  }

  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damage,
  }) {
    return damage;
  }

  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    return ItemEffectResolution(owner: owner, opponent: target);
  }

  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    return ItemEffectResolution(owner: owner, opponent: source);
  }

  ItemEffectResolution applyPassive({
    required Battler owner,
    required Battler opponent,
    required Item item,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

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

  BattlerStatus? modifyOutgoingStatus({
    required Battler owner,
    required Battler target,
    required Item item,
    required BattlerStatus status,
  }) {
    return status;
  }

  BattlerStatus? modifyIncomingStatus({
    required Battler owner,
    required Battler source,
    required Item item,
    required BattlerStatus status,
  }) {
    return status;
  }

  Battler onReceiveFatalDamage({
    required Battler owner,
    required Item item,
    required int incomingDamage,
  }) {
    return owner;
  }
}

class IntoxicarOnAttackItemEffect extends ItemEffect {
  final int amount;

  const IntoxicarOnAttackItemEffect({
    this.amount = 1,
  }) : super(
          description:
              'Al atacar: intoxica el enemigo en 1, o aumenta su valor de Intoxicacion en 1.',
        );

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final currentPoison = target.statusById('intoxicacion');
    final updatedTarget = currentPoison is IntoxicacionStatus
        ? target.applyStatus(
            currentPoison.copyWith(value: currentPoison.value + amount),
            source: owner,
          )
        : target.applyStatus(
            IntoxicacionStatus(value: amount),
            source: owner,
          );

    return ItemEffectResolution(
      owner: owner,
      opponent: updatedTarget,
    );
  }
}

class QuemaduraOnAttackItemEffect extends ItemEffect {
  final int duration;

  const QuemaduraOnAttackItemEffect({
    this.duration = QuemaduraStatus.defaultDuration,
  }) : super(
          description:
              'Al atacar: anade un efecto de Quemadura de 3 turnos de duracion.',
        );

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    return ItemEffectResolution(
      owner: owner,
      opponent: target.applyStatus(
        QuemaduraStatus(remainingTurns: duration),
        source: owner,
      ),
    );
  }
}

class QuemaduraOnHitReceivedItemEffect extends ItemEffect {
  final int duration;

  const QuemaduraOnHitReceivedItemEffect({
    this.duration = 4,
  }) : super(
          description:
              'Al recibir un ataque: anade un efecto de Quemadura de 4 turnos de duracion.',
        );

  @override
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    return ItemEffectResolution(
      owner: owner,
      opponent: source.applyStatus(
        QuemaduraStatus(remainingTurns: duration),
        source: owner,
      ),
    );
  }
}

class CrackedBatteryItemEffect extends ItemEffect {
  const CrackedBatteryItemEffect()
      : super(
          description:
              'La primera habilidad manual que se resuelve en combate reduce su cooldown restante.',
        );

  @override
  String descriptionFor(Item item) {
    return 'La primera habilidad manual que se resuelve en combate reduce su cooldown en ${item.value}.';
  }

  @override
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

class ImpactGlovesItemEffect extends ItemEffect {
  const ImpactGlovesItemEffect()
      : super(
          description:
              'Tus ataques infligen dano adicional si el objetivo no tiene buffs.',
        );

  @override
  String descriptionFor(Item item) {
    return 'Tus ataques infligen ${item.value} de dano adicional si el objetivo no tiene buffs.';
  }

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

class ChemicalFilterItemEffect extends ItemEffect {
  const ChemicalFilterItemEffect()
      : super(
          description:
              'Reduce la Quemadura e Intoxicacion recibidas al aplicarse.',
        );

  @override
  String descriptionFor(Item item) {
    return 'Reduce la Quemadura e Intoxicacion recibidas en ${item.value} al aplicarse.';
  }

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

class BillingModuleItemEffect extends ItemEffect {
  const BillingModuleItemEffect()
      : super(
          description: 'Aumenta los ingresos, pero reduce la vida maxima.',
        );

  @override
  String descriptionFor(Item item) {
    final healthPenalty = item.maxHealthPercentModifier.abs();
    final incomeGain = item.incomeModifier;
    final sign = item.maxHealthPercentModifier > 0 ? '+' : '-';

    return '+$incomeGain INCOME mientras este equipado. $sign$healthPenalty% HP MAX mientras este equipado.';
  }
}

class PortableOvenItemEffect extends ItemEffect {
  const PortableOvenItemEffect()
      : super(
          description:
              'Tus Quemaduras duran mas, pero te quemas al final de tu turno.',
        );

  @override
  String descriptionFor(Item item) {
    return 'Las Quemaduras que aplicas duran ${item.value} turno mas. Al final de tu turno te aplicas Quemadura (${item.value}).';
  }

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

  @override
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

class ParasiticCapacitorItemEffect extends ItemEffect {
  const ParasiticCapacitorItemEffect()
      : super(
          description:
              'Cuando una habilidad entra en cooldown, recuperas vida.',
        );

  @override
  String descriptionFor(Item item) {
    return 'Cuando una habilidad entra en cooldown, te curas ${item.value} HP.';
  }

  @override
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

class EclipseMantleItemEffect extends ItemEffect {
  const EclipseMantleItemEffect()
      : super(
          description:
              'La primera activacion manual de cada combate obtiene un bonus al value.',
        );

  @override
  String descriptionFor(Item item) {
    return 'La primera activacion manual de cada combate obtiene +${item.value} al value.';
  }

  @override
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

class OperativeBlackBoxItemEffect extends ItemEffect {
  const OperativeBlackBoxItemEffect()
      : super(
          description:
              'Una vez por combate evita la muerte, deja 1 HP y refresca todas las habilidades.',
        );

  @override
  Battler onReceiveFatalDamage({
    required Battler owner,
    required Item item,
    required int incomingDamage,
  }) {
    if (!owner.hasCombatFlag(Battler.combatActiveFlag)) return owner;

    final usedFlag = _itemFlag(item, 'black_box_used');
    final protectionFlag = _itemFlag(item, 'black_box_protection');

    if (owner.hasCombatFlag(protectionFlag)) {
      return owner.copyWith(health: 1);
    }

    if (owner.hasCombatFlag(usedFlag)) return owner;

    return owner
        .copyWith(health: 1)
        .resetAllAbilities()
        .addCombatFlag(usedFlag)
        .addCombatFlag(protectionFlag);
  }

  @override
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

bool _enteredCooldown(
  BattlerAbility previousAbility,
  BattlerAbility resolvedAbility,
) {
  return !previousAbility.isOnCooldown && resolvedAbility.isOnCooldown;
}

String _itemFlag(Item item, String suffix) {
  return '${item.instanceId ?? item.id.name}_$suffix';
}
