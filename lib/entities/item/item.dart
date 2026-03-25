import '_imports.dart';

enum ItemId {
  woodenStick,
  cyberWhips,
  sunglasses,
  shield,
  bulwarkAmulet,
  ironSword,
  guardShield,
  platedJacket,
  sunsteelBlade,
  dawnCharm,
  midnightCloak,
  voidInjector,
}

enum ItemSlot {
  weapon,
  offHand,
  accessory,
}

extension ItemSlotPresentation on ItemSlot {
  String get label {
    switch (this) {
      case ItemSlot.weapon:
        return 'Arma';
      case ItemSlot.offHand:
        return 'Soporte';
      case ItemSlot.accessory:
        return 'Accesorio';
    }
  }
}

class Item {
  static int _nextInstanceSequence = 0;

  final ItemId id;
  final String name;
  final String description;
  final String iconEmoji;
  final ItemSlot? slot;
  final RarityTier rarity;
  final Map<BattlerStat, int> statModifiers;
  final String? instanceId;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    this.iconEmoji = '\u{1F9F0}',
    this.slot,
    this.rarity = RarityTier.gray,
    this.statModifiers = const {},
    this.instanceId,
  });

  bool get isEquippable => slot != null;
  bool get isInstanced => instanceId != null;
  int get cost => rarity.shopPriceBase;

  int modifier(BattlerStat stat) {
    return statModifiers[stat] ?? 0;
  }

  Item toOwnedInstance() {
    if (isInstanced) return this;

    return Item(
      id: id,
      name: name,
      description: description,
      iconEmoji: iconEmoji,
      slot: slot,
      rarity: rarity,
      statModifiers: statModifiers,
      instanceId: 'item_${_nextInstanceSequence++}',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item &&
        instanceId != null &&
        other.instanceId != null &&
        other.instanceId == instanceId;
  }

  @override
  int get hashCode => instanceId?.hashCode ?? identityHashCode(this);
}
