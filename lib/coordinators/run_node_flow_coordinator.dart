import 'dart:async';

import '../app/_exports.dart';
import '../entities/_exports.dart';
import '../pages/_exports.dart';
import '../services/_exports.dart';
import '../widgets/generic/_exports.dart';
import 'package:flutter/material.dart';

typedef _RunNodeHandler = Future<void> Function({
  required BuildContext context,
  required PathNode node,
  required RunSessionController session,
  required bool isTutorialRun,
});

/// Coordinates route-node selection into the scene that resolves that node.
///
/// Path selection owns input and session state; pages own visual interactions;
/// this coordinator is the narrow navigation boundary that translates a
/// [PathNode] into a scene and forwards the scene result back to
/// [RunSessionController].
class RunNodeFlowCoordinator {
  /// Creates a stateless node-flow coordinator.
  const RunNodeFlowCoordinator();

  /// Opens the correct scene for [node] and completes or cancels the session.
  ///
  /// The caller must have already called `session.beginNodeResolution`; this
  /// method only resolves the active node by pushing a scene, showing a dialog,
  /// or canceling the node when the user backs out.
  Future<void> handleNodeSelection({
    required BuildContext context,
    required PathNode node,
    required RunSessionController session,
    bool isTutorialRun = false,
  }) async {
    final handler = _nodeHandlers[node.type];
    if (handler == null) {
      _cancelUnsupportedNode(session, node, expectedType: node.type.name);
      return;
    }

    await handler(
      context: context,
      node: node,
      session: session,
      isTutorialRun: isTutorialRun,
    );
  }

  Map<PathNodeType, _RunNodeHandler> get _nodeHandlers => {
        PathNodeType.encounter: _handleEncounterSelection,
        PathNodeType.archetype: _handleArchetypeSelection,
        PathNodeType.shop: _handleShopSelection,
        PathNodeType.campSite: _handleCampSiteSelection,
        PathNodeType.event: _handleEventSelection,
      };

  Future<void> _handleEncounterSelection({
    required BuildContext context,
    required PathNode node,
    required RunSessionController session,
    required bool isTutorialRun,
  }) async {
    final encounterNode = node is CombatPathNode ? node : null;
    if (encounterNode == null) {
      _cancelUnsupportedNode(session, node, expectedType: 'CombatPathNode');
      return;
    }

    _markCodexIndexed(CodexDiscoveryService.enemyKey(encounterNode.nodeId));
    await _openEncounterNode(
      context: context,
      node: encounterNode,
      session: session,
    );
  }

  Future<void> _handleArchetypeSelection({
    required BuildContext context,
    required PathNode node,
    required RunSessionController session,
    required bool isTutorialRun,
  }) async {
    final archetypeNode = node is ArchetypePathNode ? node : null;
    if (archetypeNode == null) {
      _cancelUnsupportedNode(session, node, expectedType: 'ArchetypePathNode');
      return;
    }

    await _openArchetypeNode(
      context: context,
      node: archetypeNode,
      session: session,
      isTutorialRun: isTutorialRun,
    );
  }

  Future<void> _handleShopSelection({
    required BuildContext context,
    required PathNode node,
    required RunSessionController session,
    required bool isTutorialRun,
  }) async {
    final shopNode = _shopNodeFor(node);
    _markCodexIndexed(CodexDiscoveryService.shopKey(shopNode.nodeId));
    await _openShopNode(
      context: context,
      node: shopNode,
      session: session,
    );
  }

  Future<void> _handleCampSiteSelection({
    required BuildContext context,
    required PathNode node,
    required RunSessionController session,
    required bool isTutorialRun,
  }) {
    return _openCampSiteNode(
      context: context,
      node: node,
      session: session,
    );
  }

  Future<void> _handleEventSelection({
    required BuildContext context,
    required PathNode node,
    required RunSessionController session,
    required bool isTutorialRun,
  }) async {
    final eventNode = node is EventPathNode ? node : null;
    if (eventNode == null) {
      _cancelUnsupportedNode(session, node, expectedType: 'EventPathNode');
      return;
    }

    _markCodexIndexed(CodexDiscoveryService.eventKey(eventNode.id));
    await _openEventNode(
      context: context,
      node: eventNode,
      session: session,
    );
  }

  void _markCodexIndexed(String key) {
    unawaited(CodexDiscoveryService.markIndexed(key));
  }

  void _cancelUnsupportedNode(
    RunSessionController session,
    PathNode node, {
    required String expectedType,
  }) {
    assert(() {
      debugPrint(
        'RunNodeFlowCoordinator expected $expectedType for '
        '${node.type.name} node ${node.nodeId}.',
      );
      return true;
    }());
    session.cancelNodeResolution();
  }

  ShopPathNode _shopNodeFor(PathNode node) {
    if (node is ShopPathNode) return node;

    return ShopPathNode(
      nodeId: node.nodeId,
      label: node.label,
      tooltip: node.tooltip,
      iconEmoji: node.iconEmoji,
      rarity: node.rarity,
      badgeLabel: node.badgeLabel,
      showTitle: node.label,
      shopTitle: node.label.toUpperCase(),
      shopSubtitle: node.tooltip,
      stockCriterion: grayShopCriterion,
    );
  }

