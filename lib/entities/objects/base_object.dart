import '../_imports.dart';

class BaseObject {
  int x;
  int y;
  int z;

  BaseObject(this.x, this.y, this.z);
}

class GridObject {
  int x;
  int y;
  Map<int, BaseObject> objects;

  GridObject(this.x, this.y, this.objects);

  Widget getGridObjectWidget(int width) {
    final tile = getHighestTile();
    return tile != null
        ? Stack(
            children: [
              Image.asset(tile.imagePath),
              if (tile.z < depthTileBase &&
                  objects[depthTileBase] is BattlerObject)
                Image.asset(
                    (objects[depthTileBase] as BattlerObject).battler.imagePath)
            ],
          )
        : SizedBox();
  }

  TileObject? getHighestTile() {
    TileObject? highest;
    int? highestZ;

    for (final obj in this.objects.values) {
      if (obj is! TileObject) continue;

      if (highestZ == null || obj.z > highestZ) {
        highestZ = obj.z;
        highest = obj;
      }
    }

    return highest;
  }
}

extension GridObjectList on List<GridObject> {
  List<BaseObject> getLayer(int depth) {
    if (depthOutOfBounds(depth)) return [];

    final layerList = <BaseObject>[];

    for (final gridObject in this) {
      if (gridObject.objects.containsKey(depth)) {
        layerList.add(gridObject.objects[depth]!);
      }
    }

    return layerList;
  }

  void setLayer(int depth, List<BaseObject> objects) {
    if (objects.length != this.length) return;

    for (int i = 0; i < this.length; i++) {
      final gridObject = this[i];
      if (gridObject.objects.containsKey(depth)) {
        gridObject.objects[depth] = objects[i];
      }
    }
  }
}

const int depthTileChasm = -1; // por si quieres distinguir
const int depthTileGround = 0; // path / river
const int depthTileBase = 1; //battler / wall
const int depthAbove = 2; // capa más alta

extension GridExtensions on Grid {
  GridObject? gridObjectAt(int x, int y, int width) {
    final i = idx(x, y, width);
    if (i < 0 || i >= length) return null;
    return this[i];
  }

  /// Devuelve la TileObject en la mayor profundidad z de esa casilla,
  /// ignorando objetos que no sean TileObject.
  TileObject? getHighestTile(int x, int y, int width) {
    final go = gridObjectAt(x, y, width);
    if (go == null) return null;

    TileObject? highest;
    int? highestZ;

    for (final obj in go.objects.values) {
      if (obj is! TileObject) continue;

      if (highestZ == null || obj.z > highestZ) {
        highestZ = obj.z;
        highest = obj;
      }
    }

    return highest;
  }

  int? getHighestTileDepth(int x, int y, int width) {
    final go = gridObjectAt(x, y, width);
    if (go == null) return null;

    int? highestZ;
    for (final obj in go.objects.values) {
      if (obj is! TileObject) continue;

      if (highestZ == null || obj.z > highestZ) {
        highestZ = obj.z;
      }
    }

    return highestZ;
  }

  TileObject? tileAt(int x, int y, int width) {
    final go = gridObjectAt(x, y, width);
    if (go == null) return null;

    // Buscamos un TileObject en cualquiera de las capas
    for (final obj in go.objects.values) {
      if (obj is TileObject) return obj;
    }
    return null;
  }

  bool isWalkableAt(int x, int y, int width) {
    final tile = tileAt(x, y, width);
    return tile?.isWalkable ?? false;
  }

  bool hasBattlerAt(int x, int y, int width) {
    final go = gridObjectAt(x, y, width);
    if (go == null) return false;

    final bo = go.objects[depthTileBase];
    return bo is BattlerObject;
  }

  BattlerObject? battlerObjectAt(int x, int y, int width) {
    final go = gridObjectAt(x, y, width);
    if (go == null) return null;
    final bo = go.objects[depthTileBase];
    return bo is BattlerObject ? bo : null;
  }
}
