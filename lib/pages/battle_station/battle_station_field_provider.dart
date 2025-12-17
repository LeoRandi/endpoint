import '_imports.dart';

class BattleStationFieldProvider {
  final Map<BattlerSide, List<Battler>> battlers;
  final Battler? startBattler;
  int mapIndex = 0;

  final ValueNotifier<Battler?> selectedBattlerNotifier;
  Grid? _currentGrid;

  BattleStationFieldProvider(this.battlers, {this.startBattler})
      : selectedBattlerNotifier = ValueNotifier<Battler?>(null);

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
          size: 12,
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

  void onTapBattleStationCell(GridObject gridObject) {
    final battlerObj = gridObject.objects[depthTileBase];
    if (battlerObj is BattlerObject) {
      setSelectedBattler(battlerObj.battler);
      return;
    }

    // If no battler was tapped, clear the selection and distance overlays.
    setSelectedBattler(null);
    final grid = _currentGrid ??
        (global.gridManager.isEmpty ? null : global.gridManager.models.first);
    if (grid != null) {
      DistanceManager.clearAllDistances(grid);
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
        grid = GridPopulatorBuilders.generatePathGridWithHorizontalRiver(
            gridSize);
      case 3:
        grid = GridPopulatorBuilders.generatePathGridWithVRiverAndChasmSquares(
            gridSize);
      case 4:
        grid = GridPopulatorBuilders.generateChasmWithBigPathChunksGrid(
            gridSize);
      default:
        grid = GridPopulatorBuilders.generateEmptyGrid(gridSize);
    }
    global.gridManager.models.add(grid);
    return grid;
  }
}
