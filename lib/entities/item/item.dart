import '../_imports.dart';

/// Identifica cada tipo de objeto sin depender de la instancia concreta que posea el jugador.
enum ItemId {
  woodenStick,
  cyberWhips,
  sunglasses,
  shield,
  bulwarkAmulet,
  crackedBattery,
  gafasFotocromaticas,
  bateriaCrepuscular,
  relojDeTurno,
  faroNoctivago,
  prismaCircadiano,
  impactGloves,
  chemicalFilter,
  billingModule,
  mochilaStronkbox,
  muestrarioContrabando,
  roperaUnida,
  mamparaPortatil,
  magnetiCHammer,
  ceramicaPurgadora,
  clavoReactor,
  ultimaMarcha,
  pagareRevalorizable,
  placaBisagra,
  silbatoMudo,
  botiquinCompacto,
  fundaAislante,
  portableOven,
  eclipseMantle,
  operativeBlackBox,
  succionaCreditos,
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
  concussionPrism,
  overloadInjector,
  contingencySeal,
  rescueBlade,
  shockMesh,
  toxicScalpel,
  deflectiveCapacitor,
  interferenceCannon,
  responseFrame,
  overloadAnchor,
  reboundLens,
  kunaiAncho,
  capaDelContrabandista,
  sunExecutionBlade,
  nucleoPiezoelectrico,
  placasCompresion,
  torreRetorno,
  aislanteArmonico,
  canonContrapresion,
  guanteReto,
  clavoDuelista,
  vendasApretadas,
  marcaRetador,
  hemomedidor,
  heridaCarbonizada,
  guanteProvocacion,
  contratoDoloroso,
  yunqueCardiaco,
  revanchadora,
  embudoMejoras,
  arnesTactico,
  mandibultimatum,
  estandarteUltimoSol,
  motorMartirio,
  visorApertura,
  seguroRoto,
  aceleradorReto,
  ultimaPalabra,
  descargaResonante,
  prismaDeEco,
  vialRoto,
  plumaSeptica,
  lanzaSucia,
  ampollaInestable,
  tuboCultivo,
  cyberCerbatana,
  protocoloBrote,
  incubadoraPortatil,
}

/// Identifica a que familias de arquetipo puede pertenecer un objeto.
enum ItemArchetypeAffinity {
  general,
  veloz,
  inamovible,
  imparable,
  mercante,
}

/// Expone utilidades para convertir afinidades de item en arquetipos de run.
extension ItemArchetypeAffinityMapping on ItemArchetypeAffinity {
  bool get isSpecific => this != ItemArchetypeAffinity.general;

  ArchetypeId? get archetypeId {
    switch (this) {
      case ItemArchetypeAffinity.general:
        return null;
      case ItemArchetypeAffinity.veloz:
        return ArchetypeId.veloz;
      case ItemArchetypeAffinity.inamovible:
        return ArchetypeId.inamovible;
      case ItemArchetypeAffinity.imparable:
        return ArchetypeId.imparable;
      case ItemArchetypeAffinity.mercante:
        return ArchetypeId.mercante;
    }
  }
}

/// Traduce el arquetipo jugable a la afinidad equivalente usada por los items.
extension ArchetypeIdItemAffinity on ArchetypeId {
  ItemArchetypeAffinity get itemAffinity {
    switch (this) {
      case ArchetypeId.veloz:
        return ItemArchetypeAffinity.veloz;
      case ArchetypeId.inamovible:
        return ItemArchetypeAffinity.inamovible;
      case ArchetypeId.imparable:
        return ItemArchetypeAffinity.imparable;
      case ArchetypeId.mercante:
        return ItemArchetypeAffinity.mercante;
    }
  }
}

const _weaponTaggedItemIds = <ItemId>{
  ItemId.woodenStick,
  ItemId.cyberWhips,
  ItemId.impactGloves,
  ItemId.roperaUnida,
  ItemId.clavoReactor,
  ItemId.ironSword,
  ItemId.placaBisagra,
  ItemId.stunBaton,
  ItemId.kunaiAncho,
  ItemId.serratedEdge,
  ItemId.pulseCarbine,
  ItemId.overloadInjector,
  ItemId.sunsteelBlade,
  ItemId.rescueBlade,
  ItemId.toxicScalpel,
  ItemId.interferenceCannon,
  ItemId.magnetiCHammer,
  ItemId.sunExecutionBlade,
  ItemId.guanteReto,
  ItemId.clavoDuelista,
  ItemId.mandibultimatum,
  ItemId.ultimaPalabra,
  ItemId.descargaResonante,
  ItemId.lanzaSucia,
  ItemId.cyberCerbatana,
};

