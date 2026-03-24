import '_imports.dart';

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
    this.tileExtent = 70,
    this.tileHeight = 84,
    this.emojiSize = 18,
    this.spacing = 8,
    this.borderColor = const Color(0x335AF78E),
    this.backgroundColor = const Color(0x66030807),
    this.textColor = const Color(0xFFE6FFF0),
  });

  @override
  Widget build(BuildContext context) {
    final slots = layout == EndpointEquipmentLayout.standard
        ? const <_EndpointEquipmentVisualSlot>[
            _EndpointEquipmentVisualSlot.weapon,
            _EndpointEquipmentVisualSlot.armor,
            _EndpointEquipmentVisualSlot.accessory,
          ]
        : const <_EndpointEquipmentVisualSlot>[
            _EndpointEquipmentVisualSlot.generic,
          ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int index = 0; index < slots.length; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          SizedBox(
            width: tileExtent,
            height: tileHeight,
            child: _EndpointEquipmentSlotTile(
              item: _itemForSlot(slots[index]),
              slot: slots[index],
              emojiSize: emojiSize,
              borderColor: borderColor,
              backgroundColor: backgroundColor,
              textColor: textColor,
            ),
          ),
        ],
      ],
    );
  }

  Item? _itemForSlot(_EndpointEquipmentVisualSlot slot) {
    switch (slot) {
      case _EndpointEquipmentVisualSlot.weapon:
        return battler.equippedItemForSlot(ItemSlot.weapon);
      case _EndpointEquipmentVisualSlot.armor:
        return battler.equippedItemForSlot(ItemSlot.offHand);
      case _EndpointEquipmentVisualSlot.accessory:
        return battler.equippedItemForSlot(ItemSlot.accessory);
      case _EndpointEquipmentVisualSlot.generic:
        if (battler.equippedItems.isEmpty) return null;
        return battler.equippedItems.first;
    }
  }
}

class _EndpointEquipmentSlotTile extends StatelessWidget {
  final Item? item;
  final _EndpointEquipmentVisualSlot slot;
  final double emojiSize;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;

  const _EndpointEquipmentSlotTile({
    required this.item,
    required this.slot,
    required this.emojiSize,
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return HoldTooltip(
      message: item?.description ?? slot.label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 6),
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
              const SizedBox(height: 3),
              if (item != null)
                EndpointText(
                  item!.name,
                  textAlign: TextAlign.center,
                  style: textSmallBold.copyWith(
                    color: textColor,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                )
              else
                const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
