import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunSessionController', () {
    test('does not complete the run while editing the player at sunrise', () {
      final controller = _sunriseController();

      controller.updatePlayer(
        controller.player.copyWith(money: controller.player.money + 1),
      );

      expect(controller.isRunComplete, isFalse);
      expect(controller.completionType, isNull);
      expect(controller.currentHour.phase, RunHourPhase.sunrise);
      expect(controller.nodes.single.nodeId, yellowCombatNode.nodeId);
    });

    test('completes the run after winning the sunrise encounter', () {
      final controller = _sunriseController();

      controller.completeEncounter(
        result: BattleFlowResult(
          type: BattleFlowResultType.victory,
          player: controller.player,
        ),
        node: yellowCombatNode,
      );

      expect(controller.isRunComplete, isTrue);
      expect(controller.completionType, RunCompletionType.victory);
    });

    test('keeps battle defeats terminal at sunrise', () {
      final controller = _sunriseController();

      controller.completeEncounter(
        result: BattleFlowResult(
          type: BattleFlowResultType.defeat,
          player: controller.player.copyWith(health: 0),
        ),
        node: yellowCombatNode,
      );

      expect(controller.isRunComplete, isTrue);
      expect(controller.completionType, RunCompletionType.defeat);
    });
  });
}

RunSessionController _sunriseController() {
  final hour = RunHourSnapshot(
    stageIndex: PathNodeService.sunriseStageIndex,
    phase: RunHourPhase.sunrise,
    title: 'SUNRISE',
    subtitle: 'Solo queda un combate.',
    nodes: List<PathNode>.unmodifiable([yellowCombatNode]),
  );

  return RunSessionController.resume(
    snapshot: EndpointCurrentRunSnapshot(
      player: defaultPlayerBattler,
      currentHour: hour,
      visibleNodes: hour.nodes,
      stageIndex: PathNodeService.sunriseStageIndex,
      isResolvingNode: false,
      isRunComplete: false,
      completionType: null,
      randomSeed: 1,
      randomState: 1,
      battleEnemyTurnDelay: Duration.zero,
      battleCombatEndDelay: Duration.zero,
    ),
    persistRun: false,
  );
}
