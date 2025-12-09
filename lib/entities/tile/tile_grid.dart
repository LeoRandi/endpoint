import "_imports.dart";

class TileGrid {
  final int width;
  final int height;
  final List<Tile> tiles; // length == width * height

  TileGrid(this.width, this.height, this.tiles);

  Tile tileAt(int x, int y) => tiles[y * width + x];

  void setTile(int x, int y, Tile tile) {
    tiles[y * width + x] = tile;
  }

  static TileGrid buildFromTypes(
    int width,
    int height,
    List<TileType> types,
  ) {
    final tiles = <Tile>[];

    int index(int x, int y) => y * width + x;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        tiles.add(Tile.fromType(types[index(x, y)], x, y));
      }
    }

    return TileGrid(width, height, tiles);
  }
}
