import '_imports.dart';

class BattleStationButtons extends StatefulWidget {
  final BattleStationFieldProvider battleStationFieldProvider;
  final VoidCallback refresh;

  const BattleStationButtons(
    this.battleStationFieldProvider, {
    required this.refresh,
    super.key,
  });

  @override
  State<BattleStationButtons> createState() => _BattleStationButtonsState();
}

class _BattleStationButtonsState extends State<BattleStationButtons> {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomCenter,
      color: Colors.green,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0) +
            const EdgeInsets.only(bottom: 8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.greenAccent),
                  ),
                  onPressed: () {
                    global.gridManager.models.clear();
                    widget.battleStationFieldProvider.mapIndex = 1;
                    global.setPlayingBattler(global.battlerObjectManager.models
                        .firstWhere((bo) => bo.battler.side == BattlerSide.ally)
                        .battler);
                    widget.refresh();
                  },
                  child: TextWidget.medium('Map 1 - Ally Start'),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.redAccent),
                  ),
                  onPressed: () {
                    global.gridManager.models.clear();
                    widget.battleStationFieldProvider.mapIndex = 2;
                    global.setPlayingBattler(global.battlerObjectManager.models
                        .firstWhere(
                            (bo) => bo.battler.side == BattlerSide.enemy)
                        .battler);
                    widget.refresh();
                  },
                  child: TextWidget.medium('Map 2 - Enemy Start'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.blueAccent),
                  ),
                  onPressed: () {
                    global.gridManager.models.clear();
                    widget.battleStationFieldProvider.mapIndex = 3;
                    global.setPlayingBattler(global.battlerObjectManager.models
                        .firstWhere(
                            (bo) => bo.battler.side == BattlerSide.neutral,
                            orElse: () {
                      return global.battlerObjectManager.models.firstWhere(
                          (bo) => bo.battler.side == BattlerSide.ally);
                    }).battler);
                    widget.refresh();
                  },
                  child: TextWidget.medium('Map 3 - Neutral/Ally Start'),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.yellowAccent),
                  ),
                  onPressed: () {
                    global.gridManager.models.clear();
                    widget.battleStationFieldProvider.mapIndex = 4;
                    global.setPlayingBattler(global.battlerObjectManager.models
                        .firstWhere(
                            (bo) => bo.battler.side == BattlerSide.neutral,
                            orElse: () {
                      return global.battlerObjectManager.models.firstWhere(
                          (bo) => bo.battler.side == BattlerSide.enemy);
                    }).battler);
                    widget.refresh();
                  },
                  child: TextWidget.medium('Map 4 - Neutral/Enemy Start'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
