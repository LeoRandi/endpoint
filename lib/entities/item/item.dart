import '_imports.dart';

enum ItemId {
  woodenStick,
  cyberWhips,
  sunglasses,
  shield,
  bulwarkAmulet,
  crackedBattery,
  impactGloves,
  chemicalFilter,
  billingModule,
  portableOven,
  parasiticCapacitor,
  eclipseMantle,
  operativeBlackBox,
  ironSword,
  guardShield,
  platedJacket,
  sunsteelBlade,
  dawnCharm,
  midnightCloak,
  voidInjector,
  toxicCatalyst,
  emberCharm,
  reactiveCasing,
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
  final int value;
  final int upgradeValue;
  final int incomePerValueUnit;
  final int maxHealthPercentPerValueUnit;
  final Map<BattlerStat, int> statModifiers;
  final ItemEffect? effect;
  final String? instanceId;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    this.iconEmoji = '\u{1F9F0}',
    this.slot,
    this.rarity = RarityTier.gray,
    this.value = 0,
    this.upgradeValue = 0,
    this.incomePerValueUnit = 0,
    this.maxHealthPercentPerValueUnit = 0,
    this.statModifiers = const {},
    this.effect,
    this.instanceId,
  });

  bool get isEquippable => slot != null;
  bool get isInstanced => instanceId != null;
  bool get hasEffect => effect != null;
  int get cost => rarity.shopPriceBase;
  int get incomeModifier => value * incomePerValueUnit;
  int get maxHealthPercentModifier => value * maxHealthPercentPerValueUnit;

  int modifier(BattlerStat stat) {
    return statModifiers[stat] ?? 0;
  }

  Item upgraded() {
    if (upgradeValue <= 0) return this;

    return copyWith(value: value + upgradeValue);
  }

  Item copyWith({
    String? name,
    String? description,
    String? iconEmoji,
    ItemSlot? slot,
    bool clearSlot = false,
    RarityTier? rarity,
    int? value,
    int? upgradeValue,
    int? incomePerValueUnit,
    int? maxHealthPercentPerValueUnit,
    Map<BattlerStat, int>? statModifiers,
    ItemEffect? effect,
    bool clearEffect = false,
    String? instanceId,
  }) {
    return Item(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      slot: clearSlot ? null : slot ?? this.slot,
      rarity: rarity ?? this.rarity,
      value: value ?? this.value,
      upgradeValue: upgradeValue ?? this.upgradeValue,
      incomePerValueUnit: incomePerValueUnit ?? this.incomePerValueUnit,
      maxHealthPercentPerValueUnit:
          maxHealthPercentPerValueUnit ?? this.maxHealthPercentPerValueUnit,
      statModifiers: statModifiers ?? this.statModifiers,
      effect: clearEffect ? null : effect ?? this.effect,
      instanceId: instanceId ?? this.instanceId,
    );
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
      value: value,
      upgradeValue: upgradeValue,
      incomePerValueUnit: incomePerValueUnit,
      maxHealthPercentPerValueUnit: maxHealthPercentPerValueUnit,
      statModifiers: statModifiers,
      effect: effect,
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
