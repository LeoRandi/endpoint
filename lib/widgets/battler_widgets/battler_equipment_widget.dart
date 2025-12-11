import "_imports.dart";

class BattlerEquipmentWidgetBox extends StatelessWidget {
  final Battler? battler;

  const BattlerEquipmentWidgetBox({Key? key, required this.battler})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [],
    );
  }
}

class BattlerEquipmentWidgetRow extends StatelessWidget {
  final Battler? battler;
  final double? size;

  const BattlerEquipmentWidgetRow({Key? key, required this.battler, this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (battler == null) return Container();

    final layout = battler?.equipmentLayout.layout ?? [];
    final finalSize =
        (size ?? (MediaQuery.of(context).size.width ~/ 8)).floor().toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: finalSize,
          height: finalSize,
          child: Stack(
            children: [
              Image.asset(layout[0].slotImage),
              // if(battler!.equipmentList[0].type == layout[0])
              Image.asset(battler!.equipmentList[0].imagePath)
            ],
          ),
        ),
        Container(
            width: finalSize,
            height: finalSize,
            child: Stack(
              children: [
                Image.asset(layout[1].slotImage),
                // if(battler!.equipmentList[0].type == layout[0])
                Image.asset(battler!.equipmentList[1].imagePath)
              ],
            )),
        Container(
          width: finalSize,
          height: finalSize,
          child: Stack(
            children: [
              Image.asset(layout[2].slotImage),
              // if(battler!.equipmentList[0].type == layout[0])
              Image.asset(battler!.equipmentList[2].imagePath)
            ],
          ),
        ),
        Container(
            width: finalSize,
            height: finalSize,
            child: Stack(
              children: [
                Image.asset(layout[3].slotImage),
                // if(battler!.equipmentList[0].type == layout[0])
                Image.asset(battler!.equipmentList[3].imagePath)
              ],
            )),
        Container(
          width: finalSize,
          height: finalSize,
          child: Stack(
            children: [
              Image.asset(layout[4].slotImage),
              // if(battler!.equipmentList[0].type == layout[0])
              Image.asset(battler!.equipmentList[4].imagePath)
            ],
          ),
        ),
        Container(
            width: finalSize,
            height: finalSize,
            child: Stack(
              children: [
                Image.asset(layout[5].slotImage),
                // if(battler!.equipmentList[0].type == layout[0])
                Image.asset(battler!.equipmentList[5].imagePath)
              ],
            )),
        Container(
          width: finalSize,
          height: finalSize,
          child: Stack(
            children: [
              Image.asset(layout[6].slotImage),
              // if(battler!.equipmentList[0].type == layout[0])
              Image.asset(battler!.equipmentList[6].imagePath)
            ],
          ),
        ),
        Container(
            width: finalSize,
            height: finalSize,
            child: Stack(
              children: [
                Image.asset(layout[7].slotImage),
                // if(battler!.equipmentList[0].type == layout[0])
                Image.asset(battler!.equipmentList[7].imagePath)
              ],
            )),
      ],
    );
  }
}

class BattlerEquipmentWidgetColumns extends StatelessWidget {
  final Battler? battler;
  final double? size;

  const BattlerEquipmentWidgetColumns(
      {Key? key, required this.battler, this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (battler == null) return Container();

    final layout = battler?.equipmentLayout.layout ?? [];
    final finalSize = (size ?? (MediaQuery.of(context).size.width ~/ 4) * 0.39)
        .floor()
        .toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: finalSize,
              height: finalSize,
              child: Stack(
                children: [
                  Image.asset(layout[0].slotImage),
                  // if(battler!.equipmentList[0].type == layout[0])
                  Image.asset(battler!.equipmentList[0].imagePath)
                ],
              ),
            ),
            Container(
                width: finalSize,
                height: finalSize,
                child: Stack(
                  children: [
                    Image.asset(layout[1].slotImage),
                    // if(battler!.equipmentList[0].type == layout[0])
                    Image.asset(battler!.equipmentList[1].imagePath)
                  ],
                )),
          ],
        ),
        Column(
          children: [
            Container(
              width: finalSize,
              height: finalSize,
              child: Stack(
                children: [
                  Image.asset(layout[2].slotImage),
                  // if(battler!.equipmentList[0].type == layout[0])
                  Image.asset(battler!.equipmentList[2].imagePath)
                ],
              ),
            ),
            Container(
                width: finalSize,
                height: finalSize,
                child: Stack(
                  children: [
                    Image.asset(layout[3].slotImage),
                    // if(battler!.equipmentList[0].type == layout[0])
                    Image.asset(battler!.equipmentList[3].imagePath)
                  ],
                )),
          ],
        ),
        Column(
          children: [
            Container(
              width: finalSize,
              height: finalSize,
              child: Stack(
                children: [
                  Image.asset(layout[4].slotImage),
                  // if(battler!.equipmentList[0].type == layout[0])
                  Image.asset(battler!.equipmentList[4].imagePath)
                ],
              ),
            ),
            Container(
                width: finalSize,
                height: finalSize,
                child: Stack(
                  children: [
                    Image.asset(layout[5].slotImage),
                    // if(battler!.equipmentList[0].type == layout[0])
                    Image.asset(battler!.equipmentList[5].imagePath)
                  ],
                )),
          ],
        ),
        Column(
          children: [
            Container(
              width: finalSize,
              height: finalSize,
              child: Stack(
                children: [
                  Image.asset(layout[6].slotImage),
                  // if(battler!.equipmentList[0].type == layout[0])
                  Image.asset(battler!.equipmentList[6].imagePath)
                ],
              ),
            ),
            Container(
                width: finalSize,
                height: finalSize,
                child: Stack(
                  children: [
                    Image.asset(layout[7].slotImage),
                    // if(battler!.equipmentList[0].type == layout[0])
                    Image.asset(battler!.equipmentList[7].imagePath)
                  ],
                )),
          ],
        ),
      ],
    );
  }
}
