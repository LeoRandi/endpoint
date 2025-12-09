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
}
