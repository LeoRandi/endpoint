// lib/game/domain/floor_grid.dart
import '../services/grid_generator_service.dart'; // tu archivo

enum CellType { empty, player, wall, enemy }

class FloorGrid {
  final int rows;
  final int cols;
  final List<List<CellType>> cells;

  FloorGrid._(this.rows, this.cols, this.cells);

  factory FloorGrid.fromInts(List<List<int>> map) {
    final rows = map.length;
    final cols = rows == 0 ? 0 : map.first.length;
    final cells = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        switch (map[r][c]) {
          case GridGenerator.tilePlayer: return CellType.player;
          case GridGenerator.tileWall:   return CellType.wall;
          case GridGenerator.tileEnemy:  return CellType.enemy;
          default:                       return CellType.empty;
        }
      });
    });
    return FloorGrid._(rows, cols, cells);
  }

  factory FloorGrid.fromGenerator(GridGenOptions o, {int? seed}) {
    final map = GridGenerator.generate(o, seed: seed);
    return FloorGrid.fromInts(map);
  }
  
  factory FloorGrid.sampleRoom() => FloorGrid.fromInts(const [
        [2,2,2,2,2,2,2,2],
        [2,2,2,2,2,2,2,2],
        [2,2,0,3,0,2,2,2],
        [2,2,0,0,0,2,2,2],
        [2,2,0,1,0,2,2,2],
        [2,2,2,2,2,2,2,2],
        [2,2,2,2,2,2,2,2],
        [2,2,2,2,2,2,2,2],
        [2,2,2,2,2,2,2,2],
      ]);

  CellType cell(int r, int c) => cells[r][c];
}