const _accessoryTaggedItemIds = <ItemId>{
  ItemId.sunglasses,
  ItemId.gafasFotocromaticas,
  ItemId.pagareRevalorizable,
  ItemId.bulwarkAmulet,
  ItemId.crackedBattery,
  ItemId.bateriaCrepuscular,
  ItemId.relojDeTurno,
  ItemId.faroNoctivago,
  ItemId.prismaCircadiano,
  ItemId.toxicCatalyst,
  ItemId.emberCharm,
  ItemId.chemicalFilter,
  ItemId.muestrarioContrabando,
  ItemId.reactiveCasing,
  ItemId.silbatoMudo,
  ItemId.pocketJammer,
  ItemId.thermalTurbine,
  ItemId.concussionPrism,
  ItemId.contingencySeal,
  ItemId.dawnCharm,
  ItemId.succionaCreditos,
  ItemId.voidInjector,
  ItemId.eclipseMantle,
  ItemId.operativeBlackBox,
  ItemId.deflectiveCapacitor,
  ItemId.ceramicaPurgadora,
  ItemId.ultimaMarcha,
  ItemId.botiquinCompacto,
  ItemId.fundaAislante,
  ItemId.overloadAnchor,
  ItemId.reboundLens,
  ItemId.nucleoPiezoelectrico,
  ItemId.placasCompresion,
  ItemId.torreRetorno,
  ItemId.aislanteArmonico,
  ItemId.canonContrapresion,
  ItemId.prismaDeEco,
  ItemId.visorApertura,
  ItemId.vendasApretadas,
  ItemId.marcaRetador,
  ItemId.hemomedidor,
  ItemId.guanteProvocacion,
  ItemId.contratoDoloroso,
  ItemId.revanchadora,
  ItemId.embudoMejoras,
  ItemId.estandarteUltimoSol,
  ItemId.seguroRoto,
  ItemId.aceleradorReto,
  ItemId.vialRoto,
  ItemId.plumaSeptica,
  ItemId.ampollaInestable,
  ItemId.tuboCultivo,
  ItemId.protocoloBrote,
  ItemId.incubadoraPortatil,
};

const _patternSquareRequirement = OperativePatternRequirement.exactShape(
  labelOverride: 'Cuadrado',
  shapeKind: OperativePatternShapeKind.square,
  shapePoints: <OperativePatternPoint>[
    OperativePatternPoint(x: -1, y: 1),
    OperativePatternPoint(x: 1, y: 1),
    OperativePatternPoint(x: 1, y: -1),
    OperativePatternPoint(x: -1, y: -1),
  ],
);

const _patternDiamondRequirement = OperativePatternRequirement.exactShape(
  labelOverride: 'Diamante',
  shapeKind: OperativePatternShapeKind.diamond,
  shapePoints: <OperativePatternPoint>[
    OperativePatternPoint(x: 0, y: 1),
    OperativePatternPoint(x: 1, y: 0),
    OperativePatternPoint(x: 0, y: -1),
    OperativePatternPoint(x: -1, y: 0),
  ],
);

const _patternHourglassRequirement = OperativePatternRequirement.exactShape(
  labelOverride: 'Reloj arena',
  shapeKind: OperativePatternShapeKind.hourglass,
  shapePoints: <OperativePatternPoint>[
    OperativePatternPoint(x: -1, y: 1),
    OperativePatternPoint(x: 1, y: 1),
    OperativePatternPoint(x: -1, y: -1),
    OperativePatternPoint(x: 1, y: -1),
  ],
);

const _patternZigzagRequirement = OperativePatternRequirement.exactShape(
  labelOverride: 'Zigzag',
  shapeKind: OperativePatternShapeKind.zigzag,
  shapePoints: <OperativePatternPoint>[
    OperativePatternPoint(x: -1, y: 1),
    OperativePatternPoint(x: 0, y: 0),
    OperativePatternPoint(x: 1, y: 1),
    OperativePatternPoint(x: 0, y: -1),
    OperativePatternPoint(x: -1, y: -1),
  ],
);

