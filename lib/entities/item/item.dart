import '_imports.dart';

enum ItemId {
  woodenStick,
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
  final ItemId id;
  final String name;
  final String description;
  final String iconEmoji;
  final ItemSlot? slot;
  final RarityTier rarity;
  final int baseCost;
  final Map<BattlerStat, int> statModifiers;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    this.iconEmoji = '\u{1F9F0}',
    this.slot,
    this.rarity = RarityTier.gray,
    this.baseCost = 1,
    this.statModifiers = const {},
  });

  bool get isEquippable => slot != null;
  int get cost => baseCost * rarity.factor;

  int modifier(BattlerStat stat) {
    return statModifiers[stat] ?? 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
