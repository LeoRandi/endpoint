enum CellType { empty, player, wall, enemy }

class FloorGrid {
  final int rows;
  final int cols;
  final List<List<CellType>> cells;

  FloorGrid._(this.rows, this.cols, this.cells);

  /// Crea desde ints: 0 vacío, 1 jugador, 2 pared, 3 enemigo
  factory FloorGrid.fromInts(List<List<int>> map) {
    final rows = map.length;
    final cols = map.isNotEmpty ? map.first.length : 0;
    final cells = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        switch (map[r][c]) {
          case 1: return CellType.player;
          case 2: return CellType.wall;
          case 3: return CellType.enemy;
          default: return CellType.empty;
        }
      });
    });
    return FloorGrid._(rows, cols, cells);
  }

  /// Mapa de ejemplo solicitado
  factory FloorGrid.sampleRoom() => FloorGrid.fromInts(const [
        [2,2,2,2,2],
        [2,0,3,0,2],
        [2,0,0,0,2],
        [2,0,1,0,2],
        [2,2,2,2,2],
      ]);

  CellType cell(int r, int c) => cells[r][c];
}
