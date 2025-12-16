import "_imports.dart";

class DistanceManager {
  static bool addSelectedBattlerDistance(
      {required Grid grid,
      required int size,
      required Battler? selectedBattler,
      required Map<BattlerSide, List<Battler>> battlers}) {
    try {
      // 1) Clear previous distance overlays (depth 2)
      clearAllDistances(grid);

      if (selectedBattler == null) return true;

      // 2) Locate selected battler on the grid
      int? startX;
      int? startY;
      for (final go in grid) {
        if (go == null) continue;
        final bo = go.objects[depthTileBase];
        if (bo is BattlerObject && identical(bo.battler, selectedBattler)) {
          startX = bo.x;
          startY = bo.y;
          break;
        }
      }

      if (startX == null || startY == null) return true;

      // 3) Movement range (speed)
      final int maxDistance = selectedBattler.getStat(BattlerStatsType.speed);  
      if (maxDistance <= 0) return true;

      bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < size && y < size;

      TileObject? tileObjectAt(int x, int y) {
        final go = grid.gridObjectAt(x, y, size);
        if (go == null) return null;

        TileObject? highest;
        int? highestZ;

        for (final obj in go.objects.values) {
          if (obj is! TileObject) continue;
          // Ignore the distance overlay layer when evaluating terrain.
          if (obj.tileType == TileType.distance ||
              obj.tileType == TileType.enemyDistance) {
            continue;
          }

          if (highestZ == null || obj.z > highestZ) {
            highestZ = obj.z;
            highest = obj;
          }
        }

        return highest;
      }

      BattlerObject? battlerObjectAt(int x, int y) {
        final go = grid.gridObjectAt(x, y, size);
        if (go == null) return null;
        final bo = go.objects[depthTileBase];
        return bo is BattlerObject ? bo : null;
      }

      bool canTraverse(int x, int y) {
        final tile = tileObjectAt(x, y);
        if (tile == null || !tile.isWalkable) return false;

        final occupant = battlerObjectAt(x, y);
        if (occupant == null) return true;

        // Can't walk through enemy battlers (anything not on our side).
        return occupant.battler.side == selectedBattler.side;
      }

      bool canPlaceOverlay(int x, int y) {
        // Never place distance overlay on a cell containing any battler.
        return battlerObjectAt(x, y) == null;
      }

      final List<int> dist = List<int>.filled(size * size, -1);
      final queue = <List<int>>[]; // [x, y]
      int qi = 0;

      dist[idx(startX, startY, size)] = 0;
      queue.add([startX, startY]);

      while (qi < queue.length) {
        final node = queue[qi++];
        final int x = node[0];
        final int y = node[1];
        final int d = dist[idx(x, y, size)];
        if (d >= maxDistance) continue;

        const dirs = <List<int>>[
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
        ];

        for (final dir in dirs) {
          final nx = x + dir[0];
          final ny = y + dir[1];
          if (!inBounds(nx, ny)) continue;

          final ni = idx(nx, ny, size);
          if (dist[ni] != -1) continue;

          if (!canTraverse(nx, ny)) continue;

          dist[ni] = d + 1;
          queue.add([nx, ny]);
        }
      }

      // 4) Paint overlays for all reachable cells (excluding occupied cells)
      final bool isAlly = selectedBattler.side == BattlerSide.ally;

      for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
          final d = dist[idx(x, y, size)];
          if (d <= 0 || d > maxDistance) continue;
          if (!canPlaceOverlay(x, y)) continue;

          final go = grid.gridObjectAt(x, y, size);
          if (go == null) continue;

          go.objects[depthAbove] = isAlly
              ? TileObject.distance(x, y, depthAbove)
              : TileObject.enemyDistance(x, y, depthAbove);
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  static void clearAllDistances(Grid grid) {
    for (final go in grid) {
      if (go == null) continue;
      final obj = go.objects[depthAbove];
      if (obj is TileObject &&
          (obj.tileType == TileType.distance ||
              obj.tileType == TileType.enemyDistance)) {
        go.objects.remove(depthAbove);
      }
    }
  }
}
