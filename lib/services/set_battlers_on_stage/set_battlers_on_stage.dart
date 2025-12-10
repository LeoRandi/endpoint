import "_imports.dart";

enum MapCorner { topLeft, topRight, bottomLeft, bottomRight }

class SetBattlersOnStage {
  static BattlerGrid getBattlersOnStageCalc(
      Map<BattlerSide, List<Battler>> battlers, TileGrid tileGrid) {
    List<Battler> battlersEmptyList =
        List.filled(tileGrid.width * tileGrid.height, Battler.voidBattler());

    final allyCorner = SetBattlersOnStage.chooseBestStartingCorner(tileGrid);

    final enemyCorner =
        SetBattlersOnStage.chooseEnemyCorner(tileGrid, allyCorner);

    return setBattlersOnStage(allyCorner, enemyCorner, battlersEmptyList,
        battlers.allyBattlers, battlers.enemyBattlers, tileGrid);
  }

  static BattlerGrid getBattlersOnStageTLvsBR(
      Map<BattlerSide, List<Battler>> battlers, TileGrid tileGrid) {
    List<Battler> battlersEmptyList =
        List.filled(tileGrid.width * tileGrid.height, Battler.voidBattler());

    return setBattlersOnStage(
        MapCorner.topLeft,
        MapCorner.bottomRight,
        battlersEmptyList,
        battlers.allyBattlers,
        battlers.enemyBattlers,
        tileGrid);
  }

  static BattlerGrid getBattlersOnStageBLvsTR(
      Map<BattlerSide, List<Battler>> battlers, TileGrid tileGrid) {
    List<Battler> battlersEmptyList =
        List.filled(tileGrid.width * tileGrid.height, Battler.voidBattler());

    return setBattlersOnStage(
        MapCorner.bottomLeft,
        MapCorner.topRight,
        battlersEmptyList,
        battlers.allyBattlers,
        battlers.enemyBattlers,
        tileGrid);
  }

  static BattlerGrid setBattlersOnStage(
      MapCorner allyCorner,
      MapCorner enemyCorner,
      List<Battler> battlersEmptyList,
      List<Battler> allyBattlersList,
      List<Battler> enemyBattlersList,
      TileGrid tileGrid,
      {int offset = 1}) {
    switch (allyCorner) {
      case MapCorner.topLeft:
        _fillTopLeftCorner(battlersEmptyList, allyBattlersList, tileGrid,
            offset: offset);
        break;
      case MapCorner.topRight:
        _fillTopRightCorner(battlersEmptyList, allyBattlersList, tileGrid,
            offset: offset);
        break;
      case MapCorner.bottomLeft:
        _fillBottomLeftCorner(battlersEmptyList, allyBattlersList, tileGrid,
            offset: offset);
        break;
      case MapCorner.bottomRight:
        _fillBottomRightCorner(battlersEmptyList, allyBattlersList, tileGrid,
            offset: offset);
        break;
    }

    switch (enemyCorner) {
      case MapCorner.topLeft:
        _fillTopLeftCorner(battlersEmptyList, enemyBattlersList, tileGrid,
            offset: offset);
        break;
      case MapCorner.topRight:
        _fillTopRightCorner(battlersEmptyList, enemyBattlersList, tileGrid,
            offset: offset);
        break;
      case MapCorner.bottomLeft:
        _fillBottomLeftCorner(battlersEmptyList, enemyBattlersList, tileGrid,
            offset: offset);
        break;
      case MapCorner.bottomRight:
        _fillBottomRightCorner(battlersEmptyList, enemyBattlersList, tileGrid,
            offset: offset);
        break;
    }

    final battlerGrid =
        BattlerGrid(tileGrid.width, tileGrid.height, battlersEmptyList);
    return battlerGrid;
  }

  static void _fillTopLeftCorner(List<Battler> battlersEmptyList,
      List<Battler> battlersList, TileGrid tileGrid,
      {int offset = 0}) {
    Battler? currentBattler = battlersList.firstOrNull;

    for (int y = 0 + offset; y < tileGrid.height; y++) {
      // vertical
      if (currentBattler == null) break;
      for (int x = 0 + offset; x < tileGrid.width; x++) {
        // horizontal
        if (tileGrid.tileAt(y, x).isWalkable &&
            battlersEmptyList[y * tileGrid.width + x].name.isEmpty) { // si es void tendrá un name como ""
          battlersEmptyList[y * tileGrid.width + x] = battlersList.getNext(currentBattler) ;
          if (currentBattler == battlersList.lastOrNull) break;
        }
      }
      if (currentBattler == battlersList.lastOrNull) break;
    }
  }