const _exactPatternRequirementsByItemId = <ItemId, OperativePatternRequirement>{
  ItemId.bateriaCrepuscular: _patternHourglassRequirement,
  ItemId.relojDeTurno: _patternSquareRequirement,
  ItemId.faroNoctivago: _patternZigzagRequirement,
  ItemId.prismaCircadiano: _patternDiamondRequirement,
  ItemId.muestrarioContrabando: _patternZigzagRequirement,
  ItemId.contingencySeal: _patternDiamondRequirement,
  ItemId.operativeBlackBox: _patternSquareRequirement,
  ItemId.responseFrame: _patternSquareRequirement,
  ItemId.overloadAnchor: _patternZigzagRequirement,
  ItemId.capaDelContrabandista: _patternHourglassRequirement,
  ItemId.sunExecutionBlade: _patternHourglassRequirement,
  ItemId.cyberCerbatana: OperativePatternRequirement.straightAngle(),
};

const _firstPointPatternItemIds = <ItemId>{
  ItemId.woodenStick,
  ItemId.cyberWhips,
  ItemId.crackedBattery,
  ItemId.gafasFotocromaticas,
  ItemId.impactGloves,
  ItemId.guanteReto,
  ItemId.visorApertura,
  ItemId.ironSword,
  ItemId.stunBaton,
  ItemId.kunaiAncho,
  ItemId.pulseCarbine,
  ItemId.sunsteelBlade,
  ItemId.magnetiCHammer,
};

const _lastPointPatternItemIds = <ItemId>{
  ItemId.seguroRoto,
  ItemId.aceleradorReto,
  ItemId.ultimaPalabra,
  ItemId.clavoReactor,
  ItemId.ultimaMarcha,
  ItemId.serratedEdge,
  ItemId.overloadInjector,
  ItemId.rescueBlade,
  ItemId.toxicScalpel,
  ItemId.interferenceCannon,
  ItemId.succionaCreditos,
  ItemId.voidInjector,
};

const _rightAnglePatternItemIds = <ItemId>{
  ItemId.shield,
  ItemId.bulwarkAmulet,
  ItemId.mamparaPortatil,
  ItemId.ceramicaPurgadora,
  ItemId.placaBisagra,
  ItemId.silbatoMudo,
  ItemId.botiquinCompacto,
  ItemId.fundaAislante,
  ItemId.guardShield,
  ItemId.reactiveCasing,
  ItemId.emergencyPlating,
  ItemId.pocketJammer,
  ItemId.containmentCoil,
  ItemId.phaseVeil,
  ItemId.platedJacket,
  ItemId.nucleoPiezoelectrico,
  ItemId.placasCompresion,
  ItemId.torreRetorno,
  ItemId.aislanteArmonico,
  ItemId.canonContrapresion,
  ItemId.deflectiveCapacitor,
};

/// Representa un objeto base o una copia poseida con stats, economia y efectos opcionales.
class Item {
  static int _nextInstanceSequence = 0;
  static final RegExp _ownedInstancePattern = RegExp(r'^item_(\d+)$');

  final ItemId id;
  final List<ItemArchetypeAffinity> archetypeAffinities;
  final List<EntityTag> _declaredTags;
  final String name;
  final String description;
  final String iconEmoji;
  final RarityTier rarity;
  final int baseCost;
  final int sellValueBonus;
  final int value;
  final int upgradeValue;
  final int incomePerValueUnit;
  final int maxHealthPercentPerValueUnit;
  final Map<BattlerStat, int> statModifiers;
  final Map<BattlerStat, int> upgradeStatModifiers;
  final ItemEffect? effect;
  final String? instanceId;
  final OperativePatternBonusKind? patternBonusKindOverride;
  final int? patternBonusAmountOverride;
  final OperativePatternRequirement? patternRequirementOverride;
  final bool hasPatternAura;
  final int combatItemBonusBoost;
  final bool combatGeneratedPatternBonus;
  final List<OperativePatternAdjacencyBonus> patternAdjacencyBonuses;

  /// Crea un item inmutable que puede actuar como preset compartido o copia poseida.
  const Item({
    required this.id,
    this.archetypeAffinities = const [ItemArchetypeAffinity.general],
    List<EntityTag> tags = const [],
    required this.name,
    required this.description,
    this.iconEmoji = '\u{1F9F0}',
    this.rarity = RarityTier.gray,
    required this.baseCost,
    this.sellValueBonus = 0,
    this.value = 0,
    this.upgradeValue = 0,
    this.incomePerValueUnit = 0,
    this.maxHealthPercentPerValueUnit = 0,
    this.statModifiers = const {},
    this.upgradeStatModifiers = const {},
    this.effect,
    this.instanceId,
    this.patternBonusKindOverride,
    this.patternBonusAmountOverride,
    this.patternRequirementOverride,
    this.hasPatternAura = false,
    this.combatItemBonusBoost = 0,
    this.combatGeneratedPatternBonus = false,
    this.patternAdjacencyBonuses = const <OperativePatternAdjacencyBonus>[],
  }) : _declaredTags = tags;

