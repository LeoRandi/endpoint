import "_imports.dart";

class MapGenerator {
  static TileGrid generateMap(int width, int height) {
    final random = Random();
    final tiles = <Tile>[];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final tileType = TileType.values[random.nextInt(TileType.values.length)];
        switch (tileType) {
          case TileType.path:
            tiles.add(Tile.path(y.toDouble(), x.toDouble()));
            break;
          case TileType.wall:
            tiles.add(Tile.wall(y.toDouble(), x.toDouble()));
            break;
          case TileType.river:
            tiles.add(Tile.river(y.toDouble(), x.toDouble()));
            break;
          case TileType.chasm:
            tiles.add(Tile.chasm(y.toDouble(), x.toDouble()));
            break;
        }
      }
    }

    return TileGrid(width, height, tiles);
  }
}
