import "_imports.dart";

class MapGenerator {
  // ---------- GENERATORS THAT MODIFY EXISTING types ----------

  /// Region-based chunk generator.
  /// Grows irregular blobs of [chunkType] with at least [minChunkSize] tiles.
  ///
  /// - Works only over [baseType] tiles.
  /// - Tries up to [attempts] starting points.
  /// - Each blob size is between [minChunkSize] and [maxChunkSize] (inclusive),
  ///   but only painted if it reaches at least [minChunkSize].
  static void addTypeRegionChunks(
    List<TileType> types,
    int width,
    int height,
    Random random, {
    TileType chunkType = TileType.wall,
    TileType baseType = TileType.path,
    int minChunkSize = 4,
    int maxChunkSize = 8,
    int attempts = 30,
  }) {
    if (minChunkSize < 1) minChunkSize = 1;
    if (maxChunkSize < minChunkSize) maxChunkSize = minChunkSize;

    final totalTiles = width * height;

    for (int attempt = 0; attempt < attempts; attempt++) {
      // 1) pick seed
      int startIndex = -1;

      for (int i = 0; i < 50; i++) {
        final candidate = random.nextInt(totalTiles);
        if (types[candidate] != baseType) continue;

        final startX = candidate % width;
        final startY = candidate ~/ width;

        // don't start next to existing chunkType
        if (MapGeneratorHelpers.hasAdjacentChunkOfType(startX, startY, width, height, types, chunkType)) {
          continue;
        }

        startIndex = candidate;
        break;
      }

      if (startIndex == -1) {
        // no valid seed found this attempt
        continue;
      }

      final startX = startIndex % width;
      final startY = startIndex ~/ width;

      // 2) grow region
      final targetSize = minChunkSize +
          (maxChunkSize > minChunkSize
              ? random.nextInt(maxChunkSize - minChunkSize + 1)
              : 0);

      final region = <int>{startIndex};
      final regionCells = <Point<int>>[Point(startX, startY)];

      // prevent infinite loops on crowded maps
      int stagnation = 0;
      const int maxStagnation = 200;

      while (region.length < targetSize && stagnation < maxStagnation) {
        // pick random existing cell as origin for growth
        final origin = regionCells[random.nextInt(regionCells.length)];
        final originX = origin.x;
        final originY = origin.y;

        const dirs = [
          Point(1, 0),
          Point(-1, 0),
          Point(0, 1),
          Point(0, -1),
        ];

        // choose random direction
        final dir = dirs[random.nextInt(dirs.length)];
        final targetX = originX + dir.x;
        final targetY = originY + dir.y;

        if (targetX < 0 || targetY < 0 || targetX >= width || targetY >= height) {
          stagnation++;
          continue;
        }

        final targetIndex = MapGeneratorHelpers.index(targetX, targetY, width);

        // must be baseType to grow into
        if (types[targetIndex] != baseType) {
          stagnation++;
          continue;
        }

        // don't re-add same cell
        if (region.contains(targetIndex)) {
          stagnation++;
          continue;
        }

        // don't grow next to other already-painted chunks
        if (MapGeneratorHelpers.hasAdjacentChunkOfType(targetX, targetY, width, height, types, chunkType)) {
          stagnation++;
          continue;
        }

        // success: add to region
        region.add(targetIndex);
        regionCells.add(Point(targetX, targetY));
        stagnation = 0; // reset stagnation when we make progress
      }

      // 3) paint only if big enough
      if (region.length >= minChunkSize) {
        for (final idx in region) {
          types[idx] = chunkType;
        }
      }
    }
  }

  /// Carves a single river across the map.
  ///
  /// - [riverType]: the tile type used for the river (default: TileType.river)
  /// - [erodedTypes]: which tile types can be overwritten by the river
  ///   (default: [TileType.path])
  /// - [maxRiverWidth]: maximum vertical/horizontal thickness of the river
  /// - [vertical]: if true, river goes top->bottom; otherwise left->right
  static void addRiver(
    List<TileType> types,
    int width,
    int height,
    Random random, {
    TileType riverType = TileType.river,
    List<TileType>? erodedTypes,
    int maxRiverWidth = 2,
    bool vertical = false,
  }) {
    // Safety
    if (maxRiverWidth < 1) maxRiverWidth = 1;

    final erodable = (erodedTypes ?? const [TileType.path]).toSet();

    if (vertical) {
      _carveVerticalRiver(
        types,
        width,
        height,
        random,
        riverType,
        erodable,
        maxRiverWidth,
      );
    } else {
      _carveHorizontalRiver(
        types,
        width,
        height,
        random,
        riverType,
        erodable,
        maxRiverWidth,
      );
    }
  }

