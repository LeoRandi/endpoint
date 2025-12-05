import '_imports.dart';

class BattleStationFieldProvider {
  final Map<BattlerSide, List<Battler>> battlers;
  int mana = 100;

  BattleStationFieldProvider(this.battlers);

  void cast(int cost) {
    if (mana >= cost) {
      mana -= cost;
    }
  }

  
}
