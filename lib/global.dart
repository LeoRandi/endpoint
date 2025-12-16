import "_imports.dart";

class GlobalState {
  final _viewSelectedBattlerController = StreamController<Battler?>.broadcast();
  final ManagerList<BattlerObject> battlerObjectManager = ManagerList<BattlerObject>([]);
  final ManagerList<Grid> gridManager = ManagerList<Grid>([]);

  Stream<Battler?> get viewSelectedBattlerStream =>
      _viewSelectedBattlerController.stream;

  void setViewSelectedBattler(Battler? battler) {
    _viewSelectedBattlerController.add(battler);
  }
}

final global = GlobalState();

typedef Grid = List<GridObject?>;