  /// Indica si el objeto puede equiparse.
  bool get isEquippable => true;

  /// Indica si este objeto ya es una copia propia y no un preset compartido.
  bool get isInstanced => instanceId != null;

  /// Indica si el objeto tiene una logica activa mas alla de sus stats planos.
  bool get hasEffect => effect != null;

  /// Indica si este objeto aporta su propio bonus de Patron.
  bool get hasPatternBonus => patternBonusAmount > 0;

  /// Describe el bonus que aporta este objeto cuando se cruza en Patron.
  OperativePatternBonus get patternBonus => OperativePatternBonus(
        kind: patternBonusKind,
        amount: patternBonusAmount,
      );

  /// Devuelve si el bonus interno del Patron empuja ataque o bloqueo.
  OperativePatternBonusKind get patternBonusKind =>
      patternBonusKindOverride ?? _defaultPatternBonusKind;

  /// Devuelve la magnitud interna del bonus de Patron.
  int get patternBonusAmount =>
      patternBonusAmountOverride ?? max(1, rarity.factor);

  /// Devuelve la condicion que debe cumplir el trazo para activar su bonus de Patron.
  OperativePatternRequirement get patternRequirement =>
      patternRequirementOverride ?? _defaultPatternRequirement;

  /// Devuelve las tags declaradas mas las de categoria visible heredadas.
  List<EntityTag> get tags {
    final resolvedTags = <EntityTag>{
      ..._declaredTags,
    };
    if (isWeaponLike) {
      resolvedTags.add(EntityTag.arma);
    }
    if (isAccessoryLike) {
      resolvedTags.add(EntityTag.accesorio);
    }
    return List<EntityTag>.unmodifiable(resolvedTags);
  }

  /// Indica si el objeto tiene al menos una tag util para filtros y UI.
  bool get hasTags => tags.isNotEmpty;

  /// Comprueba si este objeto pertenece a una tag concreta.
  bool hasTag(EntityTag tag) => tags.contains(tag);

  /// Indica si el objeto se presenta como arma en la interfaz y los filtros.
  bool get isWeaponLike => _weaponTaggedItemIds.contains(id);

  /// Indica si el objeto se presenta como accesorio en la interfaz y los filtros.
  bool get isAccessoryLike => _accessoryTaggedItemIds.contains(id);

  /// Comprueba si este objeto declara afinidad con un arquetipo concreto.
  bool hasArchetypeAffinity(ItemArchetypeAffinity affinity) {
    return archetypeAffinities.contains(affinity);
  }

  /// Comprueba si comparte afinidad con alguna de las pedidas.
  bool hasAnyArchetypeAffinity(Iterable<ItemArchetypeAffinity> affinities) {
    for (final affinity in affinities) {
      if (hasArchetypeAffinity(affinity)) {
        return true;
      }
    }
    return false;
  }

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

  /// Devuelve el coste actual del objeto para compra y reventa.
  int get cost {
    if (baseCost <= 0) return 0;

    return 1 << rarity.factor;
  }

  /// Devuelve el valor de venta rapida fuera de tienda.
  int get sellValue => max(1, rarity.factor);

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

  /// Genera la descripcion visible unica, priorizando el efecto con valores de instancia.
  String get displayDescription {
    final effectDescription = effect?.descriptionFor(this);
    if (effectDescription != null) {
      final statEntries = _statModifierDescriptionEntries();
      if (statEntries.isEmpty) return effectDescription;

      return [
        ...statEntries,
        effectDescription,
      ].join('. ');
    }

    final entries = _modifierDescriptionEntries();
    if (entries.isNotEmpty) return entries.join('. ');

    if (upgradeCount <= 0) return description;

    return description;
  }

  /// Devuelve la misma descripcion canonica para tooltips y tarjetas compactas.
  String get tooltipDescription => displayDescription;

