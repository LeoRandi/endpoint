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

  const BattlerEquipmentWidgetRow({
    Key? key,
    required this.battler,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (battler == null) return Container();

    final battlerNonNull = battler!;
    final layout = battlerNonNull.equipmentLayout.layout;
    final equipment = battlerNonNull.equipmentList;
    final finalSize =
        (size ?? (MediaQuery.of(context).size.width ~/ 8)).floor().toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        8,
        (index) => _EquipmentSlot(
          size: finalSize,
          slotImage: layout[index].slotImage,
          equipmentImage: equipment[index].imagePath,
        ),
      ),
    );
  }
}

class BattlerEquipmentWidgetColumns extends StatelessWidget {
  final Battler? battler;
  final double? size;

  const BattlerEquipmentWidgetColumns({
    Key? key,
    required this.battler,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (battler == null) return Container();

    final battlerNonNull = battler!;
    final layout = battlerNonNull.equipmentLayout.layout;
    final equipment = battlerNonNull.equipmentList;
    final finalSize = (size ??
            (MediaQuery.of(context).size.width ~/ 4) * 0.39)
        .floor()
        .toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(4, (columnIndex) {
        final baseIndex = columnIndex * 2;
        return Column(
          children: [
            _EquipmentSlot(
              size: finalSize,
              slotImage: layout[baseIndex].slotImage,
              equipmentImage: equipment[baseIndex].imagePath,
            ),
            _EquipmentSlot(
              size: finalSize,
              slotImage: layout[baseIndex + 1].slotImage,
              equipmentImage: equipment[baseIndex + 1].imagePath,
            ),
          ],
        );
      }),
    );
  }
}

class _EquipmentSlot extends StatelessWidget {
  final double size;
  final String slotImage;
  final String equipmentImage;

  const _EquipmentSlot({
    Key? key,
    required this.size,
    required this.slotImage,
    required this.equipmentImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Image.asset(slotImage),
          Image.asset(equipmentImage),
        ],
      ),
    );
  }
}
