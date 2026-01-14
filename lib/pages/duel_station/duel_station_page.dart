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
  }

  @override
  Widget build(BuildContext context) {

    widget.provider.init();

    // final provider = widget.provider;
    // provider.attachRefresh(() {
    //   if (mounted) setState(() {});
    // });

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DuelStationHand(hand: widget.provider.getStartingHand(DuelistSide.enemy), isPlayerHand: false),

        DuelStationHand(hand: widget.provider.getStartingHand(DuelistSide.ally), isPlayerHand: true)
      ],
    );
  }
}
