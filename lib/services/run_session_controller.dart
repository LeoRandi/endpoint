import '_imports.dart';

class RunSessionController extends ChangeNotifier {
  final PathNodeService _pathNodeService;
  RunState _state;
  bool _isResolvingNode = false;

  RunSessionController({
    required Battler player,
    required List<PathNode> availableNodes,
    required int nodeCount,
    required Duration battleEnemyTurnDelay,
    required Duration battleCombatEndDelay,
    int? randomSeed,
  })  : _pathNodeService = PathNodeService(seed: randomSeed),
        _state = RunState(
          player: player,
          availableNodes: List<PathNode>.unmodifiable(
            availableNodes.isEmpty ? defaultPathNodePool : availableNodes,
          ),
          visibleNodes: const [],
          nodeCount: nodeCount,
          battleEnemyTurnDelay: battleEnemyTurnDelay,
          battleCombatEndDelay: battleCombatEndDelay,
        ) {
    refreshNodes();
  }

  RunState get state => _state;
  Battler get player => _state.player;
  List<PathNode> get nodes => _state.visibleNodes;
  bool get isResolvingNode => _isResolvingNode;

  bool beginNodeResolution() {
    if (_isResolvingNode) return false;
    _isResolvingNode = true;
    notifyListeners();
    return true;
  }

  void cancelNodeResolution() {
    if (!_isResolvingNode) return;
    _isResolvingNode = false;
    notifyListeners();
  }

  void refreshNodes() {
    final visibleNodes = _pathNodeService.rollNodes(
      availableNodes: _state.availableNodes,
      nodeCount: _state.nodeCount,
    );

    _state = _state.copyWith(
      visibleNodes: List<PathNode>.unmodifiable(visibleNodes),
    );
    notifyListeners();
  }

  void completeEncounter(BattleFlowResult result) {
    _completeScene(updatedPlayer: result.player);
  }

  void completeCampVisit(CampSiteVisitResult result) {
    _completeScene(updatedPlayer: result.player);
  }

  void completeWeaponShopVisit(WeaponShopVisitResult result) {
    _completeScene(updatedPlayer: result.player);
  }

  void _completeScene({
    required Battler updatedPlayer,
  }) {
    _state = _state.copyWith(player: updatedPlayer);
    _isResolvingNode = false;
    refreshNodes();
  }
}
