import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = BattleResolver();

  test('Cortafuegos Portatil cancels incoming debuffs and grants barrier', () {
    final enemy = _battler(name: 'ENEMY').prepareForCombat();
    final player = _battler(
      name: 'PLAYER',
      abilities: const [cortafuegosPortatilAbility],
    ).prepareForCombat();

    final resolvedPlayer = player.applyStatusFromSource(
      const ConmocionStatus(value: 2),
      source: enemy,
    );

    expect(resolvedPlayer.hasStatus(ConmocionStatus.statusId), isFalse);
    expect(resolvedPlayer.currentBarrier, 2);
  });

  test('Opresion Tactica grants barrier when an enemy buff is consumed', () {
    final enemy = _battler(name: 'ENEMY').prepareForCombat().applyStatus(
          const PotenciaStatus(value: 2),
          applyEquipmentModifiers: false,
        );
    final player = _battler(
      name: 'PLAYER',
      abilities: const [opresionTacticaAbility],
    ).prepareForCombat();

    final attack = resolver.resolveAttack(
      attacker: enemy,
      defender: player,
    );

    expect(attack.attacker.hasStatus(PotenciaStatus.statusId), isFalse);
    expect(attack.defender.currentBarrier, 4);
  });

  test('Copia de Seguridad survives one lethal attack and gains barrier', () {
    final enemy = _battler(name: 'ENEMY', attack: 20).prepareForCombat();
    final player = _battler(
      name: 'PLAYER',
      health: 6,
      abilities: const [copiaDeSeguridadAbility],
    ).prepareForCombat();

    final attack = resolver.resolveAttack(
      attacker: enemy,
      defender: player,
    );

    expect(attack.defender.health, 1);
    expect(attack.defender.currentBarrier, 8);
    expect(attack.defender.isDefeated, isFalse);
  });
}

Battler _battler({
  required String name,
  int health = 30,
  int attack = 4,
  List<BattlerAbility> abilities = const [],
  List<Item> equippedItems = const [],
}) {
  return Battler(
    name: name,
    health: health,
    baseStats: <BattlerStat, int>{
      BattlerStat.health: health,
      BattlerStat.attack: attack,
      BattlerStat.barrier: 0,
    },
    abilities: abilities,
    equippedItems: equippedItems,
  );
}
