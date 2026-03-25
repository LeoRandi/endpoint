import 'package:flutter_test/flutter_test.dart';

import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';

void main() {
  test('default player starts without altered statuses', () {
    expect(defaultPlayerBattler.statuses, isEmpty);
  });

  test('calculateDamageAgainst uses attack and defense with minimum 1', () {
    final attacker = Battler.legacy(
      name: 'Attacker',
      attack: 8,
      defense: 2,
      health: 10,
    );
    final target = Battler.legacy(
      name: 'Target',
      attack: 4,
      defense: 5,
      health: 10,
    );
    final tank = Battler.legacy(
      name: 'Tank',
      attack: 3,
      defense: 20,
      health: 10,
    );

    expect(attacker.calculateDamageAgainst(target), 3);
    expect(target.calculateDamageAgainst(tank), 1);
  });

  test('receiveAttack reduces health without going below zero', () {
    final attacker = Battler.legacy(
      name: 'Attacker',
      attack: 12,
      defense: 1,
      health: 10,
    );
    final target = Battler.legacy(
      name: 'Target',
      attack: 4,
      defense: 2,
      health: 5,
    );

    final updatedTarget = target.receiveAttack(attacker);

    expect(updatedTarget.health, 0);
    expect(updatedTarget.isDefeated, isTrue);
  });

  test('heal restores health without exceeding max health', () {
    final battler = Battler.legacy(
      name: 'Operative',
      attack: 6,
      defense: 3,
      health: 4,
      maxHealth: 10,
    );

    final healed = battler.heal(5);
    final overhealed = battler.heal(20);

    expect(healed.health, 9);
    expect(overhealed.health, 10);
  });

  test('addItem accepts duplicate item types as separate owned instances', () {
    final battler = Battler.legacy(
      name: 'Operative',
      attack: 6,
      defense: 3,
      health: 10,
    );

    final updatedBattler =
        battler.addItem(woodenStickItem).addItem(woodenStickItem);

    expect(updatedBattler.inventoryItems, hasLength(2));
    expect(updatedBattler.inventoryItems[0].id, ItemId.woodenStick);
    expect(updatedBattler.inventoryItems[1].id, ItemId.woodenStick);
    expect(updatedBattler.inventoryItems[0],
        isNot(updatedBattler.inventoryItems[1]));
  });

  test('calentando adds increasing bonus damage as turns are spent', () {
    var attacker = Battler.legacy(
      name: 'Operative',
      attack: 8,
      defense: 2,
      health: 10,
      statuses: const [CalentandoStatus()],
    );
    final target = Battler.legacy(
      name: 'Target',
      attack: 4,
      defense: 5,
      health: 20,
    );
    const resolver = BattleResolver();

    final firstAttack = resolver.resolveAttack(
      attacker: attacker,
      defender: target,
    );

    attacker = attacker
        .applyStatusTurnEnd(opponent: target, isOwnerTurn: true)
        .decrementStatusDurations();

    final secondAttack = resolver.resolveAttack(
      attacker: attacker,
      defender: target,
    );

    expect(firstAttack.damageDealt, 4);
    expect(secondAttack.damageDealt, 5);
  });

  test('quemadura deals remaining turns as end turn damage ignoring defense',
      () {
    final enemy = Battler.legacy(
      name: 'Enemy',
      attack: 1,
      defense: 0,
      health: 10,
    );
    var owner = Battler.legacy(
      name: 'Operative',
      attack: 5,
      defense: 99,
      health: 12,
      statuses: const [QuemaduraStatus(remainingTurns: 3)],
    );

    owner = owner
        .applyStatusTurnEnd(opponent: enemy, isOwnerTurn: true)
        .decrementStatusDurations();

    final burn = owner.statusById('quemadura') as QuemaduraStatus?;

    expect(owner.health, 9);
    expect(burn, isNotNull);
    expect(burn?.remainingTurns, 2);
    expect(burn?.value, 2);
  });

  test('quemadura can stack as separate statuses', () {
    final battler = Battler.legacy(
      name: 'Operative',
      attack: 4,
      defense: 2,
      health: 12,
    )
        .applyStatus(
          const QuemaduraStatus(remainingTurns: 4),
        )
        .applyStatus(
          const QuemaduraStatus(remainingTurns: 4),
        );

    expect(battler.statusesById('quemadura'), hasLength(2));
  });

  test('intoxicacion deals fixed end turn damage and does not expire', () {
    final enemy = Battler.legacy(
      name: 'Enemy',
      attack: 1,
      defense: 0,
      health: 10,
    );
    var owner = Battler.legacy(
      name: 'Operative',
      attack: 5,
      defense: 99,
      health: 10,
      statuses: const [IntoxicacionStatus()],
    );

    owner = owner
        .applyStatusTurnEnd(opponent: enemy, isOwnerTurn: true)
        .decrementStatusDurations();

    final firstPoison = owner.statusById('intoxicacion') as IntoxicacionStatus?;

    expect(owner.health, 9);
    expect(firstPoison, isNotNull);
    expect(firstPoison?.remainingTurns, 1);
    expect(firstPoison?.remainingTurnsLabel, 'Indefinido');
    expect(firstPoison?.value, 1);

    owner = owner
        .applyStatusTurnEnd(opponent: enemy, isOwnerTurn: true)
        .decrementStatusDurations();

    final secondPoison =
        owner.statusById('intoxicacion') as IntoxicacionStatus?;

    expect(owner.health, 8);
    expect(secondPoison, isNotNull);
    expect(secondPoison?.remainingTurns, 1);
    expect(secondPoison?.value, 1);
  });

  test('attack item effect applies intoxicacion and increases its value', () {
    final attacker = Battler.legacy(
      name: 'Operative',
      attack: 6,
      defense: 2,
      health: 10,
      equippedItems: const [toxicCatalystItem],
    );
    final target = Battler.legacy(
      name: 'Target',
      attack: 4,
      defense: 1,
      health: 20,
    );
    const resolver = BattleResolver();

    final firstAttack = resolver.resolveAttack(
      attacker: attacker,
      defender: target,
    );
    final firstPoison =
        firstAttack.defender.statusById('intoxicacion') as IntoxicacionStatus?;

    expect(firstPoison, isNotNull);
    expect(firstPoison?.value, 1);

    final secondAttack = resolver.resolveAttack(
      attacker: firstAttack.attacker,
      defender: firstAttack.defender,
    );
    final secondPoison =
        secondAttack.defender.statusById('intoxicacion') as IntoxicacionStatus?;

    expect(secondPoison, isNotNull);
    expect(secondPoison?.value, 2);
  });

  test('receive item effect adds stacked quemadura to the attacker', () {
    final attacker = Battler.legacy(
      name: 'Attacker',
      attack: 6,
      defense: 2,
      health: 14,
    );
    final defender = Battler.legacy(
      name: 'Defender',
      attack: 3,
      defense: 1,
      health: 18,
      equippedItems: const [reactiveCasingItem],
    );
    const resolver = BattleResolver();

    final firstAttack = resolver.resolveAttack(
      attacker: attacker,
      defender: defender,
    );
    expect(firstAttack.attacker.statusesById('quemadura'), hasLength(1));
    expect(
      (firstAttack.attacker.statusesById('quemadura').first as QuemaduraStatus)
          .remainingTurns,
      4,
    );

    final secondAttack = resolver.resolveAttack(
      attacker: firstAttack.attacker,
      defender: firstAttack.defender,
    );
    expect(secondAttack.attacker.statusesById('quemadura'), hasLength(2));
  });
}
