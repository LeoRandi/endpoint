import '../_imports.dart';

enum EndpointEquipmentLayout {
  standard,
  generic,
}

enum _EndpointEquipmentVisualSlot {
  weapon,
  armor,
  accessory,
  generic,
}

extension _EndpointEquipmentVisualSlotPresentation
    on _EndpointEquipmentVisualSlot {
  String get label {
    switch (this) {
      case _EndpointEquipmentVisualSlot.weapon:
        return 'ARMA';
      case _EndpointEquipmentVisualSlot.armor:
        return 'ARMADURA';
      case _EndpointEquipmentVisualSlot.accessory:
        return 'AMULETO';
      case _EndpointEquipmentVisualSlot.generic:
        return 'SLOT';
    }
  }

  String get assetPath {
    switch (this) {
      case _EndpointEquipmentVisualSlot.weapon:
        return 'assets/images/slots/equipment_slot_weapon.png';
      case _EndpointEquipmentVisualSlot.armor:
        return 'assets/images/slots/equipment_slot_chest.png';
      case _EndpointEquipmentVisualSlot.accessory:
        return 'assets/images/slots/equipment_slot_accessory.png';
      case _EndpointEquipmentVisualSlot.generic:
        return 'assets/images/slots/empty_slot.png';
    }
  }
}

class EndpointEquipmentSlotsStrip extends StatelessWidget {
  final Battler battler;
  final EndpointEquipmentLayout layout;
  final ValueChanged<Item>? onItemPressed;
  final double tileExtent;
  final double tileHeight;
  final double emojiSize;
  final double spacing;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;

  const EndpointEquipmentSlotsStrip({
    super.key,
    required this.battler,
    this.layout = EndpointEquipmentLayout.standard,
    this.onItemPressed,
    this.tileExtent = 70,
    this.tileHeight = 84,
    this.emojiSize = 18,
    this.spacing = 8,
    this.borderColor = EndpointPalette.accentBorderSoft,
    this.backgroundColor = EndpointPalette.controlBackground,
    this.textColor = EndpointPalette.softForeground,
  });

  @override
  Widget build(BuildContext context) {
    final slots = _buildSlots();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int index = 0; index < slots.length; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          _buildSlotTile(slots[index]),
        ],
      ],
    );
  }

  Widget _buildSlotTile(_EndpointEquipmentSlotData slotData) {
    return SizedBox(
      width: tileExtent,
      height: tileHeight,
      child: _EndpointEquipmentSlotTile(
        item: slotData.item,
        slot: slotData.slot,
        emojiSize: emojiSize,
        borderColor: borderColor,
        backgroundColor: backgroundColor,
        textColor: textColor,
        onPressed: onItemPressed == null || slotData.item == null
            ? null
            : () => onItemPressed!.call(slotData.item!),
      ),
    );
  }

  List<_EndpointEquipmentSlotData> _buildSlots() {
    switch (layout) {
      case EndpointEquipmentLayout.standard:
        return [
          _EndpointEquipmentSlotData(
            slot: _EndpointEquipmentVisualSlot.weapon,
            item: battler.equippedItemForSlot(ItemSlot.weapon),
          ),
          _EndpointEquipmentSlotData(
            slot: _EndpointEquipmentVisualSlot.armor,
            item: battler.equippedItemForSlot(ItemSlot.offHand),
          ),
          _EndpointEquipmentSlotData(
            slot: _EndpointEquipmentVisualSlot.accessory,
            item: battler.equippedItemForSlot(ItemSlot.accessory),
          ),
        ];
      case EndpointEquipmentLayout.generic:
        if (battler.equippedItems.isEmpty) {
          return const [
            _EndpointEquipmentSlotData(
              slot: _EndpointEquipmentVisualSlot.generic,
            ),
          ];
        }

        return battler.equippedItems
            .map(
              (item) => _EndpointEquipmentSlotData(
                slot: _EndpointEquipmentVisualSlot.generic,
                item: item,
              ),
            )
            .toList(growable: false);
    }
  }
}

class _EndpointEquipmentSlotData {
  final _EndpointEquipmentVisualSlot slot;
  final Item? item;

  const _EndpointEquipmentSlotData({
    required this.slot,
    this.item,
  });
}

class _EndpointEquipmentSlotTile extends StatelessWidget {
  final Item? item;
  final _EndpointEquipmentVisualSlot slot;
  final double emojiSize;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;

  const _EndpointEquipmentSlotTile({
    required this.item,
    required this.slot,
    required this.emojiSize,
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor),
    );
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  slot.assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
                Center(
                  child: item == null
                      ? const SizedBox()
                      : EndpointText(
                          item!.iconEmoji,
                          style: TextStyle(
                            fontSize: emojiSize,
                            height: 1,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (item != null)
            EndpointText(
              item!.displayName,
              textAlign: TextAlign.center,
              style: textSmallBold.copyWith(
                color: textColor,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );

    return HoldTooltip(
      message: item?.tooltipDescription ?? slot.label,
      child: onPressed == null
          ? DecoratedBox(
              decoration: decoration,
              child: content,
            )
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: decoration,
                  child: content,
                ),
              ),
            ),
    );
  }
}
