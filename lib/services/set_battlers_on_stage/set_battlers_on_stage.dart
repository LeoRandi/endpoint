import "_imports.dart";

enum MapCorner { topLeft, topRight, bottomLeft, bottomRight }

class SetBattlersOnStage {
  static final Random _random = Random();

  static BattlerGrid getBattlersOnStageCalc(
      Map<BattlerSide, List<Battler>> battlers, TileGrid tileGrid) {
    final battlersEmptyList = List<Battler>.filled(
        tileGrid.width * tileGrid.height, Battler.voidBattler());

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
    final battlersEmptyList = List<Battler>.filled(
        tileGrid.width * tileGrid.height, Battler.voidBattler());

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
    final battlersEmptyList = List<Battler>.filled(
        tileGrid.width * tileGrid.height, Battler.voidBattler());

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

    // Center of that area (only for distance computation)
    final cx = (rect.left + rect.right - 1) / 2.0;
    final cy = (rect.top + rect.bottom - 1) / 2.0;

    // 2) Collect candidates, separated by region/global and path/river
    final regionPath = <Point<int>>[];
    final regionRiver = <Point<int>>[];
    final globalPath = <Point<int>>[];
    final globalRiver = <Point<int>>[];

    for (int y = 0; y < grid.height; y++) {
      for (int x = 0; x < grid.width; x++) {
        final tile = grid.tileAt(x, y);
        if (!tile.isWalkable) continue;

        final idx = y * grid.width + x;
        if (battlersEmptyList[idx].name.isNotEmpty)
          continue; // already occupied

        final p = Point(x, y);
        final inRegion = x >= rect.left &&
            x < rect.right &&
            y >= rect.top &&
            y < rect.bottom;

        final tileType = tile.tileType; // or tile.type

        if (tileType == TileType.path) {
          globalPath.add(p);
          if (inRegion) regionPath.add(p);
        } else if (tileType == TileType.river) {
          globalRiver.add(p);
          if (inRegion) regionRiver.add(p);
        }
      }
    }

    // If there are literally no candidates of any kind, we cannot place anyone.
    if (regionPath.isEmpty &&
        regionRiver.isEmpty &&
        globalPath.isEmpty &&
        globalRiver.isEmpty) {
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

    // 3) Sort all groups by distance to the region center
    sortByDistance(regionPath);
    sortByDistance(regionRiver);
    sortByDistance(globalPath);
    sortByDistance(globalRiver);

    bool placeFromList(Battler battler, List<Point<int>> list) {
      for (final p in list) {
        final idx = p.y * grid.width + p.x;

        // Re-check: since we built these lists, other battlers may have used this tile
        if (battlersEmptyList[idx].name.isNotEmpty) continue;
        if (!grid.tileAt(p.x, p.y).isWalkable) continue;

        battlersEmptyList[idx] = battler;
        return true;
      }
      return false;
    }

    // 4) Place each battler with the required priority cascade
    for (final battler in battlersList) {
      if (placeFromList(battler, regionPath)) continue;
      if (placeFromList(battler, regionRiver)) continue;
      if (placeFromList(battler, globalPath)) continue;
      if (placeFromList(battler, globalRiver)) continue;

      // No valid tile at all for this battler
      return false;
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
  final int right; // exclusive
  final int bottom; // exclusive
  const _Rect(this.left, this.top, this.right, this.bottom);
}
