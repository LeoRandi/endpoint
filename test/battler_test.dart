import 'package:flutter_test/flutter_test.dart';

import 'package:endpoint/entities/battler/battler.dart';

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
}
