import '_imports.dart';

class DuelStationPage extends StatefulWidget {
  final DuelStationProvider provider;
  DuelStationPage(this.provider, {super.key});

  @override
  State<DuelStationPage> createState() => _DuelStationPageState();
}

class _DuelStationPageState extends State<DuelStationPage> {
  @override
  void initState() {
    super.initState();
    widget.provider.init();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top appbar showing active battlers
        DuelStationDuelistAppBar(
          enemyBattler: widget.provider.getActiveBattler(DuelistSide.enemy),
          allyBattler: widget.provider.getActiveBattler(DuelistSide.ally),
        ),
        // Enemy hand (below enemy appbar)
        DuelStationHand(
          hand: widget.provider.getStartingHand(DuelistSide.enemy),
          isPlayerHand: false,
        ),

        // Duel field (center)
        Expanded(
          child: DuelStationField(provider: widget.provider),
        ),

        // Ally hand (bottom)
        DuelStationHand(
          hand: widget.provider.getStartingHand(DuelistSide.ally),
          isPlayerHand: true,
        ),
      ],
    );
  }
}
