import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Guante de Reto consumes Desafio before the main attack', () async {
    final cues = <BattleCombatAnimationCue>[];
    final controller = _controller(
      player: _battler(
        name: 'PLAYER',
        health: 30,
        attack: 1,
        equippedItems: const <Item>[guanteRetoItem],
      ),
      enemy: _battler(
        name: 'ENEMY',
        health: 30,
        attack: 1,
      ),
      cues: cues,
    );

    await controller.handleAttack();

    expect(controller.enemy.health, 25);
    expect(controller.player.health, 28);
    expect(controller.player.hasStatus(DesafioStatus.statusId), isFalse);

    final attackCues = _attackCues(cues);
    expect(attackCues.map((cue) => cue.primarySide), <BattleCombatantSide>[
      BattleCombatantSide.player,
      BattleCombatantSide.player,
      BattleCombatantSide.enemy,
    ]);
    expect(attackCues.map((cue) => cue.motionAsset), <BattleCombatMotionAsset>[
      BattleCombatMotionAsset.fist,
      BattleCombatMotionAsset.sword,
      BattleCombatMotionAsset.fist,
    ]);
    expect(attackCues.map((cue) => cue.effectCount), <int>[1, 1, 1]);

    controller.dispose();
  });

  test('Desafio direct hits do not trigger attack resolved effects', () async {
    final controller = _controller(
      player: _battler(
        name: 'PLAYER',
        health: 30,
        attack: 1,
        equippedItems: const <Item>[guanteRetoItem, cyberWhipsItem],
      ),
      enemy: _battler(
        name: 'ENEMY',
        health: 30,
        attack: 1,
      ),
    );

    await controller.handleAttack();

    final poison = controller.enemy.statusById(IntoxicacionStatus.statusId);
    expect(poison, isA<IntoxicacionStatus>());
    expect(poison!.value, 1);

    controller.dispose();
  });

  test('Desafio stacks and heals at combat end if it was kept', () {
    final battler = _battler(
      name: 'PLAYER',
      health: 10,
      maxHealth: 20,
      attack: 1,
    )
        .prepareForCombat()
        .applyStatus(
          const DesafioExcitanteStatus(value: 2),
          applyEquipmentModifiers: false,
        )
        .gainDesafio(3)
        .gainDesafio(4);

    expect(battler.desafioValue, 11);

    final finalized = battler.finalizeCombatState();
    expect(finalized.health, 20);
    expect(finalized.hasStatus(DesafioStatus.statusId), isFalse);
    expect(finalized.hasStatus(DesafioExcitanteStatus.statusId), isFalse);
  });
}

BattleController _controller({
  required Battler player,
  required Battler enemy,
  List<BattleCombatAnimationCue>? cues,
}) {
  return BattleController(
    player: player,
    enemy: enemy,
    phase: RunHourPhase.day,
    enemyTier: 1,
    enemyTurnDelay: const Duration(days: 1),
    combatEndDelay: const Duration(days: 1),
    onCombatAnimation: cues == null
        ? null
        : (cue) async {
            cues.add(cue);
          },
  );
}

Battler _battler({
  required String name,
  required int health,
  int? maxHealth,
  required int attack,
  List<Item> equippedItems = const <Item>[],
  List<BattlerAbility> abilities = const <BattlerAbility>[],
}) {
  return Battler(
    name: name,
    health: health,
    money: 0,
    income: 0,
    baseStats: <BattlerStat, int>{
      BattlerStat.health: maxHealth ?? health,
      BattlerStat.attack: attack,
      BattlerStat.barrier: 0,
      BattlerStat.thorns: 0,
      BattlerStat.damageReduction: 0,
      BattlerStat.vampirism: 0,
    },
    equippedItems: equippedItems,
    abilities: abilities,
  );
}

List<BattleCombatAnimationCue> _attackCues(
  List<BattleCombatAnimationCue> cues,
) {
  return cues
      .where((cue) => cue.hook == BattleCombatAnimationHook.attackMotion)
      .toList(growable: false);
}
