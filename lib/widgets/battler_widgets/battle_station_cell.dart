import '_imports.dart';

class BattleStationCell extends StatelessWidget {
  final Tile tile;
  final Battler battler;
  final double size;
  final VoidCallback? onTap;

  const BattleStationCell({
    Key? key,
    required this.tile,
    required this.battler,
    this.size = 24,
    this.onTap,
  }) : super(key: key);

  bool get hasBattler => battler.name.isNotEmpty; // or battler.isVoid == false

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasBattler ? onTap : null,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Image.asset(tile.imagePath),
            if (hasBattler) Image.asset(battler.imagePath), 
            // ^ adapt this line to however you build the battler sprite:
            // e.g. Image.asset(battler.imagePath) or a method on BattlerGrid.
          ],
        ),
      ),
    );
  }
}
