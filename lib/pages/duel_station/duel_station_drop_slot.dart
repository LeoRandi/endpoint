import '_imports.dart';

class DuelStationDropSlot extends StatelessWidget {
  final DuelistSide side;
  final bool isEnabled;
  final Function(BattleCard)? onCardDropped;

  DuelStationDropSlot({
    required this.side,
    this.isEnabled = true,
    this.onCardDropped,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEnabled) {
      return _buildDisabledSlot();
    }

    return DragTarget<BattleCard>(
      onAccept: (card) {
        onCardDropped?.call(card);
      },
      onWillAccept: (card) => side == DuelistSide.ally,
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: DROP_SLOT_WIDTH,
          height: DROP_SLOT_HEIGHT,
          decoration: BoxDecoration(
            border: Border.all(
              color: candidateData.isNotEmpty ? Colors.yellow : Colors.grey,
              width: DROP_SLOT_BORDER_WIDTH,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
            color: candidateData.isNotEmpty
                ? Colors.yellow.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  size: DROP_SLOT_ICON_SIZE,
                  color: candidateData.isNotEmpty ? Colors.yellow : Colors.grey,
                ),
                SizedBox(height: DROP_SLOT_ICON_SPACING),
                Text(
                  'Drop\nCard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: DROP_SLOT_TEXT_FONT_SIZE,
                    color: candidateData.isNotEmpty ? Colors.yellow : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDisabledSlot() {
    return Container(
      width: DROP_SLOT_WIDTH,
      height: DROP_SLOT_HEIGHT,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: DROP_SLOT_BORDER_WIDTH,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.withOpacity(0.05),
      ),
      child: const Center(
        child: Icon(
          Icons.lock,
          size: DROP_SLOT_ICON_SIZE,
          color: Colors.grey,
        ),
      ),
    );
  }
}
