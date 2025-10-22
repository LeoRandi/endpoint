// grid_generator.dart
import 'dart:math';

class GridGenOptions {
  final int width; // columnas (x)
  final int height; // filas (y)
  /// 0..1 = fracción del área que intentará ser suelo (habitaciones + pasillos)
  final double roomDensity;
  /// 0..1 = enemigos por casilla de suelo (aprox). 0.02 = 2%
  final double enemyDensity;
  /// Tamaño mínimo de habitación (ambos ≥ 3)
  final int minRoomW;
  final int minRoomH;
  /// Relación máx. alto:ancho o ancho:alto (≤ 4)
  final double maxAspectRatio; // 4.0 -> 1:4
  /// Intentos para emplazar habitaciones
  final int roomPlacementTries;

  const GridGenOptions({
    required this.width,
    required this.height,
    required this.roomDensity,
    required this.enemyDensity,
    this.minRoomW = 3,
    this.minRoomH = 3,
    this.maxAspectRatio = 4.0,
    this.roomPlacementTries = 200,
  });
}

class GridGenerator {
  static const int tileFloor = 0;
  static const int tilePlayer = 1;
  static const int tileEnemy = 3;
  static const int tileWall = 2;

  static List<List<int>> generate(GridGenOptions o, {int? seed}) {
    final rng = seed == null ? Random() : Random(seed);

    // Mapa base: todo paredes.
    final g = List.generate(
      o.height,
      (_) => List.filled(o.width, tileWall),
    );

    // 1) Proponer habitaciones aleatorias (rectángulos) cumpliendo restricciones.
    final rooms = <_Room>[];
    final targetFloor = max(
      1,
      (o.width * o.height * o.roomDensity).round(),
    );

    for (int t = 0; t < o.roomPlacementTries; t++) {
      final w = _randInRange(rng, o.minRoomW, max(o.minRoomW, o.width ~/ 2));
      final h = _randInRange(rng, o.minRoomH, max(o.minRoomH, o.height ~/ 2));

      // Aspect ratio ≤ maxAspectRatio
      final ar1 = w / h;
      final ar2 = h / w;
      if (ar1 > o.maxAspectRatio || ar2 > o.maxAspectRatio) continue;

      final x = _randInRange(rng, 1, max(1, o.width - w - 1));
      final y = _randInRange(rng, 1, max(1, o.height - h - 1));

      final candidate = _Room(x, y, w, h);

      // Evitar solapes: exigimos un margen de 1 casilla entre habitaciones
      bool overlaps = false;
      for (final r in rooms) {
        if (candidate.expanded(1).intersects(r.expanded(1))) {
          overlaps = true;
          break;
        }
      }
      if (overlaps) continue;

      rooms.add(candidate);
      if (_carvedArea(rooms) >= targetFloor) break;
    }

    // 2) Tallar habitaciones en el grid.
    for (final r in rooms) {
      for (int yy = r.y; yy < r.y + r.h; yy++) {
        for (int xx = r.x; xx < r.x + r.w; xx++) {
          g[yy][xx] = tileFloor;
        }
      }
    }

    // Si no hay habitaciones, garantizamos al menos 1 pequeña central.
    if (rooms.isEmpty) {
      final cx = o.width ~/ 2;
      final cy = o.height ~/ 2;
      final r = _Room(
        max(1, cx - 1),
        max(1, cy - 1),
        min(3, o.width - 2),
        min(3, o.height - 2),
      );
      rooms.add(r);
      for (int yy = r.y; yy < r.y + r.h; yy++) {
        for (int xx = r.x; xx < r.x + r.w; xx++) {
          g[yy][xx] = tileFloor;
        }
      }
    }

    // 3) Conectar habitaciones con pasillos 1-celda (L recto H+V u V+H)
    //    Hacemos un MST simple por distancia-Manhattan entre centros.
    final centers = rooms.map((r) => r.center).toList();
    final edges = _mst(centers);

    for (final e in edges) {
      final a = centers[e.a];
      final b = centers[e.b];

      // Randomiza el orden del codo para variedad
      if (rng.nextBool()) {
        _carveH(g, a.x, b.x, a.y);
        _carveV(g, a.y, b.y, b.x);
      } else {
        _carveV(g, a.y, b.y, a.x);
        _carveH(g, a.x, b.x, b.y);
      }
    }

    // 3.5) Irregularizar bordes de habitaciones con “mordidas”
    _irregularizeEdgesStrict(
      g,
      rooms,
      rng,
      triesPerRoom: 6,
      maxDepth: 2,        // distancia máxima hacia fuera desde el borde
      widenChance: 0.1,  // ensancha 1 celda a lados a veces
    );

    // 4) Colocar jugador (1) en el centro de la primera habitación.
    final start = rooms.first.center;
    g[start.y][start.x] = tilePlayer;

    // 5) Calcular casillas de suelo y poblar enemigos (3) según densidad.
    final floorCells = <_Pt>[];
    for (int y = 0; y < o.height; y++) {
      for (int x = 0; x < o.width; x++) {
        if (g[y][x] == tileFloor) floorCells.add(_Pt(x, y));
      }
    }

    final enemyCount = max(0, (floorCells.length * o.enemyDensity).round());

    // Evitar colocar enemigo donde hay jugador
    floorCells.removeWhere((p) => p.x == start.x && p.y == start.y);
    floorCells.shuffle(rng);

    for (int i = 0; i < min(enemyCount, floorCells.length); i++) {
      final p = floorCells[i];
      g[p.y][p.x] = tileEnemy;
    }

    // 6) Borde externo siempre pared (2)
    for (int x = 0; x < o.width; x++) {
      g[0][x] = tileWall;
      g[o.height - 1][x] = tileWall;
    }
    for (int y = 0; y < o.height; y++) {
      g[y][0] = tileWall;
      g[y][o.width - 1] = tileWall;
    }

    return g;
  }

