import '_imports.dart';

enum MapCorner { topLeft, topRight, bottomLeft, bottomRight }

class GridPopulator {
  // ---------- RANDOM UTIL ----------
  static final Random _random = Random();

  // ------------------------------------------------------------
  //  SPAWN DE BATTLERS EN EL GRID (USANDO GridObject)
  // ------------------------------------------------------------

  /// Coloca aliados y enemigos automáticamente según densidad de tiles walkable.
  /// Devuelve true si TODOS los battlers han podido colocarse.
  static bool populateBattlersAutoCorners(
    Grid grid,
    int gridSize,
    Map<BattlerSide, List<Battler>> battlers, {
    int offset = 1,
    double areaFactor = 2.0,
  }) {
    final allyCorner = chooseBestStartingCorner(grid, gridSize);
    final enemyCorner = chooseEnemyCorner(grid, gridSize, allyCorner);

    final okAllies = _fillCornerSmartOnGrid(
      grid,
      gridSize,
      battlers.allyBattlers,
      corner: allyCorner,
      offset: offset,
      areaFactor: areaFactor,
    );

    final okEnemies = _fillCornerSmartOnGrid(
      grid,
      gridSize,
      battlers.enemyBattlers,
      corner: enemyCorner,
      offset: offset,
      areaFactor: areaFactor,
    );

    return okAllies && okEnemies;
  }

  /// Variante explícita: aliados TL, enemigos BR.
  static bool populateBattlersTLvsBR(
    Grid grid,
    int gridSize,
    Map<BattlerSide, List<Battler>> battlers, {
    int offset = 1,
    double areaFactor = 2.0,
  }) {
    final okAllies = _fillCornerSmartOnGrid(
      grid,
      gridSize,
      battlers.allyBattlers,
      corner: MapCorner.topLeft,
      offset: offset,
      areaFactor: areaFactor,
    );

    final okEnemies = _fillCornerSmartOnGrid(
      grid,
      gridSize,
      battlers.enemyBattlers,
      corner: MapCorner.bottomRight,
      offset: offset,
      areaFactor: areaFactor,
    );

    return okAllies && okEnemies;
  }

  /// Variante explícita: aliados BL, enemigos TR.
  static bool populateBattlersBLvsTR(
    Grid grid,
    int gridSize,
    Map<BattlerSide, List<Battler>> battlers, {
    int offset = 1,
    double areaFactor = 2.0,
  }) {
    final okAllies = _fillCornerSmartOnGrid(
      grid,
      gridSize,
      battlers.allyBattlers,
      corner: MapCorner.bottomLeft,
      offset: offset,
      areaFactor: areaFactor,
    );

    final okEnemies = _fillCornerSmartOnGrid(
      grid,
      gridSize,
      battlers.enemyBattlers,
      corner: MapCorner.topRight,
      offset: offset,
      areaFactor: areaFactor,
    );

    return okAllies && okEnemies;
  }

