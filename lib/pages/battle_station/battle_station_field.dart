import '_imports.dart';

class BattleStationField extends StatefulWidget {
  final BattleStationFieldProvider battleStationFieldProvider;

  const BattleStationField(this.battleStationFieldProvider, {super.key});

  @override
  State<BattleStationField> createState() => _BattleStationFieldState();
}

class _BattleStationFieldState extends State<BattleStationField> {
  @override
  Widget build(BuildContext context) {
    final grid = MapGenerator.generateMap(16, 16);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int y = 0; y < grid.height; y++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int x = 0; x < grid.width; x++)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Image.asset(grid.tileAt(x, y).imagePath),
                ),
            ],
          ),
      ],
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Column(
  //     children: [
  //       Expanded(
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //           children: widget
  //               .battleStationFieldProvider.battlers[BattlerSide.ally]!
  //               .map((battler) => Padding(
  //                     padding: const EdgeInsets.all(8.0),
  //                     child: Column(
  //                       children: [
  //                         Image.asset(battler.imagePath, width: 64, height: 64),
  //                         Text(battler.name),
  //                         HpBar(
  //                             currentHp: battler.health,
  //                             maxHp: battler.maxHealth),
  //                       ],
  //                     ),
  //                   ))
  //               .toList(),
  //         ),
  //       ),
  //       Expanded(
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //           children: widget
  //               .battleStationFieldProvider.battlers[BattlerSide.enemy]!
  //               .map((battler) => Padding(
  //                     padding: const EdgeInsets.all(8.0),
  //                     child: Column(
  //                       children: [
  //                         Image.asset(battler.imagePath, width: 64, height: 64),
  //                         Text(battler.name),
  //                         HpBar(
  //                             currentHp: battler.health,
  //                             maxHp: battler.maxHealth),
  //                       ],
  //                     ),
  //                   ))
  //               .toList(),
  //         ),
  //       )
  //     ],
  //   );
  // }
}