  // ——————————————————————— helpers ———————————————————————

  static void _irregularizeEdgesStrict(
    List<List<int>> g,
    List<_Room> rooms,
    Random rng, {
    int triesPerRoom = 2,
    int maxDepth = 3,
    double widenChance = 0.35,
  }) {
    if (rooms.isEmpty) return;
    final h = g.length;
    final w = g.first.length;

    bool inBounds(int x, int y) => x >= 1 && x <= w - 2 && y >= 1 && y <= h - 2;

    // ¿Es suelo del propio cuarto?
    bool isRoomFloor(_Room r, int x, int y) =>
        x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h && g[y][x] == tileFloor;

    // ¿Tiene alrededor suelo que NO es del cuarto? (evitar conectar con pasillos externos)
    bool touchesExternalFloor(_Room r, int x, int y) {
      const d = [ [1,0], [-1,0], [0,1], [0,-1] ];
      for (final v in d) {
        final nx = x + v[0], ny = y + v[1];
        if (!inBounds(nx, ny)) continue;
        if (g[ny][nx] == tileFloor && !isRoomFloor(r, nx, ny)) {
          return true;
        }
      }
      return false;
    }

    // ¿Está adyacente (4-dir) al cuarto o a la mordida en curso?
    bool adjacentToRoomOrBite(_Room r, int x, int y, Set<int> bite) {
      const d = [ [1,0], [-1,0], [0,1], [0,-1] ];
      for (final v in d) {
        final nx = x + v[0], ny = y + v[1];
        if (!inBounds(nx, ny)) continue;
        if (isRoomFloor(r, nx, ny)) return true;
        if (bite.contains(ny * 100000 + nx)) return true;
      }
      return false;
    }

    for (final r in rooms) {
      for (int t = 0; t < triesPerRoom; t++) {
        // Elige un lado del cuarto y un punto de ese borde (evita esquinas)
        final side = rng.nextInt(4);
        int bx, by, dx, dy, span;
        switch (side) {
          case 0: // top → hacia arriba
            if (r.w < 3) continue;
            bx = r.x + 1 + rng.nextInt(r.w - 2);
            by = r.y;
            dx = 0; dy = -1; span = 1;
            break;
          case 1: // right → derecha
            if (r.h < 3) continue;
            bx = r.x + r.w - 1;
            by = r.y + 1 + rng.nextInt(r.h - 2);
            dx = 1; dy = 0; span = 1;
            break;
          case 2: // bottom → abajo
            if (r.w < 3) continue;
            bx = r.x + 1 + rng.nextInt(r.w - 2);
            by = r.y + r.h - 1;
            dx = 0; dy = 1; span = 1;
            break;
          default: // left → izquierda
            if (r.h < 3) continue;
            bx = r.x;
            by = r.y + 1 + rng.nextInt(r.h - 2);
            dx = -1; dy = 0; span = 1;
        }

        // Solo empezamos si la celda inicial es pared y toca interior del cuarto
        if (!inBounds(bx + dx, by + dy)) continue;
        if (g[by + dy][bx + dx] != tileWall) continue;
        if (!adjacentToRoomOrBite(r, bx + dx, by + dy, {})) continue;

        // “Bite” local: conjunto de celdas talladas en esta mordida
        final bite = <int>{};

        // talla hasta maxDepth, manteniendo contacto con el cuarto o con la propia mordida
        for (int depth = 1; depth <= maxDepth; depth++) {
          final x = bx + dx * depth;
          final y = by + dy * depth;
          if (!inBounds(x, y)) break;

          // Si tocaría suelo externo, paramos (no crear T/túneles)
          if (touchesExternalFloor(r, x, y)) break;

          // Solo convertir paredes; si ya no es pared, paramos
          if (g[y][x] != tileWall) break;

          // Debe seguir pegado al cuarto o a celdas ya talladas
          if (!adjacentToRoomOrBite(r, x, y, bite)) break;

          g[y][x] = tileFloor;
          bite.add(y * 100000 + x);

          // Ensanchar perpendicularmente a veces (una celda a cada lado si son pared)
          if (rng.nextDouble() < widenChance) {
            if (dx == 0) {
              // vertical → lados izquierda/derecha
              if (inBounds(x - 1, y) && g[y][x - 1] == tileWall && !touchesExternalFloor(r, x - 1, y)) {
                g[y][x - 1] = tileFloor; bite.add(y * 100000 + (x - 1));
              }
              if (inBounds(x + 1, y) && g[y][x + 1] == tileWall && !touchesExternalFloor(r, x + 1, y)) {
                g[y][x + 1] = tileFloor; bite.add(y * 100000 + (x + 1));
              }
            } else {
              // horizontal → arriba/abajo
              if (inBounds(x, y - 1) && g[y - 1][x] == tileWall && !touchesExternalFloor(r, x, y - 1)) {
                g[y - 1][x] = tileFloor; bite.add((y - 1) * 100000 + x);
              }
              if (inBounds(x, y + 1) && g[y + 1][x] == tileWall && !touchesExternalFloor(r, x, y + 1)) {
                g[y + 1][x] = tileFloor; bite.add((y + 1) * 100000 + x);
              }
            }
          }
        }
      }
    }
  }

