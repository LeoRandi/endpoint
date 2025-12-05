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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget.medium("Name: ${battler?.name ?? "???"}"),
            const SizedBox(width: 8),
            TextWidget.medium("Class: ${battler?.mainClass ?? "???"}"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget.medium("Attack Power: ${battler?.attackPower ?? "???"}"),
            const SizedBox(width: 8),
            TextWidget.medium("Class: ${battler?.mainClass ?? "???"}"),
          ],
        ),
      ],
    );
  }
}