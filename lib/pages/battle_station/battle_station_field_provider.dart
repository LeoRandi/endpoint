import '_imports.dart';

class BattleStationFieldProvider {
  final Map<BattlerSide, List<Battler>> battlers;
  final Battler? startBattler;
  int mapIndex = 0;

  final ValueNotifier<Battler?> selectedBattlerNotifier;

  BattleStationFieldProvider(this.battlers, {this.startBattler})
      : selectedBattlerNotifier = ValueNotifier<Battler?>(null);

  void setSelectedBattler(Battler? battler) {
    selectedBattlerNotifier.value = battler;
  }

  Widget getBattleField(BuildContext context, {required VoidCallback rebuild}) {
    const int width = 12;
    const int height = 12;

    bool ok = true;

    late final Grid grid;
    if (global.gridManager.isEmpty) {
      grid = getGrid(height, width);

      ok = GridPopulator.populateBattlersAutoCorners(
        grid,
        width,
        height,
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

    ok = DistanceManager.addSelectedBattlerDistance(
        grid: grid,
        size: 12,
        selectedBattler: selectedBattlerNotifier.value,
        battlers: battlers);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int y = 0; y < height; y++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int x = 0; x < width; x++)
                Builder(
                  builder: (_) {
                    final gridObject = grid.gridObjectAt(x, y, width);

                    return BattleStationCell(
                      gridObject: gridObject!,
                      size: 24,
                      onTap: () {
                        final battlerObj = gridObject.objects[depthTileBase];
                        if (battlerObj is BattlerObject) {
                          setSelectedBattler(battlerObj.battler);
                        }
                      },
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }

  /// Before: TileGrid getTileGrid()
  /// Now: Grid getGrid()
  Grid getGrid(int height, int width) {
    late final Grid grid;
    switch (mapIndex) {
      case 0:
        grid = GridPopulatorBuilders.generateEmptyGrid(height, width);
      case 1:
        grid = GridPopulatorBuilders.generateRandomGrid(height, width);
      case 2:
        grid = GridPopulatorBuilders.generatePathGridWithHorizontalRiver(
            height, width);
      case 3:
        grid = GridPopulatorBuilders.generatePathGridWithVRiverAndChasmSquares(
            height, width);
      case 4:
        grid = GridPopulatorBuilders.generateChasmWithBigPathChunksGrid(
            height, width);
      default:
        grid = GridPopulatorBuilders.generateEmptyGrid(height, width);
    }
    global.gridManager.models.add(grid);
    return grid;
  }
}
