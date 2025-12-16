import '_imports.dart';

class BattleStationField extends StatefulWidget {
  final BattleStationFieldProvider battleStationFieldProvider;

  const BattleStationField(this.battleStationFieldProvider, {super.key});

  @override
  State<BattleStationField> createState() => _BattleStationFieldState();
}

class _BattleStationFieldState extends State<BattleStationField> {
  @override
  Widget build(BuildContext context) {
    return widget.battleStationFieldProvider.getBattleField(
      context,
      rebuild: () => setState(() {
        widget.battleStationFieldProvider.mapIndex = (widget.battleStationFieldProvider.mapIndex + 1) % 5;
      }),
    );
  }
}
