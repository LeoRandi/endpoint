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
      height: 120,
      width: 80,
      child: side == CardSide.front
          ? Column(
              children: [
                Text(battleCard.name,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('Attack: ${battleCard.might}'),
                Text('Description: ${battleCard.description}'),
              ],
            )
          : Center(
              child: Text('Card Back',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
            ),
    );
  }
}
