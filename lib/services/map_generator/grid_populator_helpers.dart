import "_imports.dart";


// ------------------------------------------------------------
//  HELPERS DE GridPopulator
// ------------------------------------------------------------

extension GridPopulatorHelpers on GridPopulator {
  static int index(int x, int y, int width) => y * width + x;

  /// Create a base list of TileType to be used by generators.
  static List<TileType> createBaseTypes(
    int width,
    int height, {
    TileType fill = TileType.path,
  }) {
    return List<TileType>.filled(width * height, fill);
  }

  /// Construye un Grid (List<GridObject?>) a partir de una lista de TileType.
  static Grid buildGridObjects(int width, int height, List<TileType> types) {
    final grid = List<GridObject?>.filled(width * height, null);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = index(x, y, width);
        final type = types[i];

        final tile = TileObject.fromType(type, x, y);

        grid[i] = GridObject(
          x,
          y,
          {tile.z: tile},
        );
      }
    }

    return grid;
  }

  /// Devuelve true si alrededor de (x,y) hay algún tile del tipo [chunkType]
  /// en el anillo de radio 1 (8 direcciones).
  static bool hasAdjacentChunkOfType(
    int x,
    int y,
    int width,
    int height,
    List<TileType> types,
    TileType chunkType,
  ) {
    for (int yy = y - 1; yy <= y + 1; yy++) {
      for (int xx = x - 1; xx <= x + 1; xx++) {
        if (xx < 0 || yy < 0 || xx >= width || yy >= height) continue;
        if (xx == x && yy == y) continue;

        final i = index(xx, yy, width);
        if (types[i] == chunkType) return true;
      }
    }
    return false;
  }

  /// Check if we can place a 2x2 wall chunk at (x,y) without touching another chunk.
  static bool canPlaceTypeChunkAtType(
      int x, int y, int width, int height, List<TileType> types,
      {required TileType chunkTileType, required TileType baseTileType}) {
    // 1) 2x2 area must be all baseType
    for (int yy = y; yy <= y + 1; yy++) {
      for (int xx = x; xx <= x + 1; xx++) {
        if (types[index(xx, yy, width)] != baseTileType) return false;
      }
    }

    // 2) No chunks in the 1-tile ring around the 2x2 area
    for (int yy = y - 1; yy <= y + 2; yy++) {
      for (int xx = x - 1; xx <= x + 2; xx++) {
        if (xx < 0 || yy < 0 || xx >= width || yy >= height) continue;

        final insideChunk =
            (xx >= x && xx <= x + 1 && yy >= y && yy <= y + 1);
        if (insideChunk) continue;

        if (types[index(xx, yy, width)] == chunkTileType) {
          return false;
        }
      }
    }

    return true;
  }

  /// Actually place the 2x2 chunk.
  static void placeTypeChunkAt(
      int x, int y, int width, int height, List<TileType> types,
      {required TileType tileType}) {
    for (int yy = y; yy <= y + 1; yy++) {
      for (int xx = x; xx <= x + 1; xx++) {
        types[index(xx, yy, width)] = tileType;
      }
    }
  }
}