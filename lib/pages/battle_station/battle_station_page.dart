import '_imports.dart';

class BattleStationPage extends StatefulWidget {
  late final BattleStationFieldProvider provider;
  BattleStationPage(Map<BattlerSide, List<Battler>> battlers, {super.key}){
    provider = BattleStationFieldProvider(battlers);
  }

  @override
  State<BattleStationPage> createState() => _BattleStationPageState();
}

class _BattleStationPageState extends State<BattleStationPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BattleStationBattlerAppBar(widget.provider.battlers.allyBattlers.selectedBattler),
        Expanded(
          child: BattleStationField(widget.provider),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: BattleStationButtons(
            widget.provider,
            refresh: () => setState(() {}),
          ),
        ),
      ],
    );
  }
}