  static void _carveHorizontalRiver(
    List<TileType> types,
    int width,
    int height,
    Random random,
    TileType riverType,
    Set<TileType> erodable,
    int maxRiverWidth,
  ) {
    // Start row
    int y = random.nextInt(height);

    for (int x = 0; x < width; x++) {
      // Random width between 1 and maxRiverWidth
      final currentWidth =
          1 + random.nextInt(maxRiverWidth); // [1, maxRiverWidth]
      final half = currentWidth ~/ 2;

      // Paint river vertically around (x, y)
      for (int yy = y - half; yy <= y + half; yy++) {
        if (yy < 0 || yy >= height) continue;
        final i = MapGeneratorHelpers.index(x, yy, width);
        if (erodable.contains(types[i])) {
          types[i] = riverType;
        }
      }

      // Small random drift up/down to make the river meander only if the river is wider than 1
      if (currentWidth > 1) {
        final roll = random.nextDouble();
        if (roll < 0.33) {
          // go up
          if (y > 0) y--;
        } else if (roll > 0.66) {
          // go down
          if (y < height - 1) y++;
        }
      }
    }
  }

  static void _carveVerticalRiver(
    List<TileType> types,
    int width,
    int height,
    Random random,
    TileType riverType,
    Set<TileType> erodable,
    int maxRiverWidth,
  ) {
    // Start column
    int x = random.nextInt(width);

    for (int y = 0; y < height; y++) {
      final currentWidth =
          1 + random.nextInt(maxRiverWidth); // [1, maxRiverWidth]
      final half = currentWidth ~/ 2;

      // Paint river horizontally around (x, y)
      for (int xx = x - half; xx <= x + half; xx++) {
        if (xx < 0 || xx >= width) continue;
        final i = MapGeneratorHelpers.index(xx, y, width);
        if (erodable.contains(types[i])) {
          types[i] = riverType;
        }
      }

      // Small random drift left/right to make the river meander only if the river is wider than 1
      if (currentWidth > 1) {
        final roll = random.nextDouble();
        if (roll < 0.33) {
          // go left
          if (x > 0) x--;
        } else if (roll > 0.66) {
          // go right
          if (x < width - 1) x++;
        }
      }
    }
  }

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

      if (!MapGeneratorHelpers.canPlaceTypeChunkAtType(x, y, width, height, types,
          chunkTileType: tileType, baseTileType: baseType)) continue;

      MapGeneratorHelpers.placeTypeChunkAt(x, y, width, height, types, tileType: tileType);
    }
  }

  /// Chunks generator.
  /// Modifies existing types, only touching tiles that are currently `path`.
  static void addTypeChunks(
      List<TileType> types, int width, int height, Random random,
      {double baseChunkChance = 0.05,
      double neighborBonus = 0.40,
      double maxChunkChance = 0.8,
      TileType chunkType = TileType.wall,
      TileType baseType = TileType.path}) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = MapGeneratorHelpers.index(x, y, width);

        // If tile is not path, leave it alone (e.g. chasm/river already placed)
        if (types[i] != baseType) continue;

        double chunkChance = baseChunkChance;

        // If neighbors are chunkType, increase the chance → clumps
        if (x > 0 && types[MapGeneratorHelpers.index(x - 1, y, width)] == chunkType) {
          chunkChance += neighborBonus;
        }
        if (y > 0 && types[MapGeneratorHelpers.index(x, y - 1, width)] == chunkType) {
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
        final i = MapGeneratorHelpers.index(x, y, width);
        types[i] = TileType.values[random.nextInt(TileType.values.length)];
      }
    }
  }

}
