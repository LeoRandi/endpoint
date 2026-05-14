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
      const InterferenciaStatus(),
      source: enemy,
    );

    expect(resolvedPlayer.hasStatus(InterferenciaStatus.statusId), isFalse);
    expect(resolvedPlayer.currentBarrier, 2);
  });

  test(
      'Punto Ciego prevents damage and target effects while attacker self effects resolve',
      () {
    final enemy = _battler(
      name: 'ENEMY',
      attack: 8,
      equippedItems: const [
        serratedEdgeItem,
        thermalTurbineItem,
      ],
    ).prepareForCombat();
    final player = _battler(
      name: 'PLAYER',
      abilities: const [puntoCiegoAbility],
    ).prepareForCombat();
    final activation = player.toggleAbilityActivation(
      abilityId: BattlerAbilityId.puntoCiego,
      screenContext: BattlerAbilityActivationContext.battle,
      opponent: enemy,
    );

    final attack = resolver.resolveAttack(
      attacker: activation.opponent,
      defender: activation.owner,
    );

    expect(attack.damageDealt, 0);
    expect(attack.defender.health, player.health);
    expect(attack.defender.hasStatus(FragilidadStatus.statusId), isFalse);
    expect(attack.attacker.hasStatus(CalentandoStatus.statusId), isTrue);
  });

  test('Cadencia Rapida caps manual ability cooldowns', () {
    final player = _battler(
      name: 'PLAYER',
      abilities: const [
        cadenciaRapidaAbility,
        eclipseManualAbility,
      ],
    ).enforceAbilityCooldownCap();

    final cappedAbility = player.abilityById(BattlerAbilityId.eclipseManual);

    expect(cappedAbility, isNotNull);
    expect(cappedAbility!.cooldownTurns, 3);
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

  test('Sobrecarga Regulada adds cooldown to the next manual ability', () {
    final enemy = _battler(name: 'ENEMY').prepareForCombat();
    final player = _battler(
      name: 'PLAYER',
      abilities: const [
        sobrecargaReguladaAbility,
        marcaDeCazaAbility,
      ],
    ).prepareForCombat();
    final overload = player.toggleAbilityActivation(
      abilityId: BattlerAbilityId.sobrecargaRegulada,
      screenContext: BattlerAbilityActivationContext.battle,
      opponent: enemy,
    );

    final marked = overload.owner.toggleAbilityActivation(
      abilityId: BattlerAbilityId.marcaDeCaza,
      screenContext: BattlerAbilityActivationContext.battle,
      opponent: overload.opponent,
    );
    final markAbility = marked.owner.abilityById(BattlerAbilityId.marcaDeCaza);

    expect(markAbility, isNotNull);
    expect(markAbility!.remainingCooldownTurns, 3);
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
      BattlerStat.thorns: 0,
      BattlerStat.damageReduction: 0,
      BattlerStat.vampirism: 0,
    },
    abilities: abilities,
    equippedItems: equippedItems,
  );
}
