import '_imports.dart';

class BattleStationFieldProvider {
  final Map<BattlerSide, List<Battler>> battlers;
  int mapIndex = 0;

  final ValueNotifier<Battler?> selectedBattlerNotifier;
  final ValueNotifier<Battler?> playingBattlerNotifier;

  BattleStationFieldProvider(this.battlers)
      : selectedBattlerNotifier = ValueNotifier<Battler?>(null),
        playingBattlerNotifier = ValueNotifier<Battler?>(null);

  void setSelectedBattler(Battler? battler) {
    selectedBattlerNotifier.value = battler;
  }

  void setPlayingBattler(Battler? battler) {
    playingBattlerNotifier.value = battler;
  }

  Widget getBattleField(BuildContext context, {required VoidCallback rebuild}) {
    const int width = 12;
    const int height = 12;

    final grid = getGrid(height, width);

    final ok = GridPopulator.populateBattlersAutoCorners(
      grid,
      width,
      height,
      battlers,
      offset: 1,
      areaFactor: 2.0,
    );

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
    switch (mapIndex) {
      case 0:
        return GridPopulatorBuilders.generateEmptyGrid(height, width);
      case 1:
        return GridPopulatorBuilders.generateRandomGrid(height, width);
      case 2:
        return GridPopulatorBuilders.generatePathGridWithHorizontalRiver(
            height, width);
      case 3:
        return GridPopulatorBuilders.generatePathGridWithVRiverAndChasmSquares(
            height, width);
      case 4:
        return GridPopulatorBuilders.generateChasmWithBigPathChunksGrid(
            height, width);
      default:
        return GridPopulatorBuilders.generateEmptyGrid(height, width);
    }
  }
}
