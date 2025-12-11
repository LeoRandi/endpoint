import "_imports.dart";

class GlobalState {
  final _viewSelectedBattlerController = StreamController<Battler?>.broadcast();
  final ManagerList<BaseObject> baseObjectManager = ManagerList<BaseObject>([]);

  Stream<Battler?> get viewSelectedBattlerStream =>
      _viewSelectedBattlerController.stream;

  void setViewSelectedBattler(Battler? battler) {
    _viewSelectedBattlerController.add(battler);
  }
}

final global = GlobalState();

typedef Grid = List<GridObject?>;

