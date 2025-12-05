import "_imports.dart";

class BattlerEquipmentWidget extends StatelessWidget {
  final Battler? battler;

  const BattlerEquipmentWidget({Key? key, required this.battler}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [        
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget.medium("Equipment:"),
            const SizedBox(height: 4),
            for (var equipment in battler?.equipmentList ?? [])
              TextWidget.small("- ${equipment.name}"),
          ],
        ),
      ],
    );
  }
}