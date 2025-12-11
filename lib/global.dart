import "_imports.dart";

class GlobalState {
  final _viewSelectedBattlerController = StreamController<Battler?>.broadcast();

  Stream<Battler?> get viewSelectedBattlerStream =>
      _viewSelectedBattlerController.stream;

  void setViewSelectedBattler(Battler? battler) {
    _viewSelectedBattlerController.add(battler);
  }
}

final global = GlobalState();
