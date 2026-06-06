import 'dart:convert';
import 'dart:math';

import '../../entities/_exports.dart';
import '../path/path_node_service.dart';
import '../run/run_completion_type.dart';
import '../run/run_day_summary.dart';
import '../run/run_hour_snapshot.dart';
import '../run/run_randomizer.dart';
import '../run/run_state.dart';
import '../runtime/ghost_item_lease.dart';
import 'endpoint_domain_codec.dart';
import 'endpoint_json_utils.dart';
import 'endpoint_preferences_models.dart';

abstract final class EndpointCurrentRunSnapshotCodec {
  static const JsonEncoder _jsonEncoder = JsonEncoder.withIndent('  ');

  static String encode({
    required RunState state,
    required RunRandomizer randomizer,
    required bool isResolvingNode,
    required String trigger,
    int? nodeCount,
    PathNode? activeNode,
  }) {
    final payload = <String, Object?>{
      'schemaVersion': 5,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'trigger': trigger,
      'run': <String, Object?>{
        'stageIndex': state.stageIndex,
        'completedNodes': max(0, state.stageIndex),
        'nodeCount': max(1, nodeCount ?? state.visibleNodes.length),
        'isResolvingNode': isResolvingNode,
        'isRunComplete': state.isRunComplete,
        'completionType': state.completionType?.name,
        'randomSeed': randomizer.seed,
        'randomState': randomizer.state,
        'battleEnemyTurnDelayMs': state.battleEnemyTurnDelay.inMilliseconds,
        'battleCombatEndDelayMs': state.battleCombatEndDelay.inMilliseconds,
        'runSummary': state.runSummary.toJson(),
        'currentDaySummary': state.currentDaySummary.toJson(),
        'pendingDaySummary': state.pendingDaySummary?.toJson(),
        'shownShopNodeIds': state.shownShopNodeIds,
        'shopRarityDayOffset': state.shopRarityDayOffset,
        'eventRarityDayOffset': state.eventRarityDayOffset,
        'ghostItemLease': state.ghostItemLease?.toJson(),
        'currentHour': <String, Object?>{
          'stageIndex': state.currentHour.stageIndex,
          'phase': state.currentHour.phase.name,
          'title': state.currentHour.title,
          'subtitle': state.currentHour.subtitle,
        },
        'activeNode': activeNode == null
            ? null
            : EndpointDomainCodec.serializePathNode(activeNode),
        'visibleNodes': state.visibleNodes
            .map<Map<String, Object?>>(EndpointDomainCodec.serializePathNode)
            .toList(growable: false),
        'player': EndpointDomainCodec.serializeBattler(state.player),
      },
    };

    return _jsonEncoder.convert(payload);
  }

  static EndpointCurrentRunSnapshot? decode(String rawValue) {
    final decoded = jsonDecode(rawValue);
    final rootJson = EndpointJsonUtils.asJsonMap(decoded);
    if (rootJson == null) return null;

    final runJson = EndpointJsonUtils.asJsonMap(rootJson['run']);
    if (runJson == null) return null;

    return _deserializeCurrentRunSnapshot(runJson);
  }

