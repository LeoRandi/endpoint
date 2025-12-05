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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.greenAccent),
                ),
                onPressed: () {
                  widget.battleStationFieldProvider.cast(10);
                  widget.refresh();
                },
                child: TextWidget.medium('Cost 10 Mana'),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.redAccent),
                ),
                onPressed: () {
                  widget.battleStationFieldProvider.cast(20);
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
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent),
                ),
                onPressed: () {
                  widget.battleStationFieldProvider.cast(30);
                  widget.refresh();
                },
                child: TextWidget.medium('Cost 30 Mana'),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.yellowAccent),
                ),
                onPressed: () {
                  widget.battleStationFieldProvider.cast(40);
                  widget.refresh();
                },
                child: TextWidget.medium('Cost 40 Mana'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
