import 'package:endpoint/entities/objects/base_object.dart';

enum TileType {
  path,
  wall,
  river,
  chasm,
  distance(true),
  enemyDistance(false);

  final bool isAlly;
  const TileType([this.isAlly = false]);
}

class TileObject extends BaseObject {
  final String imagePath;
  final TileType tileType;
  bool get isWalkable {
    switch (tileType) {
      case TileType.wall:
      case TileType.chasm:
        return false;
      case TileType.path:
      case TileType.river:
      case TileType.distance:
      case TileType.enemyDistance:
        return true;
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

  TileObject(int x, int y, int z, this.imagePath, this.tileType)
      : super(x, y, z);

  TileObject.wall(int x, int y, int z)
      : this(x, y, z, "assets/images/tiles/wall_tile.png", TileType.wall);
  TileObject.path(int x, int y, int z)
      : this(x, y, z, "assets/images/tiles/path_tile.png", TileType.path);
  TileObject.river(int x, int y, int z)
      : this(x, y, z, "assets/images/tiles/river_tile.png", TileType.river);
  TileObject.chasm(int x, int y, int z)
      : this(x, y, z, "assets/images/tiles/chasm_tile.png", TileType.chasm);
  TileObject.distance(int x, int y, int z)
      : this(x, y, z, "assets/images/tiles/distance_tile.png",
            TileType.distance);
  TileObject.enemyDistance(int x, int y, int z)
      : this(x, y, z, "assets/images/tiles/enemy_distance_tile.png",
            TileType.enemyDistance);

  static TileObject fromType(TileType type, int x, int y) {
    switch (type) {
      case TileType.path:
        return TileObject.path(y, x, 0);
      case TileType.wall:
        return TileObject.wall(y, x, 1);
      case TileType.river:
        return TileObject.river(y, x, 0);
      case TileType.chasm:
        return TileObject.chasm(y, x, -1);
      case TileType.distance:
        return TileObject.distance(y, x, 2);
      case TileType.enemyDistance:
        return TileObject.enemyDistance(y, x, 2);
    }
  }
}