  /// Coloca battlers cerca del [corner], priorizando:
  /// 1) tiles PATH antes que RIVER
  /// 2) tiles dentro de la región "square-ish" antes que fuera
  /// 3) tiles más cercanos al centro de la región
  ///
  /// Devuelve false si algún battler no ha podido colocarse.
  static bool _fillCornerSmartOnGrid(
    Grid grid,
    int gridSize,
    List<Battler> battlersList, {
    required MapCorner corner,
    int offset = 1,
    double areaFactor = 2.0,
  }) {
    if (battlersList.isEmpty) return true;

    final battlerCount = battlersList.length;
    final desiredCells = max(1, (battlerCount * areaFactor).ceil());
    final side = max(1, sqrt(desiredCells).ceil());

    // 1) Área target para ese corner
    final rect = _cornerRect(gridSize, corner, side, offset);

    // Centro de la región (para calcular distancias)
    final cx = (rect.left + rect.right - 1) / 2.0;
    final cy = (rect.top + rect.bottom - 1) / 2.0;

    // 2) Candidatos separados por región / global y PATH / RIVER
    final regionPath = <Point<int>>[];
    final regionRiver = <Point<int>>[];
    final globalPath = <Point<int>>[];
    final globalRiver = <Point<int>>[];

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final tile = grid.tileAt(x, y, gridSize);
        if (tile == null || !tile.isWalkable) continue;

        // ya hay battler aquí?
        if (grid.hasBattlerAt(x, y, gridSize)) continue;

        final p = Point(x, y);
        final inRegion = x >= rect.left &&
            x < rect.right &&
            y >= rect.top &&
            y < rect.bottom;

        final tileType = tile.tileType;

        if (tileType == TileType.path) {
          globalPath.add(p);
          if (inRegion) regionPath.add(p);
        } else if (tileType == TileType.river) {
          globalRiver.add(p);
          if (inRegion) regionRiver.add(p);
        }
      }
    }

    if (regionPath.isEmpty &&
        regionRiver.isEmpty &&
        globalPath.isEmpty &&
        globalRiver.isEmpty) {
      // No hay ni un solo tile walkable libre
      return false;
    }

    void sortByDistance(List<Point<int>> list) {
      list.shuffle(_random);
      list.sort((a, b) {
        final da = (a.x - cx) * (a.x - cx) + (a.y - cy) * (a.y - cy);
        final db = (b.x - cx) * (b.x - cx) + (b.y - cy) * (b.y - cy);
        return da.compareTo(db);
      });
    }

    // 3) Ordenamos todos por distancia al centro
    sortByDistance(regionPath);
    sortByDistance(regionRiver);
    sortByDistance(globalPath);
    sortByDistance(globalRiver);

    bool placeFromList(Battler battler, List<Point<int>> list) {
      for (final p in list) {
        if (grid.hasBattlerAt(p.x, p.y, gridSize)) continue;

        final tile = grid.tileAt(p.x, p.y, gridSize);
        if (tile == null || !tile.isWalkable) continue;

        final go = grid.gridObjectAt(p.x, p.y, gridSize);
        if (go == null) continue;

        final newBattler = BattlerObject(
          p.x,
          p.y,
          depthTileBase,
          global.battlerObjectManager.nextId(),
          battler,
        );

        global.battlerObjectManager.models.add(newBattler);

        go.objects[depthTileBase] = newBattler;

        return true;
      }
      return false;
    }

    // 4) Intentamos colocar cada battler con la prioridad:
    //   region PATH → region RIVER → global PATH → global RIVER
    for (final battler in battlersList) {
      if (placeFromList(battler, regionPath)) continue;
      if (placeFromList(battler, regionRiver)) continue;
      if (placeFromList(battler, globalPath)) continue;
      if (placeFromList(battler, globalRiver)) continue;

      // No hay hueco válido para este battler
      return false;
    }

    return true;
  }

  // ------------------------------------------------------------
  //  CORNER-CHOOSING LOGIC (SOBRE GridObject)
  // ------------------------------------------------------------

  static MapCorner chooseBestStartingCorner(Grid grid, int gridSize) {
    final counts = _walkablesPerCorner(grid, gridSize);

    if (counts.values.every((c) => c == 0)) {
      return MapCorner.topLeft;
    }

    MapCorner best = MapCorner.topLeft;
    int bestCount = counts[best]!;

    counts.forEach((corner, count) {
      if (count > bestCount) {
        best = corner;
        bestCount = count;
      }
    });

    return best;
  }

  static MapCorner chooseEnemyCorner(
      Grid grid, int gridSize, MapCorner allyCorner) {
    final counts = _walkablesPerCorner(grid, gridSize);

    if (counts.values.every((c) => c == 0)) {
      return allyCorner;
    }

    final allyPos = _cornerCoord(allyCorner);

    MapCorner? best;
    int bestDist2 = -1;
    int bestCount = -1;

    for (final corner in MapCorner.values) {
      if (corner == allyCorner) continue;

      final count = counts[corner] ?? 0;
      if (count == 0) continue;

      final pos = _cornerCoord(corner);
      final dx = pos.x - allyPos.x;
      final dy = pos.y - allyPos.y;
      final dist2 = dx * dx + dy * dy;

      if (dist2 > bestDist2 || (dist2 == bestDist2 && count > bestCount)) {
        best = corner;
        bestDist2 = dist2;
        bestCount = count;
      }
    }

    return best ?? allyCorner;
  }

  static Map<MapCorner, int> _walkablesPerCorner(
      Grid grid, int gridSize) {
    final midX = gridSize ~/ 2;
    final midY = gridSize ~/ 2;

    int countWalkables(int x0, int y0, int x1, int y1) {
      int c = 0;
      for (int y = y0; y < y1; y++) {
        for (int x = x0; x < x1; x++) {
          if (grid.isWalkableAt(x, y, gridSize)) c++;
        }
      }
      return c;
    }

    return <MapCorner, int>{
      MapCorner.topLeft: countWalkables(0, 0, midX, midY),
      MapCorner.topRight: countWalkables(midX, 0, gridSize, midY),
      MapCorner.bottomLeft: countWalkables(0, midY, midX, gridSize),
      MapCorner.bottomRight: countWalkables(midX, midY, gridSize, gridSize),
    };
  }

  static Point<int> _cornerCoord(MapCorner c) {
    switch (c) {
      case MapCorner.topLeft:
        return const Point(0, 0);
      case MapCorner.topRight:
        return const Point(1, 0);
      case MapCorner.bottomLeft:
        return const Point(0, 1);
      case MapCorner.bottomRight:
        return const Point(1, 1);
    }
  }

  static _Rect _cornerRect(
    int gridSize,
    MapCorner corner,
    int side,
    int offset,
  ) {
    switch (corner) {
      case MapCorner.topLeft:
        final left = offset;
        final top = offset;
        final right = min(gridSize, left + side);
        final bottom = min(gridSize, top + side);
        return _Rect(left, top, right, bottom);

      case MapCorner.topRight:
        final right = gridSize - offset;
        final left = max(0, right - side);
        final top = offset;
        final bottom = min(gridSize, top + side);
        return _Rect(left, top, right, bottom);

      case MapCorner.bottomLeft:
        final left = offset;
        final bottom = gridSize - offset;
        final top = max(0, bottom - side);
        final right = min(gridSize, left + side);
        return _Rect(left, top, right, bottom);

      case MapCorner.bottomRight:
        final right = gridSize - offset;
        final bottom = gridSize - offset;
        final left = max(0, right - side);
        final top = max(0, bottom - side);
        return _Rect(left, top, right, bottom);
    }
  }

  // ------------------------------------------------------------
  //  GENERADORES DE TILES (TRABAJAN SOBRE List<TileType>)
  // ------------------------------------------------------------

  /// Region-based chunk generator.
  /// Grows irregular blobs of [chunkType] with at least [minChunkSize] tiles.
  ///
  /// - Works only over [baseType] tiles.
  /// - Tries up to [attempts] starting points.
  /// - Each blob size is between [minChunkSize] and [maxChunkSize] (inclusive),
  ///   but only painted if it reaches at least [minChunkSize].
  static void addTypeRegionChunks(
    List<TileType> types,
    int gridSize,
    Random random, {
    TileType chunkType = TileType.wall,
    TileType baseType = TileType.path,
    int minChunkSize = 4,
    int maxChunkSize = 8,
    int attempts = 30,
  }) {
    if (minChunkSize < 1) minChunkSize = 1;
    if (maxChunkSize < minChunkSize) maxChunkSize = minChunkSize;

    final totalTiles = gridSize * gridSize;

    for (int attempt = 0; attempt < attempts; attempt++) {
      // 1) pick seed
      int startIndex = -1;

      for (int i = 0; i < 50; i++) {
        final candidate = random.nextInt(totalTiles);
        if (types[candidate] != baseType) continue;

        final startX = candidate % gridSize;
        final startY = candidate ~/ gridSize;

        // don't start next to existing chunkType
        if (GridPopulatorHelpers.hasAdjacentChunkOfType(
            startX, startY, gridSize, gridSize, types, chunkType)) {
          continue;
        }

        startIndex = candidate;
        break;
      }

      if (startIndex == -1) {
        // no valid seed found this attempt
        continue;
      }

      final startX = startIndex % gridSize;
      final startY = startIndex ~/ gridSize;

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

        if (targetX < 0 ||
            targetY < 0 ||
            targetX >= gridSize ||
            targetY >= gridSize) {
          stagnation++;
          continue;
        }

        final targetIndex = GridPopulatorHelpers.index(targetX, targetY, gridSize);

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
        if (GridPopulatorHelpers.hasAdjacentChunkOfType(
            targetX, targetY, gridSize, gridSize, types, chunkType)) {
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
    int gridSize,
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
        gridSize,
        random,
        riverType,
        erodable,
        maxRiverWidth,
      );
    } else {
      _carveHorizontalRiver(
        types,
        gridSize,
        random,
        riverType,
        erodable,
        maxRiverWidth,
      );
    }
  }

  static void _carveHorizontalRiver(
    List<TileType> types,
    int gridSize,
    Random random,
    TileType riverType,
    Set<TileType> erodable,
    int maxRiverWidth,
  ) {
    // Start row
    int y = random.nextInt(gridSize);

    for (int x = 0; x < gridSize; x++) {
      // Random width between 1 and maxRiverWidth
      final currentWidth =
          1 + random.nextInt(maxRiverWidth); // [1, maxRiverWidth]
      final half = currentWidth ~/ 2;

      // Paint river vertically around (x, y)
      for (int yy = y - half; yy <= y + half; yy++) {
        if (yy < 0 || yy >= gridSize) continue;
        final i = GridPopulatorHelpers.index(x, yy, gridSize);
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
          if (y < gridSize - 1) y++;
        }
      }
    }
  }

  static void _carveVerticalRiver(
    List<TileType> types,
    int gridSize,
    Random random,
    TileType riverType,
    Set<TileType> erodable,
    int maxRiverWidth,
  ) {
    // Start column
    int x = random.nextInt(gridSize);

    for (int y = 0; y < gridSize; y++) {
      final currentWidth =
          1 + random.nextInt(maxRiverWidth); // [1, maxRiverWidth]
      final half = currentWidth ~/ 2;

      // Paint river horizontally around (x, y)
      for (int xx = x - half; xx <= x + half; xx++) {
        if (xx < 0 || xx >= gridSize) continue;
        final i = GridPopulatorHelpers.index(xx, y, gridSize);
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
          if (x < gridSize - 1) x++;
        }
      }
    }
  }

  /// Add 2x2 wall chunks on top of paths.
  /// Only uses cells that are currently `TileType.path`.
  static void addTypeSquares(
    List<TileType> types,
    int gridSize,
    Random random, {
    double chunkProbability = 0.25, // density of chunks
    TileType tileType = TileType.wall,
    TileType baseType = TileType.path,
  }) {
    // All possible top-left coords for 2x2 chunks
    final candidates = <Point<int>>[];
    for (int y = 0; y < gridSize - 1; y++) {
      for (int x = 0; x < gridSize - 1; x++) {
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

      if (!GridPopulatorHelpers.canPlaceTypeChunkAtType(
          x, y, gridSize, types,
          chunkTileType: tileType, baseTileType: baseType)) continue;

      GridPopulatorHelpers.placeTypeChunkAt(x, y, gridSize, types,
          tileType: tileType);
    }
  }

  /// Chunks generator.
  /// Modifies existing types, only touching tiles that are currently `path`.
  static void addTypeChunks(
      List<TileType> types, int gridSize, Random random,
      {double baseChunkChance = 0.05,
      double neighborBonus = 0.40,
      double maxChunkChance = 0.8,
      TileType chunkType = TileType.wall,
      TileType baseType = TileType.path}) {
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final i = GridPopulatorHelpers.index(x, y, gridSize);

        // If tile is not path, leave it alone (e.g. chasm/river already placed)
        if (types[i] != baseType) continue;

        double chunkChance = baseChunkChance;

        // If neighbors are chunkType, increase the chance → clumps
        if (x > 0 &&
            types[GridPopulatorHelpers.index(x - 1, y, gridSize)] == chunkType) {
          chunkChance += neighborBonus;
        }
        if (y > 0 &&
            types[GridPopulatorHelpers.index(x, y - 1, gridSize)] == chunkType) {
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
    int gridSize,
    Random random,
  ) {
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final i = GridPopulatorHelpers.index(x, y, gridSize);
        types[i] = TileType.values[random.nextInt(TileType.values.length)];
      }
    }
  }
}

// Small rect struct
class _Rect {
  final int left;
  final int top;
  final int right; // exclusive
  final int bottom; // exclusive
  const _Rect(this.left, this.top, this.right, this.bottom);
}
