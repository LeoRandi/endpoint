import "_imports.dart";

enum MapCorner { topLeft, topRight, bottomLeft, bottomRight }

class SetBattlersOnStage {
  static final Random _random = Random();

  static BattlerGrid getBattlersOnStageCalc(
      Map<BattlerSide, List<Battler>> battlers, TileGrid tileGrid) {
    final battlersEmptyList =
        List<Battler>.filled(tileGrid.width * tileGrid.height, Battler.voidBattler());

    final allyCorner = chooseBestStartingCorner(tileGrid);
    final enemyCorner = chooseEnemyCorner(tileGrid, allyCorner);

    return setBattlersOnStage(
      allyCorner,
      enemyCorner,
      battlersEmptyList,
      battlers.allyBattlers,
      battlers.enemyBattlers,
      tileGrid,
    );
  }

  static BattlerGrid getBattlersOnStageTLvsBR(
      Map<BattlerSide, List<Battler>> battlers, TileGrid tileGrid) {
    final battlersEmptyList =
        List<Battler>.filled(tileGrid.width * tileGrid.height, Battler.voidBattler());

    return setBattlersOnStage(
      MapCorner.topLeft,
      MapCorner.bottomRight,
      battlersEmptyList,
      battlers.allyBattlers,
      battlers.enemyBattlers,
      tileGrid,
    );
  }

  static BattlerGrid getBattlersOnStageBLvsTR(
      Map<BattlerSide, List<Battler>> battlers, TileGrid tileGrid) {
    final battlersEmptyList =
        List<Battler>.filled(tileGrid.width * tileGrid.height, Battler.voidBattler());

    return setBattlersOnStage(
      MapCorner.bottomLeft,
      MapCorner.topRight,
      battlersEmptyList,
      battlers.allyBattlers,
      battlers.enemyBattlers,
      tileGrid,
    );
  }

  static BattlerGrid setBattlersOnStage(
    MapCorner allyCorner,
    MapCorner enemyCorner,
    List<Battler> battlersEmptyList,
    List<Battler> allyBattlersList,
    List<Battler> enemyBattlersList,
    TileGrid tileGrid, {
    int offset = 1,
  }) {
    final okAllies = _fillCornerSmart(
      battlersEmptyList,
      allyBattlersList,
      tileGrid,
      corner: allyCorner,
      offset: offset,
    );

    final okEnemies = _fillCornerSmart(
      battlersEmptyList,
      enemyBattlersList,
      tileGrid,
      corner: enemyCorner,
      offset: offset,
    );

    // TODO: Devolver mensaje de error si no sale bien
    // if (!okAllies || !okEnemies) {
    //   return 
    // }

    return BattlerGrid(tileGrid.width, tileGrid.height, battlersEmptyList);
  }


  // ------------------------------------------------------------
  //  RANDOM CORNER FILL
  // ------------------------------------------------------------

