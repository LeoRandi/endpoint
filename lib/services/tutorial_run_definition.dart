import '../entities/_exports.dart';
import 'path_node_service.dart';

abstract final class TutorialRunDefinition {
  static const int randomSeed = 0;
  static const int nodeCount = 1;

  static final Map<int, List<PathNode>> scriptedNodesByStage =
      Map<int, List<PathNode>>.unmodifiable({
    PathNodeService.startStageIndex: List<PathNode>.unmodifiable([
      imparableArchetypeNode,
    ]),
    1: List<PathNode>.unmodifiable([scrapArsenalNode]),
    2: List<PathNode>.unmodifiable([grayCombatNode]),
    3: List<PathNode>.unmodifiable([emberFoundryNode]),
    4: List<PathNode>.unmodifiable([restZoneCampNode]),
    5: List<PathNode>.unmodifiable([greenCombatNode]),
    6: List<PathNode>.unmodifiable([venomStitchCombatNode]),
    7: List<PathNode>.unmodifiable([afterHoursArsenalNode]),
    8: List<PathNode>.unmodifiable([blueCombatNode]),
    9: List<PathNode>.unmodifiable([chemicalExchangeNode]),
    10: List<PathNode>.unmodifiable([purpleCombatNode]),
    11: List<PathNode>.unmodifiable([severeMedicationCampNode]),
    PathNodeService.sunriseStageIndex: List<PathNode>.unmodifiable([
      yellowCombatNode,
    ]),
  });
}