  static void _irregularizeEdges(
    List<List<int>> g,
    List<_Room> rooms,
    Random rng, {
    double nibbleChance = 0.35,
    int triesPerRoom = 2,
    int maxNibbleLen = 3,
    double branchChance = 0.35,
  }) {
    if (rooms.isEmpty) return;
    final h = g.length;
    final w = g.first.length;

    bool inBounds(int x, int y) => x >= 1 && x <= w - 2 && y >= 1 && y <= h - 2;

    // Para cada habitación, intentamos “morder” su contorno hacia fuera.
    for (final r in rooms) {
      for (int t = 0; t < triesPerRoom; t++) {
        if (rng.nextDouble() > nibbleChance) continue;

        // Elige un lado: 0=top,1=right,2=bottom,3=left
        final side = rng.nextInt(4);

        // Rango del segmento (evitar esquinas para no abrir huecos raros)
        int sx, sy, ex, ey, dx, dy;
        switch (side) {
          case 0: // top, empuja hacia arriba
            sx = r.x + 1; sy = r.y;
            ex = r.x + r.w - 2; ey = r.y;
            dx = 0; dy = -1;
            break;
          case 1: // right, empuja hacia la derecha
            sx = r.x + r.w - 1; sy = r.y + 1;
            ex = r.x + r.w - 1; ey = r.y + r.h - 2;
            dx = 1; dy = 0;
            break;
          case 2: // bottom, empuja hacia abajo
            sx = r.x + 1; sy = r.y + r.h - 1;
            ex = r.x + r.w - 2; ey = r.y + r.h - 1;
            dx = 0; dy = 1;
            break;
          default: // left, empuja hacia la izquierda
            sx = r.x; sy = r.y + 1;
            ex = r.x; ey = r.y + r.h - 2;
            dx = -1; dy = 0;
        }

        // Si el lado es demasiado corto, salta
        if ((sx == ex && (ey - sy) < 0) || (sy == ey && (ex - sx) < 0)) continue;

        // Elige un punto de inicio en ese borde
        int bx, by;
        if (sx == ex) {
          final y0 = rng.nextInt((ey - sy + 1).clamp(1, ey - sy + 1));
          bx = sx; by = sy + y0;
        } else {
          final x0 = rng.nextInt((ex - sx + 1).clamp(1, ex - sx + 1));
          bx = sx + x0; by = sy;
        }

        // Longitud de la “mordida”
        final len = 2 + rng.nextInt(maxNibbleLen.clamp(1, 6));

        // Carva hacia fuera mientras sea pared interna y dentro de límites
        for (int i = 1; i <= len; i++) {
          final nx = bx + dx * i;
          final ny = by + dy * i;
          if (!inBounds(nx, ny)) break;

          // Solo convertimos pared (2) en suelo (0); si ya es suelo, detenemos para no abrir túneles infinitos
          if (g[ny][nx] == tileWall) {
            g[ny][nx] = tileFloor;

            // A veces ensancha un poco en perpendicular (forma “lengua”)
            if (rng.nextDouble() < branchChance) {
              if (dx == 0) {
                // vertical → ensancha a izquierda/derecha
                if (inBounds(nx - 1, ny) && g[ny][nx - 1] == tileWall) g[ny][nx - 1] = tileFloor;
                if (inBounds(nx + 1, ny) && g[ny][nx + 1] == tileWall) g[ny][nx + 1] = tileFloor;
              } else {
                // horizontal → ensancha arriba/abajo
                if (inBounds(nx, ny - 1) && g[ny - 1][nx] == tileWall) g[ny - 1][nx] = tileFloor;
                if (inBounds(nx, ny + 1) && g[ny + 1][nx] == tileWall) g[ny + 1][nx] = tileFloor;
              }
            }
          } else {
            break;
          }
        }
      }
    }
  }