  List<String> _statModifierDescriptionEntries() {
    return [
      ...statModifiers.entries.map((entry) {
        final value = entry.value;
        final sign = value >= 0 ? '+' : '';
        return '$sign$value ${_statLabel(entry.key)}';
      }),
    ];
  }

  List<String> _modifierDescriptionEntries() {
    final entries = <String>[
      ..._statModifierDescriptionEntries(),
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
      archetypeAffinities: upgradeTemplate.archetypeAffinities,
      tags: upgradeTemplate._declaredTags,
      name: upgradeTemplate.name,
      description: upgradeTemplate.description,
      iconEmoji: upgradeTemplate.iconEmoji,
      rarity: rarity.nextTier,
      baseCost: upgradeTemplate.baseCost,
      sellValueBonus: sellValueBonus,
      value: value + upgradeTemplate.upgradeValue,
      upgradeValue: upgradeTemplate.upgradeValue,
      incomePerValueUnit: upgradeTemplate.incomePerValueUnit,
      maxHealthPercentPerValueUnit:
          upgradeTemplate.maxHealthPercentPerValueUnit,
      statModifiers: updatedStatModifiers,
      upgradeStatModifiers: upgradeTemplate.upgradeStatModifiers,
      effect: upgradeTemplate.effect,
      patternBonusKindOverride: upgradeTemplate.patternBonusKindOverride,
      clearPatternBonusKindOverride:
          upgradeTemplate.patternBonusKindOverride == null,
      patternBonusAmountOverride: upgradeTemplate.patternBonusAmountOverride,
      clearPatternBonusAmountOverride:
          upgradeTemplate.patternBonusAmountOverride == null,
      patternRequirementOverride: upgradeTemplate.patternRequirementOverride,
      clearPatternRequirementOverride:
          upgradeTemplate.patternRequirementOverride == null,
      hasPatternAura: false,
      combatItemBonusBoost: 0,
      combatGeneratedPatternBonus: false,
      patternAdjacencyBonuses: upgradeTemplate.patternAdjacencyBonuses,
    );
  }

  /// Crea una copia parcial del objeto conservando el resto de propiedades intactas.
  Item copyWith({
    List<ItemArchetypeAffinity>? archetypeAffinities,
    List<EntityTag>? tags,
    String? name,
    String? description,
    String? iconEmoji,
    RarityTier? rarity,
    int? baseCost,
    int? sellValueBonus,
    int? value,
    int? upgradeValue,
    int? incomePerValueUnit,
    int? maxHealthPercentPerValueUnit,
    Map<BattlerStat, int>? statModifiers,
    Map<BattlerStat, int>? upgradeStatModifiers,
    ItemEffect? effect,
    bool clearEffect = false,
    String? instanceId,
    OperativePatternBonusKind? patternBonusKindOverride,
    bool clearPatternBonusKindOverride = false,
    int? patternBonusAmountOverride,
    bool clearPatternBonusAmountOverride = false,
    OperativePatternRequirement? patternRequirementOverride,
    bool clearPatternRequirementOverride = false,
    bool? hasPatternAura,
    int? combatItemBonusBoost,
    bool? combatGeneratedPatternBonus,
    List<OperativePatternAdjacencyBonus>? patternAdjacencyBonuses,
  }) {
    return Item(
      id: id,
      archetypeAffinities: archetypeAffinities ?? this.archetypeAffinities,
      tags: tags ?? _declaredTags,
      name: name ?? this.name,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      rarity: rarity ?? this.rarity,
      baseCost: baseCost ?? this.baseCost,
      sellValueBonus: sellValueBonus ?? this.sellValueBonus,
      value: value ?? this.value,
      upgradeValue: upgradeValue ?? this.upgradeValue,
      incomePerValueUnit: incomePerValueUnit ?? this.incomePerValueUnit,
      maxHealthPercentPerValueUnit:
          maxHealthPercentPerValueUnit ?? this.maxHealthPercentPerValueUnit,
      statModifiers: statModifiers ?? this.statModifiers,
      upgradeStatModifiers: upgradeStatModifiers ?? this.upgradeStatModifiers,
      effect: clearEffect ? null : effect ?? this.effect,
      instanceId: instanceId ?? this.instanceId,
      patternBonusKindOverride: clearPatternBonusKindOverride
          ? null
          : patternBonusKindOverride ?? this.patternBonusKindOverride,
      patternBonusAmountOverride: clearPatternBonusAmountOverride
          ? null
          : patternBonusAmountOverride ?? this.patternBonusAmountOverride,
      patternRequirementOverride: clearPatternRequirementOverride
          ? null
          : patternRequirementOverride ?? this.patternRequirementOverride,
      hasPatternAura: hasPatternAura ?? this.hasPatternAura,
      combatItemBonusBoost:
          max(0, combatItemBonusBoost ?? this.combatItemBonusBoost),
      combatGeneratedPatternBonus:
          combatGeneratedPatternBonus ?? this.combatGeneratedPatternBonus,
      patternAdjacencyBonuses:
          patternAdjacencyBonuses ?? this.patternAdjacencyBonuses,
    );
  }

