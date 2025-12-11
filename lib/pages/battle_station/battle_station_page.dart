import '_imports.dart';

class BattleStationPage extends StatefulWidget {
  late final BattleStationFieldProvider provider;
  BattleStationPage(Map<BattlerSide, List<Battler>> battlers, {super.key}) {
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
    final provider = widget.provider;

    return Column(
      children: [
        ValueListenableBuilder<Battler?>(
          valueListenable: provider.selectedBattlerNotifier,
          builder: (context, battler, _) {
            return BattleStationBattlerAppBar(battler);
          },
        ),
        Expanded(
          child: BattleStationField(widget.provider),
        ),
        ValueListenableBuilder<Battler?>(
          valueListenable: provider.playingBattlerNotifier,
          builder: (context, battler, _) {
            return SizedBox(
              height:
                  (MediaQuery.of(context).size.width ~/ 8).floor().toDouble(),
              child: BattlerEquipmentWidgetRow(battler: battler),
            );
          },
        ),
        BattleStationButtons(
          provider,
          refresh: () => setState(() {}),
        ),
      ],
    );
  }
}
