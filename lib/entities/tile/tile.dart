enum TileType {
  path,
  wall,
  river,
  chasm,
}

class Tile {
  final double rowPosition;
  final double columnPosition;
  final String imagePath;
  final TileType tileType;
  bool get isWalkable {
    switch (tileType) {
      case TileType.path:
      case TileType.river:
        return true;
      case TileType.wall:
      case TileType.chasm:
        return false;
    }
  }

  bool get isJumpable {
    switch (tileType) {
      case TileType.chasm:
        return true;
      default:
        return false;
    }
  }

  Tile(this.rowPosition, this.columnPosition, this.imagePath, this.tileType);

  Tile.wall(double rowPosition, double columnPosition)
      : this(rowPosition, columnPosition, "assets/images/tiles/wall_tile.png",
            TileType.wall);
  Tile.path(double rowPosition, double columnPosition)
      : this(rowPosition, columnPosition, "assets/images/tiles/path_tile.png",
            TileType.path);
  Tile.river(double rowPosition, double columnPosition)
      : this(rowPosition, columnPosition, "assets/images/tiles/river_tile.png",
            TileType.river);
  Tile.chasm(double rowPosition, double columnPosition)
      : this(rowPosition, columnPosition, "assets/images/tiles/chasm_tile.png",
            TileType.chasm);

  static Tile fromType(TileType type, int x, int y) {
    switch (type) {
      case TileType.path:
        return Tile.path(y.toDouble(), x.toDouble());
      case TileType.wall:
        return Tile.wall(y.toDouble(), x.toDouble());
      case TileType.river:
        return Tile.river(y.toDouble(), x.toDouble());
      case TileType.chasm:
        return Tile.chasm(y.toDouble(), x.toDouble());
    }
  }
}
