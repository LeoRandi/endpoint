import '_imports.dart';

class BattleStationFieldProvider {
  final Map<BattlerSide, List<Battler>> battlers;
  int mapIndex = 0;

  // selected battler state
  final ValueNotifier<Battler?> selectedBattlerNotifier;
  
  // selected battler state
  final ValueNotifier<Battler?> playingBattlerNotifier;

  BattleStationFieldProvider(this.battlers)
      : selectedBattlerNotifier = ValueNotifier<Battler?>(
          null, //initial value
        ),
        playingBattlerNotifier = ValueNotifier<Battler?>(
          null, //initial value
        );

  void setSelectedBattler(Battler? battler) {
    selectedBattlerNotifier.value = battler;
  }

  void setPlayingBattler(Battler? battler) {
    playingBattlerNotifier.value = battler;
  }  

  Widget getBattleField() {
    final tileGrid = getTileGrid();
    final battlerGrid =
        SetBattlersOnStage.getBattlersOnStageCalc(battlers, tileGrid);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int y = 0; y < tileGrid.height; y++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int x = 0; x < tileGrid.width; x++)
                BattleStationCell(
                  tile: tileGrid.tileAt(x, y),
                  battler: battlerGrid.battlerAt(x, y),
                  size: 24,
                  onTap: () {
                    final b = battlerGrid.battlerAt(x, y);
                    if (b.name.isNotEmpty) {
                      setSelectedBattler(b); 
                    }
                  },
                ),
            ],
          ),
      ],
    );
  }

  TileGrid getTileGrid() {
    switch (mapIndex) {
      case 0:
        return MapGeneratorBuilders.generateEmpty(12, 12);
      case 1:
        return MapGeneratorBuilders.generateRandomMap(12, 12);
      case 2:
        return MapGeneratorBuilders.generatePathMapWithHorizontalRiver(12, 12);
      case 3:
        return MapGeneratorBuilders.generatePathMapWithVRiverAndChasmSquares(
            12, 12);
      case 4:
        return MapGeneratorBuilders.generateChasmWithBigPathChunks(12, 12);
      default:
        return MapGeneratorBuilders.generateEmpty(12, 12);
    }
  }
}
