import '_imports.dart';

enum CardSide { front, back }

class BattleCardWidget extends StatelessWidget {
  final BattleCard battleCard;
  final CardSide side;
  final Color color;

  BattleCardWidget(
      {required this.battleCard, required this.side, required this.color});

  BattleCardWidget.enemy(
      {required BattleCard battleCard, Color? color})
      : this.battleCard = battleCard,
        this.side = CardSide.back,
        this.color = Color.fromARGB(255, 64, 60, 75);

  
  BattleCardWidget.ally(
      {required BattleCard battleCard, Color? color})
      : this.battleCard = battleCard,
        this.side = CardSide.front,
        this.color = Color.fromARGB(255, 83, 122, 90);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: BattleCardContainerWidget(battleCard: battleCard, side: side),
    );
  }
}

class BattleCardContainerWidget extends StatelessWidget {
  final BattleCard battleCard;
  final CardSide side;

  BattleCardContainerWidget({required this.battleCard, required this.side});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: BATTLE_CARD_WIDTH,
      child: side == CardSide.front
          ? Column(
              children: [
                Text(battleCard.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: BATTLE_CARD_TITLE_FONT_SIZE, fontWeight: FontWeight.bold)),
                SizedBox(height: BATTLE_CARD_SPACING),
                Text('A: ${battleCard.might}', style: TextStyle(fontSize: BATTLE_CARD_ATTACK_FONT_SIZE)),
                Text(battleCard.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: BATTLE_CARD_DESCRIPTION_FONT_SIZE)),
              ],
            )
          : Center(
              child: Text('Back',
                  style: TextStyle(fontSize: BATTLE_CARD_BACK_FONT_SIZE, fontStyle: FontStyle.italic)),
            ),
    );
  }
}
