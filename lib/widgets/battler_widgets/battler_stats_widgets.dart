import "_imports.dart";

class BattlerStatsWidget extends StatelessWidget {
  final Battler? battler;

  const BattlerStatsWidget({Key? key, required this.battler}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextWidget.medium(battler?.name ?? "???"), // name,
            Image.asset(
              battler?.mainClassIconPath ??
                  "assets/images/slots/empty_slot.png",
              height: 16,
              width: 16,
            ), // class,
            Image.asset(
              battler?.subClassIconPath ?? "assets/images/slots/empty_slot.png",
              height: 16,
              width: 16,
            ), // subclass,
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            BattlerStatWidget(
                // defense,
                imagePath: BattlerStatsType.defense
                    .getStatIconPath(BattlerStatsType.defense),
                statValue: battler?.calculatedStats[BattlerStatsType.defense]
                        ?.toString() ??
                    "0"),
            BattlerStatWidget(
                // magicDefense,
                imagePath: BattlerStatsType.magicDefense
                    .getStatIconPath(BattlerStatsType.magicDefense),
                statValue: battler
                        ?.calculatedStats[BattlerStatsType.magicDefense]
                        ?.toString() ??
                    "0"),
            BattlerStatWidget(
                // dodge,
                imagePath: BattlerStatsType.dodge
                    .getStatIconPath(BattlerStatsType.dodge),
                statValue: battler?.calculatedStats[BattlerStatsType.dodge]
                        ?.toString() ??
                    "0"),
            BattlerStatWidget(
                // magicDodge,
                imagePath: BattlerStatsType.magicDodge
                    .getStatIconPath(BattlerStatsType.magicDodge),
                statValue: battler?.calculatedStats[BattlerStatsType.magicDodge]
                        ?.toString() ??
                    "0"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            BattlerStatWidget(
                // strength,
                imagePath: BattlerStatsType.strength
                    .getStatIconPath(BattlerStatsType.strength),
                statValue: battler?.calculatedStats[BattlerStatsType.strength]
                        ?.toString() ??
                    "0"),
            BattlerStatWidget(
                // magic,
                imagePath: BattlerStatsType.magic
                    .getStatIconPath(BattlerStatsType.magic),
                statValue: battler?.calculatedStats[BattlerStatsType.magic]
                        ?.toString() ??
                    "0"),
            BattlerStatWidget(
                // speed,
                imagePath: BattlerStatsType.speed
                    .getStatIconPath(BattlerStatsType.speed),
                statValue: battler?.calculatedStats[BattlerStatsType.speed]
                        ?.toString() ??
                    "0"),
            BattlerStatWidget(
                // luck,
                imagePath: BattlerStatsType.luck
                    .getStatIconPath(BattlerStatsType.luck),
                statValue: battler?.calculatedStats[BattlerStatsType.luck]
                        ?.toString() ??
                    "0"),
          ],
        ),
        Container(
          height: 1,
          color: Colors.black,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            BattlerStatWidget(
                // sword,
                imagePath: BattlerStatsType.sword
                    .getStatIconPath(BattlerStatsType.sword),
                statValue: battler?.calculatedStats[BattlerStatsType.sword]
                        ?.toString() ??
                    "0"),
            BattlerStatWidget(
                // spear,
                imagePath: BattlerStatsType.spear
                    .getStatIconPath(BattlerStatsType.spear),
                statValue: battler?.calculatedStats[BattlerStatsType.spear]
                        ?.toString() ??
                    "0"),
            BattlerStatWidget(
                // axe,
                imagePath:
                    BattlerStatsType.axe.getStatIconPath(BattlerStatsType.axe),
                statValue: battler?.calculatedStats[BattlerStatsType.axe]
                        ?.toString() ??
                    "0"),
            BattlerStatWidget(
                // hammer,
                imagePath: BattlerStatsType.hammer
                    .getStatIconPath(BattlerStatsType.hammer),
                statValue: battler?.calculatedStats[BattlerStatsType.hammer]
                        ?.toString() ??
                    "0"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            BattlerStatWidget(
                // dagger,
                imagePath: BattlerStatsType.dagger
                    .getStatIconPath(BattlerStatsType.dagger),
                statValue: battler?.calculatedStats[BattlerStatsType.dagger]
                        ?.toString() ??
                    "0"),
            BattlerStatWidget(
                // unarmed,
                imagePath: BattlerStatsType.unarmed
                    .getStatIconPath(BattlerStatsType.unarmed),
                statValue: battler?.calculatedStats[BattlerStatsType.unarmed]
                        ?.toString() ??
                    "0"),
            BattlerStatWidget(
                // shield,
                imagePath: BattlerStatsType.shield
                    .getStatIconPath(BattlerStatsType.shield),
                statValue: battler?.calculatedStats[BattlerStatsType.shield]
                        ?.toString() ??
                    "0"),
            BattlerStatWidget(
                // bow,
                imagePath:
                    BattlerStatsType.bow.getStatIconPath(BattlerStatsType.bow),
                statValue: battler?.calculatedStats[BattlerStatsType.bow]
                        ?.toString() ??
                    "0"),
          ],
        ),
      ],
    );
  }
}

class BattlerStatWidget extends StatelessWidget {
  final String imagePath;
  final String statValue;

  const BattlerStatWidget(
      {Key? key, required this.imagePath, required this.statValue})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Image.asset(imagePath, height: 16, width: 16),
        Text(": $statValue"),
      ],
    );
  }
}
