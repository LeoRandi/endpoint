import 'package:flutter_test/flutter_test.dart';

import 'package:endpoint/entities/battler/battler.dart';

void main() {
  test('calculateDamageAgainst uses attack and defense with minimum 1', () {
    const attacker = Battler(
      name: 'Attacker',
      attack: 8,
      defense: 2,
      health: 10,
    );
    const target = Battler(
      name: 'Target',
      attack: 4,
      defense: 5,
      health: 10,
    );
    const tank = Battler(
      name: 'Tank',
      attack: 3,
      defense: 20,
      health: 10,
    );

    expect(attacker.calculateDamageAgainst(target), 3);
    expect(target.calculateDamageAgainst(tank), 1);
  });

  test('receiveAttack reduces health without going below zero', () {
    const attacker = Battler(
      name: 'Attacker',
      attack: 12,
      defense: 1,
      health: 10,
    );
    const target = Battler(
      name: 'Target',
      attack: 4,
      defense: 2,
      health: 5,
    );

    final updatedTarget = target.receiveAttack(attacker);

    expect(updatedTarget.health, 0);
    expect(updatedTarget.isDefeated, isTrue);
  });
}