  /// Materializa un objeto de preset como copia propia para poder diferenciarlo por instancia.
  Item toOwnedInstance() {
    if (isInstanced) return this;

    return Item(
      id: id,
      archetypeAffinities: archetypeAffinities,
      tags: _declaredTags,
      name: name,
      description: description,
      iconEmoji: iconEmoji,
      rarity: rarity,
      baseCost: baseCost,
      sellValueBonus: sellValueBonus,
      value: value,
      upgradeValue: upgradeValue,
      incomePerValueUnit: incomePerValueUnit,
      maxHealthPercentPerValueUnit: maxHealthPercentPerValueUnit,
      statModifiers: statModifiers,
      upgradeStatModifiers: upgradeStatModifiers,
      effect: effect,
      instanceId: 'item_${_nextInstanceSequence++}',
      patternBonusKindOverride: patternBonusKindOverride,
      patternBonusAmountOverride: patternBonusAmountOverride,
      patternRequirementOverride: patternRequirementOverride,
      patternAdjacencyBonuses: patternAdjacencyBonuses,
    );
  }

  Item clearCombatAugments() {
    var updatedItem = this;

    if (combatItemBonusBoost > 0) {
      final amount = combatItemBonusBoost;
      final cleanedStats = <BattlerStat, int>{
        for (final entry in statModifiers.entries)
          entry.key: max(0, entry.value - amount),
      };
      final cleanedAdjacencyBonuses = patternAdjacencyBonuses
          .map(
            (bonus) => OperativePatternAdjacencyBonus(
              direction: bonus.direction,
              requiredTag: bonus.requiredTag,
              kind: bonus.kind,
              amount: max(0, bonus.amount - amount),
            ),
          )
          .toList(growable: false);
      updatedItem = updatedItem.copyWith(
        value: effect != null && value > amount ? value - amount : value,
        statModifiers: cleanedStats,
        patternBonusAmountOverride:
            hasPatternBonus ? max(0, patternBonusAmount - amount) : null,
        patternAdjacencyBonuses: cleanedAdjacencyBonuses,
      );
    }

    if (combatGeneratedPatternBonus) {
      updatedItem = updatedItem.copyWith(
        clearPatternBonusKindOverride: true,
        patternBonusAmountOverride: 0,
        clearPatternRequirementOverride: true,
      );
    }

    return updatedItem.copyWith(
      hasPatternAura: false,
      combatItemBonusBoost: 0,
      combatGeneratedPatternBonus: false,
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

  OperativePatternBonusKind get _defaultPatternBonusKind {
    final attackScore = max(0, modifier(BattlerStat.attack)) +
        (hasTag(EntityTag.ataque) ? 1 : 0) +
        (isWeaponLike ? 1 : 0);
    final barrierScore = max(0, modifier(BattlerStat.barrier)) +
        (hasTag(EntityTag.barrera) ? 1 : 0);

    return attackScore > barrierScore
        ? OperativePatternBonusKind.attack
        : OperativePatternBonusKind.barrier;
  }

  OperativePatternRequirement get _defaultPatternRequirement {
    final exactRequirement = _exactPatternRequirementsByItemId[id];
    if (exactRequirement != null) return exactRequirement;

    if (_rightAnglePatternItemIds.contains(id)) {
      return const OperativePatternRequirement.rightAngle();
    }
    if (_lastPointPatternItemIds.contains(id)) {
      return const OperativePatternRequirement.last();
    }
    if (_firstPointPatternItemIds.contains(id)) {
      return const OperativePatternRequirement.first();
    }
    if (hasTag(EntityTag.barrera)) {
      return const OperativePatternRequirement.rightAngle();
    }
    if (isWeaponLike) {
      return rarity.index >= RarityTier.blue.index
          ? const OperativePatternRequirement.last()
          : const OperativePatternRequirement.first();
    }

    return const OperativePatternRequirement.middle();
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
