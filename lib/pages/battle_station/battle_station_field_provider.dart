import '_imports.dart';

class BattleStationFieldProvider {
  final Map<BattlerSide, List<Battler>> battlers;
  int mapIndex = 0;

  // TODO: hacer biomas específicos que limiten los tipos de tile del mapa a generar
  // final MapBiome mapBiome;

  BattleStationFieldProvider(
    this.battlers,
    // this.mapBiome,
  );

  Widget getBattleField() {
    final tileGrid = getTileGrid();
    final battlerGrid =
        SetBattlersOnStage.getBattlersOnStageTLvsBR(battlers, tileGrid);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int y = 0; y < tileGrid.height; y++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int x = 0; x < tileGrid.width; x++)
                SizedBox(
                    width: 24,
                    height: 24,
                    child: Stack(children: [
                      Image.asset(tileGrid.tileAt(x, y).imagePath),
                      battlerGrid.getBattlerImage(x, y),
                    ])),
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
