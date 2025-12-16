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
                    widget.refresh();
                  },
                  child: TextWidget.medium('Cost 10 Mana'),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.redAccent),
                  ),
                  onPressed: () {
                    global.gridManager.models.clear();
                    widget.battleStationFieldProvider.mapIndex = 2;
                    widget.refresh();
                  },
                  child: TextWidget.medium('Cost 20 Mana'),
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
                    widget.refresh();
                  },
                  child: TextWidget.medium('Cost 30 Mana'),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.yellowAccent),
                  ),
                  onPressed: () {
                    global.gridManager.models.clear();
                    widget.battleStationFieldProvider.mapIndex = 4;
                    widget.refresh();
                  },
                  child: TextWidget.medium('Cost 40 Mana'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
