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
    final grid = getGrid();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int y = 0; y < grid.height; y++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int x = 0; x < grid.width; x++)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Image.asset(grid.tileAt(x, y).imagePath),
                ),
            ],
          ),
      ],
    );
  }

  TileGrid getGrid() {
    switch (mapIndex) {
      case 0:
        return MapGenerator.generateEmpty(16, 16);
      case 1:
        return MapGenerator.generateRandomMap(16, 16);
      case 2:
        return MapGenerator.generateSquareWallsMap(16, 16);
      case 3:
        return MapGenerator.generateSquareWallsMapWithChasms(16, 16);
      case 4:
        return MapGenerator.generateChasmFilledWithPathSquares(16, 16);
      default:
        return MapGenerator.generateEmpty(16, 16);
    }
  }
}
