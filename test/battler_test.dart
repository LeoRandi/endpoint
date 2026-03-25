import 'package:flutter_test/flutter_test.dart';

import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';

void main() {
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
    final attacker = Battler.legacy(
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
    final secondAttack = resolver.resolveAttack(
      attacker: attacker.decrementStatusDurations(),
      defender: target,
    );

    expect(firstAttack.damageDealt, 4);
    expect(secondAttack.damageDealt, 5);
  });
}
