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
        return 'Armadura';
      case ItemSlot.accessory:
        return 'Accesorio';
    }
  }
}

/// Representa un objeto base o una copia poseida con stats, economia y efectos opcionales.
class Item {
  static int _nextInstanceSequence = 0;

  final ItemId id;
  final List<EntityTag> tags;
  final String name;
  final String description;
  final String iconEmoji;
  final ItemSlot? slot;
  final RarityTier rarity;
  final int baseCost;
  final int value;
  final int upgradeValue;
  final int incomePerValueUnit;
  final int maxHealthPercentPerValueUnit;
  final Map<BattlerStat, int> statModifiers;
  final Map<BattlerStat, int> upgradeStatModifiers;
  final ItemEffect? effect;
  final String? instanceId;

  /// Crea un item inmutable que puede actuar como preset compartido o copia poseida.
  const Item({
    required this.id,
    this.tags = const [],
    required this.name,
    required this.description,
    this.iconEmoji = '\u{1F9F0}',
    this.slot,
    this.rarity = RarityTier.gray,
    required this.baseCost,
    this.value = 0,
    this.upgradeValue = 0,
    this.incomePerValueUnit = 0,
    this.maxHealthPercentPerValueUnit = 0,
    this.statModifiers = const {},
    this.upgradeStatModifiers = const {},
    this.effect,
    this.instanceId,
  });

  /// Indica si el objeto puede equiparse en algun hueco.
  bool get isEquippable => slot != null;

  /// Indica si este objeto ya es una copia propia y no un preset compartido.
  bool get isInstanced => instanceId != null;

  /// Indica si el objeto tiene una logica activa mas alla de sus stats planos.
  bool get hasEffect => effect != null;

  /// Indica si el objeto tiene al menos una tag util para filtros y UI.
  bool get hasTags => tags.isNotEmpty;

  /// Comprueba si este objeto pertenece a una tag concreta.
  bool hasTag(EntityTag tag) => tags.contains(tag);

  /// Indica si este objeto puede mejorar al recibir una copia adicional.
  bool get canUpgrade => upgradeValue > 0 || upgradeStatModifiers.isNotEmpty;

  /// Devuelve el coste base propio del objeto para compra y reventa.
  int get cost => baseCost;

  /// Calcula el income que aporta el objeto a partir de su valor actual.
  int get incomeModifier => value * incomePerValueUnit;

  /// Calcula el modificador porcentual de vida maxima que aporta el objeto.
  int get maxHealthPercentModifier => value * maxHealthPercentPerValueUnit;

  /// Devuelve el modificador plano que este objeto aplica a una stat concreta.
  int modifier(BattlerStat stat) {
    return statModifiers[stat] ?? 0;
  }

  /// Indica cuantas mejoras visibles lleva esta copia respecto a su preset base.
  int get upgradeCount {
    if (upgradeValue <= 0) return 0;

    final baseValue = presetForId(id).value;
    if (value <= baseValue) return 0;

    return max(0, (value - baseValue) ~/ upgradeValue);
  }

  /// Devuelve el nombre visible incluyendo el sufijo de mejora cuando proceda.
  String get displayName {
    if (upgradeCount <= 0) return name;

    return '$name +$upgradeCount';
  }

  /// Genera una descripcion visible que refleja mejor los valores ya mejorados.
  String get displayDescription {
    if (upgradeCount <= 0) return description;

    final entries = _modifierDescriptionEntries();
    if (entries.isEmpty) {
      return effect?.descriptionFor(this) ?? description;
    }

    return entries.join('. ');
  }

  /// Devuelve una descripcion compacta para tooltips, incluyendo el efecto si procede.
  String get tooltipDescription {
    if (upgradeCount <= 0) return description;

    final entries = _modifierDescriptionEntries();
    if (effect != null) {
      entries.add(effect!.descriptionFor(this));
    }

    if (entries.isEmpty) return description;

    return entries.join('. ');
  }

  List<String> _modifierDescriptionEntries() {
    final entries = <String>[
      ...statModifiers.entries.map((entry) {
        final value = entry.value;
        final sign = value >= 0 ? '+' : '';
        return '$sign$value ${_statLabel(entry.key)}';
      }),
    ];

    if (incomeModifier != 0) {
      final sign = incomeModifier >= 0 ? '+' : '';
      entries.add('$sign$incomeModifier INCOME');
    }

    if (maxHealthPercentModifier != 0) {
      final sign = maxHealthPercentModifier >= 0 ? '+' : '';
      entries.add('$sign$maxHealthPercentModifier% HP MAX');
    }

    return entries;
  }