  /// Fills a "square-ish" area in [corner] with [battlers],
  /// trying to put them as close as possible to the area's center.
  /// Never silently drops battlers:
  /// - If area has no slots for a specific battler, tries the whole map.
  /// - If still impossible, returns false.
  static bool _fillCornerSmart(
    
    List<Battler> battlersEmptyList,
    List<Battler> battlersList,
    TileGrid grid, {
    required MapCorner corner,
    int offset = 1,
    double areaFactor = 2.0,
  }) {
    if (battlersList.isEmpty) return true;

    final battlerCount = battlersList.length;
    final desiredCells = max(1, (battlerCount * areaFactor).ceil());
    final side = max(1, sqrt(desiredCells).ceil());

    // 1) Spawn rectangle for that corner (logical target area)
    final rect = _cornerRect(grid, corner, side, offset);

    // Center of that area (can be fractional, we use it only for distance)
    final cx = (rect.left + rect.right - 1) / 2.0;
    final cy = (rect.top + rect.bottom - 1) / 2.0;

    // 2) Collect ALL walkable+empty tiles on the map
    final candidates = <Point<int>>[];
    for (int y = 0; y < grid.height; y++) {
      for (int x = 0; x < grid.width; x++) {
        if (!grid.tileAt(x, y).isWalkable) continue;
        final idx = y * grid.width + x;
        if (battlersEmptyList[idx].name.isNotEmpty) continue; // already occupied
        candidates.add(Point(x, y));
      }
    }

    if (candidates.isEmpty) {
      // No place at all for anyone
      return false;
    }

    // 3) Shuffle for tie-breaking randomness, then sort by distance to area center
    candidates.shuffle(_random);
    candidates.sort((a, b) {
      final da = (a.x - cx) * (a.x - cx) + (a.y - cy) * (a.y - cy);
      final db = (b.x - cx) * (b.x - cx) + (b.y - cy) * (b.y - cy);
      return da.compareTo(db);
    });

    // 4) Place each battler on the nearest still-free candidate
    for (final battler in battlersList) {
      bool placed = false;

      for (final p in candidates) {
        final idx = p.y * grid.width + p.x;

        // Re-check: other battlers may have occupied this since we built the list
        if (battlersEmptyList[idx].name.isNotEmpty) continue;

        // walkable is guaranteed by earlier check, but being defensive is cheap:
        if (!grid.tileAt(p.x, p.y).isWalkable) continue;

        battlersEmptyList[idx] = battler;
        placed = true;
        break;
      }

      if (!placed) {
        // There is literally no free tile left in the map for this battler
        return false;
      }
    }

    return true;
  }


  static _Rect _cornerRect(
    TileGrid grid,
    MapCorner corner,
    int side,
    int offset,
  ) {
    final w = grid.width;
    final h = grid.height;

    switch (corner) {
      case MapCorner.topLeft:
        final left = offset;
        final top = offset;
        final right = min(w, left + side);
        final bottom = min(h, top + side);
        return _Rect(left, top, right, bottom);

      case MapCorner.topRight:
        final right = w - offset;
        final left = max(0, right - side);
        final top = offset;
        final bottom = min(h, top + side);
        return _Rect(left, top, right, bottom);

      case MapCorner.bottomLeft:
        final left = offset;
        final bottom = h - offset;
        final top = max(0, bottom - side);
        final right = min(w, left + side);
        return _Rect(left, top, right, bottom);

      case MapCorner.bottomRight:
        final right = w - offset;
        final bottom = h - offset;
        final left = max(0, right - side);
        final top = max(0, bottom - side);
        return _Rect(left, top, right, bottom);
    }
  }

  // ------------------------------------------------------------
  //  CORNER-CHOOSING LOGIC
  // ------------------------------------------------------------

  static MapCorner chooseBestStartingCorner(TileGrid grid) {
    final counts = _walkablesPerCorner(grid);

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

  static MapCorner chooseEnemyCorner(TileGrid grid, MapCorner allyCorner) {
    final counts = _walkablesPerCorner(grid);

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

  static Map<MapCorner, int> _walkablesPerCorner(TileGrid grid) {
    final midX = grid.width ~/ 2;
    final midY = grid.height ~/ 2;

    int countWalkables(int x0, int y0, int x1, int y1) {
      int c = 0;
      for (int y = y0; y < y1; y++) {
        for (int x = x0; x < x1; x++) {
          if (grid.tileAt(x, y).isWalkable) c++;
        }
      }
      return c;
    }

    return <MapCorner, int>{
      MapCorner.topLeft: countWalkables(0, 0, midX, midY),
      MapCorner.topRight: countWalkables(midX, 0, grid.width, midY),
      MapCorner.bottomLeft: countWalkables(0, midY, midX, grid.height),
      MapCorner.bottomRight:
          countWalkables(midX, midY, grid.width, grid.height),
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
}

  // Small struct for a rectangle
  class _Rect {
    final int left;
    final int top;
    final int right;  // exclusive
    final int bottom; // exclusive
    const _Rect(this.left, this.top, this.right, this.bottom);
  }
