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
  stunBaton,
  emergencyPlating,
  pocketJammer,
  serratedEdge,
  containmentCoil,
  thermalTurbine,
  pulseCarbine,
  phaseVeil,
  inertialCore,
  impulseSpear,
  reboundHarness,
  concussionPrism,
  overloadInjector,
  vectorBulwark,
  contingencySeal,
  rescueBlade,
  shockMesh,
  toxicScalpel,
  deflectiveCapacitor,
  interferenceCannon,
  responseFrame,
  overloadAnchor,
  reboundLens,
  inertiaCrown,
  sunExecutionBlade,
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
  static const int defaultEquipmentCost = 1;
  static int _nextInstanceSequence = 0;
  static final RegExp _ownedInstancePattern = RegExp(r'^item_(\d+)$');

  final ItemId id;
  final List<EntityTag> tags;
  final String name;
  final String description;
  final String iconEmoji;
  final ItemSlot? slot;
  final RarityTier rarity;
  final int baseCost;
  final int? equipCost;
  final int value;
  final int upgradeValue;
  final int incomePerValueUnit;
  final int maxHealthPercentPerValueUnit;
  final Map<BattlerStat, int> statModifiers;
  final Map<BattlerStat, int> upgradeStatModifiers;
  final ItemEffect? effect;
  final String? instanceId;
  final ItemBonusShape? bonusShapeOverride;

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
    this.equipCost,
    this.value = 0,
    this.upgradeValue = 0,
    this.incomePerValueUnit = 0,
    this.maxHealthPercentPerValueUnit = 0,
    this.statModifiers = const {},
    this.upgradeStatModifiers = const {},
    this.effect,
    this.instanceId,
    this.bonusShapeOverride,
  });

  /// Indica si el objeto puede equiparse en algun hueco.
  bool get isEquippable => slot != null;

  /// Indica si este objeto ya es una copia propia y no un preset compartido.
  bool get isInstanced => instanceId != null;

  /// Indica si el objeto tiene una logica activa mas alla de sus stats planos.
  bool get hasEffect => effect != null;

  /// Devuelve la forma geometrica asociada al bonus especial del objeto.
  ItemBonusShape get bonusShape => bonusShapeOverride ?? _defaultBonusShape;

  /// Describe el bonus especial ligado a la forma actual del objeto.
  ItemSpecialBonus get specialBonus => ItemSpecialBonus.forShape(bonusShape);

  /// Indica si el objeto tiene al menos una tag util para filtros y UI.
  bool get hasTags => tags.isNotEmpty;

  /// Comprueba si este objeto pertenece a una tag concreta.
  bool hasTag(EntityTag tag) => tags.contains(tag);

  /// Indica si este objeto puede mejorar al recibir una copia adicional.
  bool get canUpgrade {
    final preset = presetForId(id);
    final resolvedUpgradeValue =
        upgradeValue > 0 ? upgradeValue : preset.upgradeValue;
    final resolvedUpgradeStats = upgradeStatModifiers.isNotEmpty
        ? upgradeStatModifiers
        : preset.upgradeStatModifiers;

    return !rarity.isMaxTier &&
        (resolvedUpgradeValue > 0 || resolvedUpgradeStats.isNotEmpty);
  }

  /// Devuelve el coste base propio del objeto para compra y reventa.
  int get cost => baseCost;

  /// Devuelve el coste de equipo efectivo, usando 1 salvo que el item lo fuerce.
  int get equipmentCost => max(0, equipCost ?? defaultEquipmentCost);

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
    final preset = presetForId(id);
    final resolvedUpgradeValue =
        upgradeValue > 0 ? upgradeValue : preset.upgradeValue;
    if (resolvedUpgradeValue <= 0) return 0;

    final baseValue = preset.value;
    if (value <= baseValue) return 0;

    return max(0, (value - baseValue) ~/ resolvedUpgradeValue);
  }

  /// Devuelve el nombre visible del objeto sin marcadores extras de mejora.
  String get displayName => name;

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

  ItemBonusShape get _defaultBonusShape {
    if (slot == ItemSlot.weapon) {
      return ItemBonusShape.triangle;
    }
    if (hasTag(EntityTag.barrera)) {
      return ItemBonusShape.square;
    }
    return ItemBonusShape.circle;
  }

  /// Sube la rareza visual y el valor del objeto respetando el tope amarillo.
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
      rarity: rarity.nextTier,
      baseCost: upgradeTemplate.baseCost,
      value: value + upgradeTemplate.upgradeValue,
      upgradeValue: upgradeTemplate.upgradeValue,
      incomePerValueUnit: upgradeTemplate.incomePerValueUnit,
      maxHealthPercentPerValueUnit:
          upgradeTemplate.maxHealthPercentPerValueUnit,
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
    int? equipCost,
    int? value,
    int? upgradeValue,
    int? incomePerValueUnit,
    int? maxHealthPercentPerValueUnit,
    Map<BattlerStat, int>? statModifiers,
    Map<BattlerStat, int>? upgradeStatModifiers,
    ItemEffect? effect,
    bool clearEffect = false,
    String? instanceId,
    ItemBonusShape? bonusShapeOverride,
    bool clearBonusShapeOverride = false,
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
      equipCost: equipCost ?? this.equipCost,
      value: value ?? this.value,
      upgradeValue: upgradeValue ?? this.upgradeValue,
      incomePerValueUnit: incomePerValueUnit ?? this.incomePerValueUnit,
      maxHealthPercentPerValueUnit:
          maxHealthPercentPerValueUnit ?? this.maxHealthPercentPerValueUnit,
      statModifiers: statModifiers ?? this.statModifiers,
      upgradeStatModifiers: upgradeStatModifiers ?? this.upgradeStatModifiers,
      effect: clearEffect ? null : effect ?? this.effect,
      instanceId: instanceId ?? this.instanceId,
      bonusShapeOverride: clearBonusShapeOverride
          ? null
          : bonusShapeOverride ?? this.bonusShapeOverride,
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
      equipCost: equipCost,
      value: value,
      upgradeValue: upgradeValue,
      incomePerValueUnit: incomePerValueUnit,
      maxHealthPercentPerValueUnit: maxHealthPercentPerValueUnit,
      statModifiers: statModifiers,
      upgradeStatModifiers: upgradeStatModifiers,
      effect: effect,
      instanceId: 'item_${_nextInstanceSequence++}',
      bonusShapeOverride: bonusShapeOverride,
    );
  }

  /// Avanza el contador global de instancias para no reutilizar ids tras restaurar una partida.
  static void syncInstanceSequenceFromExistingIds(
      Iterable<String?> instanceIds) {
    var nextSequence = _nextInstanceSequence;

    for (final instanceId in instanceIds) {
      if (instanceId == null) continue;
      final match = _ownedInstancePattern.firstMatch(instanceId);
      if (match == null) continue;

      final parsedSequence = int.tryParse(match.group(1) ?? '');
      if (parsedSequence == null) continue;
      nextSequence = max(nextSequence, parsedSequence + 1);
    }

    _nextInstanceSequence = nextSequence;
  }

  /// Recupera el preset canonico asociado al id estable del objeto.
  static Item presetForId(ItemId id) {
    final preset = itemPresetRegistry[id];
    if (preset != null) {
      return preset;
    }

    throw StateError('No existe preset para el objeto ${id.name}.');
  }

  /// Ajusta la rareza visual de objetos legacy segun sus mejoras acumuladas.
  Item normalizeUpgradeTier() {
    final preset = presetForId(id);
    final inferredRarity = preset.rarity.advanceBy(upgradeCount);
    if (rarity.index >= inferredRarity.index) return this;

    return copyWith(
      rarity: inferredRarity,
    );
  }

  static String _statLabel(BattlerStat stat) {
    switch (stat) {
      case BattlerStat.health:
        return 'HP';
      case BattlerStat.attack:
        return 'ATK';
      case BattlerStat.barrier:
        return 'Barrera';
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
