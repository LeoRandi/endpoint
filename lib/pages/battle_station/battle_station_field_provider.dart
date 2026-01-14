import '_imports.dart';

class BattleStationFieldProvider {
  final Map<BattlerSide, List<Battler>> battlers;
  final Battler? startBattler;
  
  int mapIndex = 0;

  final ValueNotifier<Battler?> selectedBattlerNotifier;
  VoidCallback? _refresh;

  Grid? _currentGrid;

  BattlerObject? _selectedBattlerObject;

  void setSelectedBattlerObject(BattlerObject? bo) {
    _selectedBattlerObject = bo;
    selectedBattlerNotifier.value = bo?.battler;
  }

  BattleStationFieldProvider(this.battlers, {this.startBattler})
      : selectedBattlerNotifier = ValueNotifier<Battler?>(null);

  void attachRefresh(VoidCallback refresh) => _refresh = refresh;

  void _tick() => _refresh?.call();


  void setSelectedBattler(Battler? battler) {
    selectedBattlerNotifier.value = battler;
  }

  Widget getBattleField(BuildContext context, {required VoidCallback rebuild}) {
    bool ok = true;

    late final Grid grid;
    if (global.gridManager.isEmpty) {
      grid = getGrid(global.gridSize);

      ok = GridPopulator.populateBattlersAutoCorners(
        grid,
        global.gridSize,
        battlers,
        offset: 1,
        areaFactor: 2.0,
      );
    } else {
      grid = global.gridManager.models.first;
    }

    if (!ok) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // avoid stacking dialogs
        if (ModalRoute.of(context)?.isCurrent != true) return;

        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Uh oh! Something terrible happened"),
            content: const Text(
              "I couldn't place battlers on this map.\nTry rebuilding to generate a new one.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  rebuild();
                },
                child: const Text("Rebuild"),
              ),
            ],
          ),
        );
      });
    }

    _currentGrid = grid;

    ok = DistanceManager.addSelectedBattlerDistance(
        grid: grid,
        size: global.gridSize,
        selectedBattler: selectedBattlerNotifier.value,
        battlers: battlers);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int y = 0; y < global.gridSize; y++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int x = 0; x < global.gridSize; x++)
                Builder(
                  builder: (_) {
                    final gridObject = grid.gridObjectAt(x, y, global.gridSize);

                    return BattleStationCell(
                      gridObject: gridObject!,
                      size: 24,
                      onTap: () => onTapBattleStationCell(gridObject),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }

  void onTapBattleStationCell(GridObject gridObject) async {
    final battlerObj = gridObject.objects[depthTileBase];
    if (battlerObj is BattlerObject) {
      setSelectedBattlerObject(battlerObj);
      return;
    }

    await moveToGrid(gridObject);

    final grid = _currentGrid ??
        (global.gridManager.isEmpty ? null : global.gridManager.models.first);
    if (grid != null) {
      DistanceManager.clearAllDistances(grid);
    }
  }

  Future<void> moveToGrid(GridObject destinationGridObject) async {
    final selectedBo = _selectedBattlerObject;
    if (selectedBo == null) return;
    
    setSelectedBattlerObject(null);

    final grid = _currentGrid ??
        (global.gridManager.isEmpty ? null : global.gridManager.models.first);
    if (grid == null) return;

    // No moverse a una celda ocupada
    if (destinationGridObject.objects[depthTileBase] != null) return;

    // Solo si hay overlay de distancia y es el battler del jugador
    if (destinationGridObject.objects[depthAbove] == null) return;

    final isPlayerBattler =
        selectedBo.battler.name == global.playingBattlerNotifier.value?.name;
    if (!isPlayerBattler) return;

    // Origen por coords del BattlerObject (sin escanear)
    final originGO =
        grid.gridObjectAt(selectedBo.x, selectedBo.y, global.gridSize);
    if (originGO == null) return;

    // Seguridad: confirmar que el objeto en origen es el mismo BattlerObject
    final originObj = originGO.objects[depthTileBase];
    if (!identical(originObj, selectedBo)) return;

    final path = BattlerMover.calculateClosestPath(
      grid,
      originGO,
      destinationGridObject,
      global.gridSize,
    );

    DistanceManager.clearAllDistances(grid);
    _tick();

    final int maxSteps =
    selectedBo.battler.getStat(BattlerStatsType.speed).clamp(1, 999);

    final int msPerStep = (1000 / maxSteps).round().clamp(60, 500);

    for (int i = 1; i < path.length; i++) {
      final currentGO = path[i - 1];
      final nextGO = path[i];

      BattlerMover.moveToTargetGrid(
        grid,
        currentGO,
        nextGO,
        depthTileBase,
      );


      // El BattlerObject debería ser la misma instancia movida al nextGO
      final moved = nextGO.objects[depthTileBase];
      if (moved is BattlerObject && identical(moved, selectedBo)) {
        moved.x = nextGO.x;
        moved.y = nextGO.y;
      } else {
        break; // algo se desincronizó; mejor cortar
      }

      await Future.delayed(Duration(milliseconds: msPerStep));
      _tick();
    }
  }


  /// Before: TileGrid getTileGrid()
  /// Now: Grid getGrid()
  Grid getGrid(int gridSize) {
    late final Grid grid;
    switch (mapIndex) {
      case 0:
        grid = GridPopulatorBuilders.generateEmptyGrid(gridSize);
      case 1:
        grid = GridPopulatorBuilders.generateRandomGrid(gridSize);
      case 2:
        grid =
            GridPopulatorBuilders.generatePathGridWithHorizontalRiver(gridSize);
      case 3:
        grid = GridPopulatorBuilders.generatePathGridWithVRiverAndChasmSquares(
            gridSize);
      case 4:
        grid =
            GridPopulatorBuilders.generateChasmWithBigPathChunksGrid(gridSize);
      default:
        grid = GridPopulatorBuilders.generateEmptyGrid(gridSize);
    }
    global.gridManager.models.add(grid);
    return grid;
  }
}
