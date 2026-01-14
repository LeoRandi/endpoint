import "_imports.dart";

class BattlerMover {
  /// Simple BFS shortest path (4-dir).
  /// - Ignores battler occupancy completely (it can path "through anything").
  /// - Still respects terrain walkability (highest-z TileObject, ignoring distance overlays).
  /// - Returns [origin] if no path.
  static List<GridObject> calculateClosestPath(
    Grid grid,
    GridObject origin,
    GridObject destination,
    int size,
  ) {
    if (identical(origin, destination)) return [origin];

    final startIdx = idx(origin.x, origin.y, size);
    final goalIdx = idx(destination.x, destination.y, size);

    final dist = List<int>.filled(size * size, -1);
    final prev = List<int>.filled(size * size, -1);

    final queue = <int>[];
    int qi = 0;

    bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < size && y < size;

    TileObject? terrainAt(int x, int y) {
      final go = grid.gridObjectAt(x, y, size);
      if (go == null) return null;

      TileObject? highest;
      int? highestZ;

      for (final obj in go.objects.values) {
        if (obj is! TileObject) continue;

        // ignore overlays used for distance painting
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

    bool canTraverse(int x, int y) {
      final t = terrainAt(x, y);
      return t != null && t.isWalkable;
    }

    dist[startIdx] = 0;
    queue.add(startIdx);

    const dirs = <List<int>>[
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ];

    while (qi < queue.length) {
      final cur = queue[qi++];
      if (cur == goalIdx) break;

      final cx = cur % size;
      final cy = cur ~/ size;

      for (final d in dirs) {
        final nx = cx + d[0];
        final ny = cy + d[1];
        if (!inBounds(nx, ny)) continue;

        final ni = idx(nx, ny, size);
        if (dist[ni] != -1) continue;

        if (!canTraverse(nx, ny)) continue;

        dist[ni] = dist[cur] + 1;
        prev[ni] = cur;
        queue.add(ni);
      }
    }

    if (dist[goalIdx] == -1) return [origin];

    // Reconstruct
    final indices = <int>[];
    int cur = goalIdx;
    while (cur != -1) {
      indices.add(cur);
      if (cur == startIdx) break;
      cur = prev[cur];
    }
    final reversedIndices = indices.reversed.toList();

    final path = <GridObject>[];
    for (final i in reversedIndices) {
      final x = i % size;
      final y = i ~/ size;
      final go = grid.gridObjectAt(x, y, size);
      if (go == null) return [origin]; // safety if grid has holes
      path.add(go);
    }

    return path;
  }

  /// FORCE move: whatever is in [next.objects[depth]] gets overwritten (removed).
  /// This guarantees the moving object ends up at the target cell for that step.
  static void moveToTargetGrid(
    Grid grid,
    GridObject current,
    GridObject next,
    int depth, {
    bool updateObjectCoords = true,
  }) {
    final moving = current.objects[depth];
    if (moving == null) return;

    // Remove whatever was there (force overwrite)
    next.objects.remove(depth);

    // Remove from current
    current.objects.remove(depth);

    // Place in next
    next.objects[depth] = moving;

    // Keep coords in sync if it's a BaseObject (BattlerObject is)
    if (updateObjectCoords) {
      moving.x = next.x;
      moving.y = next.y;
      // don't touch z unless your project uses z == depth; if it does, uncomment:
      // moving.z = depth;
    }
  }
}
