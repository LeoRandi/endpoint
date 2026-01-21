import '_imports.dart';

class DuelStationHand extends StatefulWidget {
  final bool isPlayerHand;
  final Hand hand;
  final bool isEnabled;

  DuelStationHand({
    required this.hand,
    required this.isPlayerHand,
    this.isEnabled = true,
    super.key,
  });

  @override
  State<DuelStationHand> createState() => _DuelStationHandState();
}

class _DuelStationHandState extends State<DuelStationHand> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: HAND_HEIGHT,
      width: double.infinity,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          for (var card in widget.hand)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: widget.isPlayerHand && widget.isEnabled
                  ? Draggable<BattleCard>(
                      data: card,
                      feedback: Material(
                        child: widget.isPlayerHand
                            ? BattleCardWidget.ally(battleCard: card)
                            : BattleCardWidget.enemy(battleCard: card),
                      ),
                      childWhenDragging: Opacity(
                        opacity: HAND_CARD_OPACITY_DRAGGING,
                        child: widget.isPlayerHand
                            ? BattleCardWidget.ally(battleCard: card)
                            : BattleCardWidget.enemy(battleCard: card),
                      ),
                      child: widget.isPlayerHand
                          ? BattleCardWidget.ally(battleCard: card)
                          : BattleCardWidget.enemy(battleCard: card),
                    )
                  : Opacity(
                      opacity: widget.isEnabled ? 1.0 : 0.5,
                      child: widget.isPlayerHand
                          ? BattleCardWidget.ally(battleCard: card)
                          : BattleCardWidget.enemy(battleCard: card),
                    ),
            ),
        ],
      ),
    );
  }
}
