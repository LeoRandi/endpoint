import "_imports.dart";

class MapGenerator {
  // ---------- builders ----------

  // GENERATE EMPTY
  static TileGrid generateEmpty(int height, int width) {
    final types =
        MapGenerator.createBaseTypes(width, height, fill: TileType.path);
    return MapGenerator.buildGrid(width, height, types);
  }

  // GENERATE RANDOM
  static TileGrid generateRandomMap(int height, int width) {
    final random = Random();
    final types =
        MapGenerator.createBaseTypes(width, height, fill: TileType.path);

    MapGenerator.fillCompletelyRandom(types, width, height, random);

    return MapGenerator.buildGrid(width, height, types);
  }

  // GENERATE SQUARE WALLS
  static TileGrid generateSquareWallsMap(int height, int width) {
    final random = Random();
    final types =
        MapGenerator.createBaseTypes(width, height, fill: TileType.path);

    MapGenerator.addTypeSquares(types, width, height, random);

    return MapGenerator.buildGrid(width, height, types);
  }

  // GENERATE SQUARE WALLS WITH CHASMS
  static TileGrid generateSquareWallsMapWithChasms(int height, int width) {
    final random = Random();
    final types =
        MapGenerator.createBaseTypes(width, height, fill: TileType.path);

    MapGenerator.addTypeChunks(types, width, height, random,
        chunkType: TileType.chasm);

    MapGenerator.addTypeSquares(types, width, height, random);

    return MapGenerator.buildGrid(width, height, types);
  }

  // GENERATE CHASM FILLED WITH PATH CHUNKS
  static TileGrid generateChasmFilledWithPathChunks(int height, int width) {
    final random = Random();
    final types =
        MapGenerator.createBaseTypes(width, height, fill: TileType.chasm);

    MapGenerator.addTypeChunks(types, width, height, random,
        chunkType: TileType.path, baseType: TileType.chasm);

    return MapGenerator.buildGrid(width, height, types);
  }

  // GENERATE CHASM FILLED WITH PATH SQUARES
  static TileGrid generateChasmFilledWithPathSquares(int height, int width) {
    final random = Random();
    final types =
        MapGenerator.createBaseTypes(width, height, fill: TileType.chasm);

    MapGenerator.addTypeSquares(types, width, height, random,
        tileType: TileType.path, baseType: TileType.chasm);

    return MapGenerator.buildGrid(width, height, types);
  }

  // ---------- helpers ----------

  static int _index(int x, int y, int width) => y * width + x;

  /// Create a base list of TileType to be used by generators.
  static List<TileType> createBaseTypes(
    int width,
    int height, {
    TileType fill = TileType.path,
  }) {
    return List<TileType>.filled(width * height, fill);
  }

  /// Final step: build the TileGrid from types.
  static TileGrid buildGrid(int width, int height, List<TileType> types) {
    return TileGrid.buildFromTypes(width, height, types);
  }

  // ---------- GENERATORS THAT MODIFY EXISTING types ----------

  /// Add 2x2 wall chunks on top of paths.
  /// Only uses cells that are currently `TileType.path`.
  static void addTypeSquares(
    List<TileType> types,
    int width,
    int height,
    Random random, {
    double chunkProbability = 0.25, // density of chunks
    TileType tileType = TileType.wall,
    TileType baseType = TileType.path,
  }) {
    // All possible top-left coords for 2x2 chunks
    final candidates = <Point<int>>[];
    for (int y = 0; y < height - 1; y++) {
      for (int x = 0; x < width - 1; x++) {
        candidates.add(Point(x, y));
      }
    }

    // Shuffle so placement is random
    candidates.shuffle(random);

    for (final p in candidates) {
      final x = p.x;
      final y = p.y;

      // Chance to even try a chunk here
      if (random.nextDouble() > chunkProbability) continue;

      if (!_canPlaceTypeChunkAtType(x, y, width, height, types,
          chunkTileType: tileType, baseTileType: baseType)) continue;

      _placeTypeChunkAt(x, y, width, height, types, tileType: tileType);
    }
  }

  /// Chunks generator.
  /// Modifies existing types, only touching tiles that are currently `path`.
  static void addTypeChunks(
      List<TileType> types, int width, int height, Random random,
      {double baseChunkChance = 0.05,
      double neighborBonus = 0.30,
      double maxChunkChance = 0.8,
      TileType chunkType = TileType.wall,
      TileType baseType = TileType.path}) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = _index(x, y, width);

        // If tile is not path, leave it alone (e.g. chasm/river already placed)
        if (types[i] != baseType) continue;

        double chunkChance = baseChunkChance;

        // If neighbors are walls, increase the chance → clumps
        if (x > 0 && types[_index(x - 1, y, width)] == chunkType) {
          chunkChance += neighborBonus;
        }
        if (y > 0 && types[_index(x, y - 1, width)] == chunkType) {
          chunkChance += neighborBonus;
        }

        if (chunkChance > maxChunkChance) chunkChance = maxChunkChance;

        final isWall = random.nextDouble() < chunkChance;
        if (isWall) {
          types[i] = chunkType;
        }
      }
    }
  }

  /// Completely random map (for all tile types).
  static void fillCompletelyRandom(
    List<TileType> types,
    int width,
    int height,
    Random random,
  ) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = _index(x, y, width);
        types[i] = TileType.values[random.nextInt(TileType.values.length)];
      }
    }
  }

  // ---------- PRIVATE HELPERS FOR 2x2 WALL SQUARES ----------

  /// Check if we can place a 2x2 wall chunk at (x,y) without touching another chunk.
  static bool _canPlaceTypeChunkAtType(
      int x, int y, int width, int height, List<TileType> types,
      {required TileType chunkTileType, required TileType baseTileType}) {
    // 1) 2x2 area must be all paths
    for (int yy = y; yy <= y + 1; yy++) {
      for (int xx = x; xx <= x + 1; xx++) {
        if (types[_index(xx, yy, width)] != baseTileType) return false;
      }
    }

    // 2) No walls in the 1-tile ring around the 2x2 area
    for (int yy = y - 1; yy <= y + 2; yy++) {
      for (int xx = x - 1; xx <= x + 2; xx++) {
        if (xx < 0 || yy < 0 || xx >= width || yy >= height) continue;

        final insideChunk = (xx >= x && xx <= x + 1 && yy >= y && yy <= y + 1);
        if (insideChunk) continue;

        if (types[_index(xx, yy, width)] == chunkTileType) {
          return false;
        }
      }
    }

    return true;
  }

  /// Actually place the 2x2 wall chunk.
  static void _placeTypeChunkAt(
      int x, int y, int width, int height, List<TileType> types,
      {required TileType tileType}) {
    for (int yy = y; yy <= y + 1; yy++) {
      for (int xx = x; xx <= x + 1; xx++) {
        types[_index(xx, yy, width)] = tileType;
      }
    }
  }
}
