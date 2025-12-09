import "_imports.dart";

class BattleStationBattlerAppBar extends StatelessWidget {
  final Battler? battler;

  const BattleStationBattlerAppBar(this.battler, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: battler?.side.getColor() ?? Colors.grey,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.39,
              child: BattlerStatsWidget(battler: battler),
            ),
            const SizedBox(width: 4),
            Image.asset(battler?.imagePath ?? "assets/sprites/unknown.png", width: 48, height: 48),
            const SizedBox(width: 4),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.39,
              child: HpBar(currentHp: battler?.health ?? 0, maxHp: battler?.maxHealth ?? 1),
            ),
          ],
        ),
      ),
    );
  }

}