  static int _randInRange(Random rng, int a, int b) {
    if (b < a) return a;
    return a + rng.nextInt(b - a + 1);
  }

  static int _carvedArea(List<_Room> rooms) =>
      rooms.fold(0, (s, r) => s + r.w * r.h);

  static void _carveH(List<List<int>> g, int x1, int x2, int y) {
    final s = x1 <= x2 ? x1 : x2;
    final e = x1 <= x2 ? x2 : x1;
    for (int x = s; x <= e; x++) {
      g[y][x] = tileFloor;
    }
  }

  static void _carveV(List<List<int>> g, int y1, int y2, int x) {
    final s = y1 <= y2 ? y1 : y2;
    final e = y1 <= y2 ? y2 : y1;
    for (int y = s; y <= e; y++) {
      g[y][x] = tileFloor;
    }
  }

  /// MST por Kruskal sobre centros.
  static List<_Edge> _mst(List<_Pt> pts) {
    if (pts.length <= 1) return [];
    final edges = <_Edge>[];
    for (int i = 0; i < pts.length; i++) {
      for (int j = i + 1; j < pts.length; j++) {
        final d = (pts[i].x - pts[j].x).abs() + (pts[i].y - pts[j].y).abs();
        edges.add(_Edge(i, j, d));
      }
    }
    edges.sort((a, b) => a.w.compareTo(b.w));

    final uf = _UF(pts.length);
    final res = <_Edge>[];
    for (final e in edges) {
      if (uf.find(e.a) != uf.find(e.b)) {
        uf.union(e.a, e.b);
        res.add(e);
        if (res.length == pts.length - 1) break;
      }
    }
    return res;
  }
}

class _Room {
  final int x, y, w, h;
  _Room(this.x, this.y, this.w, this.h);

  _Room expanded(int m) => _Room(x - m, y - m, w + 2 * m, h + 2 * m);

  bool intersects(_Room o) {
    final ax2 = x + w - 1, ay2 = y + h - 1;
    final bx2 = o.x + o.w - 1, by2 = o.y + o.h - 1;
    final noOverlap =
        (ax2 < o.x) || (bx2 < x) || (ay2 < o.y) || (by2 < y);
    return !noOverlap;
  }

  _Pt get center => _Pt(x + w ~/ 2, y + h ~/ 2);
}

class _Pt {
  final int x, y;
  const _Pt(this.x, this.y);
}

class _Edge {
  final int a, b, w;
  _Edge(this.a, this.b, this.w);
}

class _UF {
  final List<int> p, r;
  _UF(int n)
      : p = List.generate(n, (i) => i),
        r = List.filled(n, 0);
  int find(int x) => p[x] == x ? x : p[x] = find(p[x]);
  void union(int a, int b) {
    a = find(a);
    b = find(b);
    if (a == b) return;
    if (r[a] < r[b]) {
      p[a] = b;
    } else if (r[a] > r[b]) {
      p[b] = a;
    } else {
      p[b] = a;
      r[a]++;
    }
  }
}
