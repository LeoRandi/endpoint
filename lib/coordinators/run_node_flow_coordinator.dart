import '../app/_exports.dart';
import '../entities/_exports.dart';
import '../pages/_exports.dart';
import '../services/_exports.dart';
import '../widgets/generic/_exports.dart';
import 'package:flutter/material.dart';

class RunNodeFlowCoordinator {
  const RunNodeFlowCoordinator();

  // Keeps node-to-scene routing out of the path page.
  Future<void> handleNodeSelection({
    required BuildContext context,
    required PathNode node,
    required RunSessionController session,
  }) async {
    switch (node.type) {
      case PathNodeType.encounter:
        final encounterNode = node as CombatPathNode;
        await _openNodeScene<BattleFlowResult>(
          context: context,
          session: session,
          page: BattlePage(
            enemy: encounterNode.enemy,
            player: session.player,
            randomizer: session.randomizer,
            showTitle: encounterNode.showTitle,
            victoryMoneyFactor: encounterNode.tier.factor,
            enemyTurnDelay: session.state.battleEnemyTurnDelay,
            combatEndDelay: session.state.battleCombatEndDelay,
            returnResultToCaller: true,
          ),
          onCompleted: (result) => session.completeEncounter(
            result: result,
            node: encounterNode,
          ),
        );
        return;
      case PathNodeType.archetype:
        final archetypeNode = node as ArchetypePathNode;
        final projectedPlayer = archetypeNode.applyTo(
          session.player,
          resolveDynamicStartingItems: false,
        );
        final shouldConfirm = await showEndpointDialog<bool>(
          context: context,
          barrierLabel: 'Seleccionar arquetipo',
          barrierColor: EndpointPalette.overlayScrimStrong,
          builder: (context) {
            return ArchetypeSelectionDialog(
              player: session.player,
              archetype: archetypeNode,
              projectedPlayer: projectedPlayer,
            );
          },
        );
        if (shouldConfirm == true) {
          session.completeArchetypeSelection(
            archetypeNode.applyTo(
              session.player,
              randomizer: session.randomizer,
            ),
          );
          return;
        }

        session.cancelNodeResolution();
        return;
      case PathNodeType.shop:
        final shopNode = node as ShopPathNode;
        await _openNodeScene<WeaponShopVisitResult>(
          context: context,
          session: session,
          page: WeaponShopPage(
            player: session.player,
            shop: shopNode,
            randomizer: session.randomizer,
            phase: session.currentHour.phase,
            stockPool: itemPoolForArchetype(session.player.archetypeId),
          ),
          onCompleted: session.completeWeaponShopVisit,
        );
        return;
      case PathNodeType.campSite:
        final campNode = node is CampSitePathNode ? node : null;
        await _openNodeScene<CampSiteVisitResult>(
          context: context,
          session: session,
          page: CampSitePage(
            player: session.player,
            recoveryService: CampSiteService(
              recoveryFactor: campNode?.recoveryFactor ?? 1,
              removeRandomDebuff: campNode?.removeRandomDebuff ?? false,
            ),
            randomizer: session.randomizer,
            showTitle:
                campNode?.showTitle ?? 'Has encontrado una zona de descanso',
            sceneTitle: campNode?.sceneTitle ?? 'ZONA DE DESCANSO',
            description: campNode?.description ?? 'Recuperas toda tu vida.',
            iconEmoji: campNode?.iconEmoji ?? '\u{1F6CF}',
            accent: campNode?.accent ?? EndpointPalette.primaryAccent,
          ),
          onCompleted: session.completeCampVisit,
        );
        return;
      case PathNodeType.event:
        final eventNode = node as EventPathNode;
        await _openNodeScene<PathEventVisitResult>(
          context: context,
          session: session,
          page: PathEventPage(
            player: session.player,
            node: eventNode,
          ),
          onCompleted: session.completeEventVisit,
        );
        return;
    }
  }

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
