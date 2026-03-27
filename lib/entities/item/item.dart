import '../_imports.dart';

/// Identifica cada tipo de objeto sin depender de la instancia concreta que posea el jugador.
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

/// Define los huecos equipables disponibles en el loadout del battler.
enum ItemSlot {
  weapon,
  offHand,
  accessory,
}

/// Traduce cada hueco interno al texto corto que se muestra en UI.
extension ItemSlotPresentation on ItemSlot {
  /// Devuelve el nombre legible del slot para paneles y tooltips.
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

/// Representa un objeto base o una copia poseida con stats, economia y efectos opcionales.
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

  /// Crea un item inmutable que puede actuar como preset compartido o copia poseida.
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

  /// Indica si el objeto puede equiparse en algun hueco.
  bool get isEquippable => slot != null;

  /// Indica si este objeto ya es una copia propia y no un preset compartido.
  bool get isInstanced => instanceId != null;

  /// Indica si el objeto tiene una logica activa mas alla de sus stats planos.
  bool get hasEffect => effect != null;

  /// Devuelve el coste base de compra segun la rareza del objeto.
  int get cost => rarity.shopPriceBase;

  /// Calcula el income que aporta el objeto a partir de su valor actual.
  int get incomeModifier => value * incomePerValueUnit;

  /// Calcula el modificador porcentual de vida maxima que aporta el objeto.
  int get maxHealthPercentModifier => value * maxHealthPercentPerValueUnit;

  /// Devuelve el modificador plano que este objeto aplica a una stat concreta.
  int modifier(BattlerStat stat) {
    return statModifiers[stat] ?? 0;
  }

  /// Sube el valor del objeto si el preset define una mejora disponible.
  Item upgraded() {
    if (upgradeValue <= 0) return this;

    return copyWith(value: value + upgradeValue);
  }

  /// Crea una copia parcial del objeto conservando el resto de propiedades intactas.
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

  /// Materializa un objeto de preset como copia propia para poder diferenciarlo por instancia.
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

  /// Compara objetos poseidos usando su id de instancia para no mezclar copias distintas.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item &&
        instanceId != null &&
        other.instanceId != null &&
        other.instanceId == instanceId;
  }

  /// Genera un hash estable para instancias propias y uno identitario para presets.
  @override
  int get hashCode => instanceId?.hashCode ?? identityHashCode(this);
}