  static void _fillBottomRightCorner(List<Battler> battlersEmptyList,
      List<Battler> battlersList, TileGrid tileGrid,
      {int offset = 0}) {
    Battler? currentBattler = battlersList.firstOrNull;

    for (int y = tileGrid.height - 1 - offset; y >= 0; y--) {
      // vertical
      if (currentBattler == null) break;
      for (int x = tileGrid.width - 1 - offset; x >= 0; x--) {
        // horizontal
        if (tileGrid.tileAt(y, x).isWalkable &&
            battlersEmptyList[y * tileGrid.width + x].name.isEmpty) { // si es void tendrá un name como ""
          battlersEmptyList[y * tileGrid.width + x] = battlersList.getNext(currentBattler) ;
          if (currentBattler == battlersList.lastOrNull) break;
        }
      }
      if (currentBattler == battlersList.lastOrNull) break;
      currentBattler = battlersList.getNext(currentBattler);
    }
  }

  static void _fillBottomLeftCorner(List<Battler> battlersEmptyList,
      List<Battler> battlersList, TileGrid tileGrid,
      {int offset = 0}) {
    Battler? currentBattler = battlersList.firstOrNull;

    for (int y = tileGrid.height - 1 - offset; y >= 0; y--) {
      // vertical
      if (currentBattler == null) break;
      for (int x = 0 + offset; x < tileGrid.width; x++) {
        // horizontal
        if (tileGrid.tileAt(y, x).isWalkable &&
            battlersEmptyList[y * tileGrid.width + x].name.isEmpty) { // si es void tendrá un name como ""
          battlersEmptyList[y * tileGrid.width + x] = battlersList.getNext(currentBattler) ;
          if (currentBattler == battlersList.lastOrNull) break;
        }
      }
      if (currentBattler == battlersList.lastOrNull) break;
      currentBattler = battlersList.getNext(currentBattler);
    }
  }

  static void _fillTopRightCorner(List<Battler> battlersEmptyList,
      List<Battler> battlersList, TileGrid tileGrid,
      {int offset = 0}) {
    Battler? currentBattler = battlersList.firstOrNull;

    for (int y = 0 + offset; y < tileGrid.height; y++) {
      // vertical
      if (currentBattler == null) break;
      for (int x = tileGrid.width - 1 - offset; x >= 0; x--) {
        // horizontal
        if (tileGrid.tileAt(y, x).isWalkable &&
            battlersEmptyList[y * tileGrid.width + x].name.isEmpty) { // si es void tendrá un name como ""
          battlersEmptyList[y * tileGrid.width + x] = battlersList.getNext(currentBattler) ;
          if (currentBattler == battlersList.lastOrNull) break;
        }
      }
      if (currentBattler == battlersList.lastOrNull) break;
      currentBattler = battlersList.getNext(currentBattler);
    }
  }

  /// Choose the corner with the highest number of walkable tiles.
  static MapCorner chooseBestStartingCorner(TileGrid grid) {
    final counts = _walkablesPerCorner(grid);

    // If everything is blocked, just default to top-left.
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

  /// Choose a corner for enemies:
  /// - as far as possible from [allyCorner]
  /// - but still with walkable tiles
  /// - fallback to [allyCorner] if nothing else is usable
  static MapCorner chooseEnemyCorner(TileGrid grid, MapCorner allyCorner) {
    final counts = _walkablesPerCorner(grid);

    // If no corner has walkables, just put them together (degenerate case).
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
      if (count == 0) continue; // this corner is basically unusable

      final pos = _cornerCoord(corner);
      final dx = pos.x - allyPos.x;
      final dy = pos.y - allyPos.y;
      final dist2 = dx * dx + dy * dy;

      // Prefer farthest corner; tie-breaker = more walkables
      if (dist2 > bestDist2 || (dist2 == bestDist2 && count > bestCount)) {
        best = corner;
        bestDist2 = dist2;
        bestCount = count;
      }
    }

    // If no other corner has walkables, fallback to ally corner.
    return best ?? allyCorner;
  }

  /// Count walkable tiles inside each quadrant.
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

    final counts = <MapCorner, int>{
      MapCorner.topLeft: countWalkables(0, 0, midX, midY),
      MapCorner.topRight: countWalkables(midX, 0, grid.width, midY),
      MapCorner.bottomLeft: countWalkables(0, midY, midX, grid.height),
      MapCorner.bottomRight:
          countWalkables(midX, midY, grid.width, grid.height),
    };

    return counts;
  }

  /// Logical coordinates of each corner in a 2x2 "corner space"
  /// (used only for "farther/closer" comparison).
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