  static EndpointCurrentRunSnapshot? _deserializeCurrentRunSnapshot(
    Map<String, dynamic> runJson,
  ) {
    final playerJson = EndpointJsonUtils.asJsonMap(runJson['player']);
    if (playerJson == null) return null;

    final visibleNodes =
        EndpointJsonUtils.readJsonMapList(runJson['visibleNodes'])
            .map<PathNode?>(EndpointDomainCodec.deserializePathNode)
            .whereType<PathNode>()
            .toList(growable: false);
    final isRunComplete = EndpointJsonUtils.readBool(
      runJson['isRunComplete'],
      fallback: false,
    );
    final pendingDaySummary = RunDaySummary.fromJson(
      runJson['pendingDaySummary'],
    );
    if (visibleNodes.isEmpty && !isRunComplete && pendingDaySummary == null) {
      return null;
    }

    final stageIndex = EndpointJsonUtils.readInt(
      runJson['stageIndex'],
      fallback: PathNodeService.startStageIndex,
    );
    final currentHourJson = EndpointJsonUtils.asJsonMap(runJson['currentHour']);
    final currentHour = currentHourJson == null
        ? RunHourSnapshot(
            stageIndex: stageIndex,
            phase: _parseRunHourPhase(
              null,
              fallback: RunHourPhase.day,
            ),
            title: 'HORA ${stageIndex + 1}',
            subtitle: '',
            nodes: visibleNodes,
          )
        : RunHourSnapshot(
            stageIndex: EndpointJsonUtils.readInt(
              currentHourJson['stageIndex'],
              fallback: stageIndex,
            ),
            phase: _parseRunHourPhase(
              currentHourJson['phase'],
              fallback: RunHourPhase.day,
            ),
            title: EndpointJsonUtils.readString(
              currentHourJson['title'],
              fallback: 'HORA ${stageIndex + 1}',
            ),
            subtitle: EndpointJsonUtils.readString(
              currentHourJson['subtitle'],
              fallback: '',
            ),
            nodes: visibleNodes,
          );

    final activeNode = EndpointDomainCodec.deserializePathNode(
      EndpointJsonUtils.asJsonMap(runJson['activeNode']),
    );
    final isResolvingNode = EndpointJsonUtils.readBool(
      runJson['isResolvingNode'],
      fallback: false,
    );

    return EndpointCurrentRunSnapshot(
      player: EndpointDomainCodec.deserializeBattler(playerJson),
      currentHour: currentHour,
      visibleNodes: visibleNodes,
      stageIndex: stageIndex,
      isResolvingNode: isResolvingNode && activeNode != null,
      isRunComplete: isRunComplete,
      completionType: _parseRunCompletionType(runJson['completionType']),
      savedNodeCount: EndpointJsonUtils.readInt(
        runJson['nodeCount'],
        fallback: visibleNodes.length,
      ),
      randomSeed: EndpointJsonUtils.readInt(
        runJson['randomSeed'],
        fallback: RunRandomizer().seed,
      ),
      randomState: EndpointJsonUtils.readInt(
        runJson['randomState'],
        fallback: EndpointJsonUtils.readInt(
          runJson['randomSeed'],
          fallback: RunRandomizer().seed,
        ),
      ),
      battleEnemyTurnDelay: Duration(
        milliseconds: EndpointJsonUtils.readInt(
          runJson['battleEnemyTurnDelayMs'],
          fallback: 900,
        ),
      ),
      battleCombatEndDelay: Duration(
        milliseconds: EndpointJsonUtils.readInt(
          runJson['battleCombatEndDelayMs'],
          fallback: 2000,
        ),
      ),
      runSummary: RunDaySummary.fromJson(runJson['runSummary']) ??
          RunDaySummary.fromJson(runJson['currentDaySummary']) ??
          const RunDaySummary.empty(),
      currentDaySummary: RunDaySummary.fromJson(
            runJson['currentDaySummary'],
          ) ??
          RunDaySummary.empty(
            dayNumber: PathNodeService.dayNumberForStageIndex(stageIndex),
          ),
      pendingDaySummary: pendingDaySummary,
      shownShopNodeIds: _readStringList(runJson['shownShopNodeIds']),
      shopRarityDayOffset: EndpointJsonUtils.readInt(
        runJson['shopRarityDayOffset'],
        fallback: 0,
      ),
      eventRarityDayOffset: EndpointJsonUtils.readInt(
        runJson['eventRarityDayOffset'],
        fallback: 0,
      ),
      ghostItemLease: GhostItemLease.fromJson(runJson['ghostItemLease']),
      activeNode: activeNode,
    );
  }
}

List<String> _readStringList(Object? rawValue) {
  if (rawValue is! List) return const <String>[];

  return List<String>.unmodifiable(
    rawValue.whereType<String>(),
  );
}

RunHourPhase _parseRunHourPhase(
  Object? rawValue, {
  required RunHourPhase fallback,
}) {
  return EndpointJsonUtils.parseEnumByName(RunHourPhase.values, rawValue) ??
      fallback;
}

RunCompletionType? _parseRunCompletionType(Object? rawValue) {
  return EndpointJsonUtils.parseEnumByName(
    RunCompletionType.values,
    rawValue,
  );
}