  /// Sube el valor del objeto si el preset define una mejora disponible.
  Item upgraded() {
    final upgradeTemplate = canUpgrade ? this : presetForId(id);
    if (!upgradeTemplate.canUpgrade) return this;

    final updatedStatModifiers = Map<BattlerStat, int>.from(statModifiers);
    for (final entry in upgradeTemplate.upgradeStatModifiers.entries) {
      updatedStatModifiers.update(
        entry.key,
        (currentValue) => currentValue + entry.value,
        ifAbsent: () => entry.value,
      );
    }

    return copyWith(
      tags: upgradeTemplate.tags,
      name: upgradeTemplate.name,
      description: upgradeTemplate.description,
      iconEmoji: upgradeTemplate.iconEmoji,
      rarity: upgradeTemplate.rarity,
      baseCost: upgradeTemplate.baseCost,
      value: value + upgradeTemplate.upgradeValue,
      upgradeValue: upgradeTemplate.upgradeValue,
      incomePerValueUnit: upgradeTemplate.incomePerValueUnit,
      maxHealthPercentPerValueUnit: upgradeTemplate.maxHealthPercentPerValueUnit,
      statModifiers: updatedStatModifiers,
      upgradeStatModifiers: upgradeTemplate.upgradeStatModifiers,
      effect: upgradeTemplate.effect,
    );
  }

  /// Crea una copia parcial del objeto conservando el resto de propiedades intactas.
  Item copyWith({
    List<EntityTag>? tags,
    String? name,
    String? description,
    String? iconEmoji,
    ItemSlot? slot,
    bool clearSlot = false,
    RarityTier? rarity,
    int? baseCost,
    int? value,
    int? upgradeValue,
    int? incomePerValueUnit,
    int? maxHealthPercentPerValueUnit,
    Map<BattlerStat, int>? statModifiers,
    Map<BattlerStat, int>? upgradeStatModifiers,
    ItemEffect? effect,
    bool clearEffect = false,
    String? instanceId,
  }) {
    return Item(
      id: id,
      tags: tags ?? this.tags,
      name: name ?? this.name,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      slot: clearSlot ? null : slot ?? this.slot,
      rarity: rarity ?? this.rarity,
      baseCost: baseCost ?? this.baseCost,
      value: value ?? this.value,
      upgradeValue: upgradeValue ?? this.upgradeValue,
      incomePerValueUnit: incomePerValueUnit ?? this.incomePerValueUnit,
      maxHealthPercentPerValueUnit:
          maxHealthPercentPerValueUnit ?? this.maxHealthPercentPerValueUnit,
      statModifiers: statModifiers ?? this.statModifiers,
      upgradeStatModifiers: upgradeStatModifiers ?? this.upgradeStatModifiers,
      effect: clearEffect ? null : effect ?? this.effect,
      instanceId: instanceId ?? this.instanceId,
    );
  }

  /// Materializa un objeto de preset como copia propia para poder diferenciarlo por instancia.
  Item toOwnedInstance() {
    if (isInstanced) return this;

    return Item(
      id: id,
      tags: tags,
      name: name,
      description: description,
      iconEmoji: iconEmoji,
      slot: slot,
      rarity: rarity,
      baseCost: baseCost,
      value: value,
      upgradeValue: upgradeValue,
      incomePerValueUnit: incomePerValueUnit,
      maxHealthPercentPerValueUnit: maxHealthPercentPerValueUnit,
      statModifiers: statModifiers,
      upgradeStatModifiers: upgradeStatModifiers,
      effect: effect,
      instanceId: 'item_${_nextInstanceSequence++}',
    );
  }

  /// Recupera el preset canonico asociado al id estable del objeto.
  static Item presetForId(ItemId id) {
    for (final item in itemPresets) {
      if (item.id == id) return item;
    }

    throw StateError('No existe preset para el objeto ${id.name}.');
  }

  static String _statLabel(BattlerStat stat) {
    switch (stat) {
      case BattlerStat.health:
        return 'HP';
      case BattlerStat.attack:
        return 'ATK';
      case BattlerStat.defense:
        return 'DEF';
      case BattlerStat.thorns:
        return 'THORNS';
      case BattlerStat.damageReduction:
        return 'REDUCCION';
      case BattlerStat.vampirism:
        return 'VAMPIRISMO';
    }
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