  /// Opens a combat scene and forwards the battle result to the active run.
  ///
  /// Combat returns a [BattleFlowResult] for victory, defeat, or escape; the
  /// session controller then decides how the path advances and whether the run
  /// has ended.
  Future<void> _openEncounterNode({
    required BuildContext context,
    required CombatPathNode node,
    required RunSessionController session,
  }) {
    return _openNodeScene<BattleFlowResult>(
      context: context,
      session: session,
      page: BattlePage(
        enemy: node.enemy,
        player: session.player,
        randomizer: session.randomizer,
        phase: session.currentHour.phase,
        showTitle: node.showTitle,
        victoryMoneyFactor: node.tier.factor,
        enemyTier: node.tier.factor,
        enemyTurnDelay: session.state.battleEnemyTurnDelay,
        combatEndDelay: session.state.battleCombatEndDelay,
        returnResultToCaller: true,
      ),
      onCompleted: (result) => session.completeEncounter(
        result: result,
        node: node,
      ),
    );
  }

  /// Opens the archetype confirmation dialog and applies the chosen archetype.
  ///
  /// The preview uses deterministic starting items so the player can inspect
  /// base stats without spending random starting-item rolls until confirmation.
  Future<void> _openArchetypeNode({
    required BuildContext context,
    required ArchetypePathNode node,
    required RunSessionController session,
    required bool isTutorialRun,
  }) async {
    final projectedPlayer = node.applyTo(
      session.player,
      resolveDynamicStartingItems: false,
    );
    final shouldConfirm = await showEndpointDialog<bool>(
      context: context,
      barrierLabel: 'Seleccionar arquetipo',
      barrierDismissible: !isTutorialRun,
      barrierColor: EndpointPalette.overlayScrimStrong,
      builder: (context) {
        return ArchetypeSelectionDialog(
          player: session.player,
          archetype: node,
          projectedPlayer: projectedPlayer,
          isTutorialRun: isTutorialRun,
        );
      },
    );
    if (shouldConfirm == true) {
      unawaited(
        CodexDiscoveryService.markIndexed(
          CodexDiscoveryService.archetypeKey(node.archetypeId),
        ),
      );
      session.completeArchetypeSelection(
        node.applyTo(
          session.player,
          randomizer: session.randomizer,
        ),
      );
      return;
    }

    session.cancelNodeResolution();
  }

  /// Opens a weapon shop scene using the current day, phase, and archetype pool.
  ///
  /// The shop page owns buying/selling interactions; the coordinator only
  /// provides the stock context and forwards [WeaponShopVisitResult].
  Future<void> _openShopNode({
    required BuildContext context,
    required ShopPathNode node,
    required RunSessionController session,
  }) {
    return _openNodeScene<WeaponShopVisitResult>(
      context: context,
      session: session,
      page: WeaponShopPage(
        player: session.player,
        shop: node,
        randomizer: session.randomizer,
        phase: session.currentHour.phase,
        dayNumber: PathNodeService.dayNumberForStageIndex(
          session.currentHour.stageIndex,
        ),
        stockPool: itemPresets,
      ),
      onCompleted: session.completeWeaponShopVisit,
    );
  }

  /// Opens a camp-site scene, falling back to the generic preview node values.
  ///
  /// Most camp nodes are [CampSitePathNode] instances with custom recovery
  /// rules. The base [PathNode.campSite] constructor remains supported for
  /// previews and lightweight fixtures.
  Future<void> _openCampSiteNode({
    required BuildContext context,
    required PathNode node,
    required RunSessionController session,
  }) {
    final campNode = node is CampSitePathNode ? node : null;

    return _openNodeScene<CampSiteVisitResult>(
      context: context,
      session: session,
      page: CampSitePage(
        player: session.player,
        recoveryService: CampSiteService(
          recoveryFactor: campNode?.recoveryFactor ?? 1,
          removeRandomDebuff: campNode?.removeRandomDebuff ?? false,
        ),
        randomizer: session.randomizer,
        showTitle: campNode?.showTitle ?? 'Has encontrado una zona de descanso',
        sceneTitle: campNode?.sceneTitle ?? 'ZONA DE DESCANSO',
        description: campNode?.description ?? 'Recuperas toda tu vida.',
        iconEmoji: campNode?.iconEmoji ?? '\u{1F6CF}',
        accent: campNode?.accent ?? EndpointPalette.primaryAccent,
      ),
      onCompleted: session.completeCampVisit,
    );
  }

  /// Opens a path-event scene and forwards the event result to the run session.
  ///
  /// Event-specific pages are resolved by the event page registry, which keeps
  /// this coordinator independent from every concrete event widget.
  Future<void> _openEventNode({
    required BuildContext context,
    required EventPathNode node,
    required RunSessionController session,
  }) {
    return _openNodeScene<PathEventVisitResult>(
      context: context,
      session: session,
      page: buildPathEventPage(
        player: session.player,
        node: node,
        randomizer: session.randomizer,
        dayNumber: PathNodeService.dayNumberForStageIndex(
          session.currentHour.stageIndex,
        ),
      ),
      onCompleted: session.completeEventVisit,
    );
  }

  /// Pushes a node scene and completes or cancels the active node resolution.
  ///
  /// A `null` result means the user backed out or the scene closed without a
  /// decision, so the session must leave node-resolution mode instead of
  /// advancing the route.
  Future<void> _openNodeScene<T>({
    required BuildContext context,
    required RunSessionController session,
    required Widget page,
    required void Function(T result) onCompleted,
  }) async {
    final result = await Navigator.of(context).push<T>(
      buildEndpointSceneRoute<T>(page),
    );

    if (!context.mounted) return;
    if (result == null) {
      session.cancelNodeResolution();
      return;
    }

    onCompleted(result);
  }
}
