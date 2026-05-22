import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PathNodeService', () {
    test('uses a single archetype stage and then 12 stages per day', () {
      expect(PathNodeService.startStageIndex, 0);
      expect(PathNodeService.firstStageIndexForDay(1), 1);
      expect(PathNodeService.firstDayBossStageIndex, 12);
      expect(PathNodeService.firstStageIndexForDay(2), 13);
      expect(
        PathNodeService.bossStageIndexForDay(2) -
            PathNodeService.firstStageIndexForDay(2) +
            1,
        PathNodeService.stagesPerDay,
      );
    });

    test('builds fixed dusk combat tiers for the first day', () {
      final service = PathNodeService(randomizer: RunRandomizer(seed: 7));

      final hour = service.buildHourSnapshot(
        stageIndex: PathNodeService.duskStageIndex,
        player: defaultPlayerBattler,
      );
      final combatNodes = hour.nodes.whereType<CombatPathNode>().toList();

      expect(hour.phase, RunHourPhase.dusk);
      expect(combatNodes, hasLength(3));
      expect(
        combatNodes.map((node) => node.tier),
        containsAllInOrder([
          CombatNodeTier.gray,
          CombatNodeTier.gray,
          CombatNodeTier.green,
        ]),
      );
    });

    test('builds purple dusk and yellow final boss on day five', () {
      final service = PathNodeService(randomizer: RunRandomizer(seed: 11));

      final dusk = service.buildHourSnapshot(
        stageIndex: PathNodeService.firstStageIndexForDay(5) +
            PathNodeService.duskStageOffset,
        player: defaultPlayerBattler,
      );
      final finalBoss = service.buildHourSnapshot(
        stageIndex: PathNodeService.sunriseStageIndex,
        player: defaultPlayerBattler,
      );

      expect(
        dusk.nodes.whereType<CombatPathNode>().map((node) => node.tier),
        everyElement(CombatNodeTier.purple),
      );
      expect(finalBoss.nodes.single, isA<CombatPathNode>());
      expect(
        (finalBoss.nodes.single as CombatPathNode).tier,
        CombatNodeTier.yellow,
      );
    });

    test('normal path selections contain at most one shop', () {
      for (var seed = 1; seed <= 20; seed++) {
        final service = PathNodeService(randomizer: RunRandomizer(seed: seed));

        for (var stageIndex = PathNodeService.firstPlayableStageIndex;
            stageIndex < PathNodeService.firstDayBossStageIndex;
            stageIndex++) {
          final hour = service.buildHourSnapshot(
            stageIndex: stageIndex,
            player: defaultPlayerBattler,
          );

          expect(
            hour.nodes.whereType<ShopPathNode>(),
            hasLength(lessThanOrEqualTo(1)),
          );
        }
      }
    });

    test('shop selection prefers unshown eligible shops until cycle resets',
        () {
      final service = PathNodeService(randomizer: RunRandomizer(seed: 3));
      const stageIndex = PathNodeService.firstPlayableStageIndex;
      final eligibleShopNodeIds = service.eligibleShopNodeIdsFor(
        stageIndex: stageIndex,
        player: defaultPlayerBattler,
      );
      final remainingShopNodeId = eligibleShopNodeIds.first;
      final shownShopNodeIds = eligibleShopNodeIds
          .where((nodeId) => nodeId != remainingShopNodeId)
          .toList(growable: false);

      final hour = service.buildHourSnapshot(
        stageIndex: stageIndex,
        player: defaultPlayerBattler,
        shownShopNodeIds: shownShopNodeIds,
      );

      expect(hour.nodes.whereType<ShopPathNode>().single.nodeId,
          remainingShopNodeId);

      final resetHour = service.buildHourSnapshot(
        stageIndex: stageIndex,
        player: defaultPlayerBattler,
        shownShopNodeIds: eligibleShopNodeIds,
      );

      expect(resetHour.nodes.whereType<ShopPathNode>(), hasLength(1));
      expect(
        eligibleShopNodeIds,
        contains(resetHour.nodes.whereType<ShopPathNode>().single.nodeId),
      );
    });

    test('filters shop nodes that would have empty stock', () {
      final service = PathNodeService(
        randomizer: RunRandomizer(seed: 5),
        shopStockService: const _EmptyShopStockService(),
      );

      final hour = service.buildHourSnapshot(
        stageIndex: PathNodeService.firstPlayableStageIndex,
        player: defaultPlayerBattler,
        availableNodes: [
          scrapArsenalNode,
          grayCombatNode,
          greenCombatNode,
        ],
      );

      expect(hour.nodes.whereType<ShopPathNode>(), isEmpty);
      expect(
        hour.nodes.map((node) => node.nodeId),
        isNot(contains(scrapArsenalNode.nodeId)),
      );
    });
  });

  group('RunSessionController', () {
    test('does not complete the run while editing the player at final boss',
        () {
      final controller = _bossController(
        dayNumber: PathNodeService.maxDayNumber,
        node: yellowCombatNode,
      );

      controller.updatePlayer(
        controller.player.copyWith(money: controller.player.money + 1),
      );

      expect(controller.isRunComplete, isFalse);
      expect(controller.completionType, isNull);
      expect(controller.currentHour.phase, RunHourPhase.sunrise);
      expect(controller.nodes.single.nodeId, yellowCombatNode.nodeId);
    });

    test('winning a non-final daily boss opens the day summary', () {
      final controller = _bossController(
        dayNumber: 1,
        node: blueCombatNode,
      );
      final rewardedPlayer = controller.player.earnMoney(6).copyWith(
        inventoryItems: const [ironSwordItem],
        abilities: const [weaknessHunterAbility],
      );

      controller.completeEncounter(
        result: BattleFlowResult(
          type: BattleFlowResultType.victory,
          player: rewardedPlayer,
        ),
        node: blueCombatNode,
      );

      final summary = controller.pendingDaySummary!;
      expect(controller.isRunComplete, isFalse);
      expect(controller.completionType, isNull);
      expect(controller.hasPendingDaySummary, isTrue);
      expect(controller.nodes, isEmpty);
      expect(summary.dayNumber, 1);
      expect(summary.enemiesKilled, 1);
      expect(summary.moneyGained, 6);
      expect(summary.defeatedEnemies, hasLength(1));
      expect(summary.defeatedEnemies.single.name, blueCombatNode.enemy.name);
      expect(summary.defeatedEnemies.single.rarity, blueCombatNode.tier.rarity);
      expect(
        summary.defeatedEnemies.single.battler.equippedItems.map(
          (item) => item.id,
        ),
        blueCombatNode.enemy.equippedItems.map((item) => item.id),
      );
      expect(
        summary.defeatedEnemies.single.battler.abilities.map(
          (ability) => ability.id,
        ),
        blueCombatNode.enemy.abilities.map((ability) => ability.id),
      );
      expect(summary.gainedRewards, hasLength(2));
      expect(
        summary.gainedRewards
            .where((reward) => reward.type == RunDaySummaryRewardType.item)
            .single
            .item
            ?.id,
        ItemId.ironSword,
      );
      expect(
        summary.gainedRewards
            .where((reward) => reward.type == RunDaySummaryRewardType.ability)
            .single
            .ability
            ?.id,
        BattlerAbilityId.weaknessHunter,
      );

      final restoredSummary = RunDaySummary.fromJson(summary.toJson())!;
      expect(restoredSummary.defeatedEnemies.single.name,
          blueCombatNode.enemy.name);
      expect(
        restoredSummary.gainedRewards
            .where((reward) => reward.type == RunDaySummaryRewardType.item)
            .single
            .item
            ?.id,
        ItemId.ironSword,
      );
      expect(
        restoredSummary.gainedRewards
            .where((reward) => reward.type == RunDaySummaryRewardType.ability)
            .single
            .ability
            ?.id,
        BattlerAbilityId.weaknessHunter,
      );
    });

    test('continuing after the day summary starts day two without archetypes',
        () {
      final controller = _bossController(
        dayNumber: 1,
        node: blueCombatNode,
      );

      controller.completeEncounter(
        result: BattleFlowResult(
          type: BattleFlowResultType.victory,
          player: controller.player,
        ),
        node: blueCombatNode,
      );

      expect(controller.continueToNextDay(), isTrue);

      expect(
        controller.state.stageIndex,
        PathNodeService.firstStageIndexForDay(2),
      );
      expect(controller.currentHour.phase, RunHourPhase.day);
      expect(controller.pendingDaySummary, isNull);
      expect(controller.currentDaySummary.dayNumber, 2);
      expect(
        controller.nodes.whereType<ArchetypePathNode>(),
        isEmpty,
      );
    });

    test('continuing after the day summary heals and purges debuffs', () {
      final damagedPlayer = defaultPlayerBattler.copyWith(
        health: defaultPlayerBattler.maxHealth - 4,
        statuses: const [
          QuemaduraStatus(),
          IntoxicacionStatus(),
        ],
      );
      final controller = _bossController(
        dayNumber: 1,
        node: blueCombatNode,
        player: damagedPlayer,
      );

      controller.completeEncounter(
        result: BattleFlowResult(
          type: BattleFlowResultType.victory,
          player: controller.player,
        ),
        node: blueCombatNode,
      );
      controller.continueToNextDay();

      expect(controller.player.health, controller.player.maxHealth);
      expect(
        controller.player.statuses
            .where((status) => status.type == BattlerStatusType.debuff),
        isEmpty,
      );
    });

    test('completes the run after winning the day five boss', () {
      final controller = _bossController(
        dayNumber: PathNodeService.maxDayNumber,
        node: yellowCombatNode,
      );

      controller.completeEncounter(
        result: BattleFlowResult(
          type: BattleFlowResultType.victory,
          player: controller.player,
        ),
        node: yellowCombatNode,
      );

      expect(controller.isRunComplete, isTrue);
      expect(controller.completionType, RunCompletionType.victory);
      expect(controller.hasPendingDaySummary, isFalse);
    });

    test('keeps battle defeats terminal at final boss', () {
      final controller = _bossController(
        dayNumber: PathNodeService.maxDayNumber,
        node: yellowCombatNode,
      );

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

RunSessionController _bossController({
  required int dayNumber,
  required CombatPathNode node,
  Battler player = defaultPlayerBattler,
}) {
  final stageIndex = PathNodeService.bossStageIndexForDay(dayNumber);
  final hour = RunHourSnapshot(
    stageIndex: stageIndex,
    phase: RunHourPhase.sunrise,
    title: 'DIA $dayNumber - BOSS',
    subtitle: 'Solo queda un combate.',
    nodes: List<PathNode>.unmodifiable([node]),
  );

  return RunSessionController.resume(
    snapshot: EndpointCurrentRunSnapshot(
      player: player,
      currentHour: hour,
      visibleNodes: hour.nodes,
      stageIndex: stageIndex,
      isResolvingNode: false,
      isRunComplete: false,
      completionType: null,
      randomSeed: 1,
      randomState: 1,
      battleEnemyTurnDelay: Duration.zero,
      battleCombatEndDelay: Duration.zero,
      currentDaySummary: RunDaySummary.empty(dayNumber: dayNumber),
    ),
    persistRun: false,
  );
}

class _EmptyShopStockService extends WeaponShopStockService {
  const _EmptyShopStockService();

  @override
  bool hasAvailableStock({
    required ShopInventoryCriterion criterion,
    required RunHourPhase phase,
    Battler? player,
    int dayNumber = 1,
    List<Item> pool = itemPresets,
  }) {
    return false;
  }
}
