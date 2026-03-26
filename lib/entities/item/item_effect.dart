import '_imports.dart';

class ItemEffectResolution {
  final Battler owner;
  final Battler opponent;

  const ItemEffectResolution({
    required this.owner,
    required this.opponent,
  });
}

abstract class ItemEffect {
  final String description;

  const ItemEffect({
    required this.description,
  });

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
          )
        : target.applyStatus(IntoxicacionStatus(value: amount));

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
      ),
    );
  }
}
