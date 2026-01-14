import '_imports.dart';

class DuelStationHand extends StatefulWidget {
  final bool isPlayerHand;
  final Hand hand;

  DuelStationHand({required this.hand, required this.isPlayerHand, super.key});

  @override
  State<DuelStationHand> createState() => _DuelStationHandState();
}

class _DuelStationHandState extends State<DuelStationHand> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (var card in widget.hand)
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: widget.isPlayerHand
                ? BattleCardWidget.ally(battleCard: card)
                : BattleCardWidget.enemy(battleCard: card),
          ),
      ]),
    );
  }
}
