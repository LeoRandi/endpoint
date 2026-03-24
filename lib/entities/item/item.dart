import '_imports.dart';

enum ItemId {
  woodenStick,
  ironSword,
  guardShield,
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
  final Map<BattlerStat, int> statModifiers;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    this.iconEmoji = '\u{1F9F0}',
    this.slot,
    this.statModifiers = const {},
  });

  bool get isEquippable => slot != null;

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
