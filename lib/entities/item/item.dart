import '_imports.dart';

const String itemAssetDirectory = 'assets/sprites/items/';

/// Sprite paths eligible when an item does not declare a specific asset.
const List<String> itemAssetPool = <String>[
  '${itemAssetDirectory}WoodenStick.png',
];

/// The run archetype whose item pool contains an item.
enum ItemArchetypeAffinity {
  general,
  veloz,
  inamovible,
  imparable,
  mercante,
}

/// The immediate action produced by an [ActionEffect].
enum ItemActionType {
  attack,
  block,
  heal,
  none,
}

extension ItemArchetypeAffinityMapping on ItemArchetypeAffinity {
  bool get isSpecific => this != ItemArchetypeAffinity.general;

  ArchetypeId? get archetypeId => switch (this) {
        ItemArchetypeAffinity.general => null,
        ItemArchetypeAffinity.veloz => ArchetypeId.veloz,
        ItemArchetypeAffinity.inamovible => ArchetypeId.inamovible,
        ItemArchetypeAffinity.imparable => ArchetypeId.imparable,
        ItemArchetypeAffinity.mercante => ArchetypeId.mercante,
      };
}

extension ArchetypeIdItemAffinity on ArchetypeId {
  ItemArchetypeAffinity get itemAffinity => switch (this) {
        ArchetypeId.veloz => ItemArchetypeAffinity.veloz,
        ArchetypeId.inamovible => ItemArchetypeAffinity.inamovible,
        ArchetypeId.imparable => ItemArchetypeAffinity.imparable,
        ArchetypeId.mercante => ItemArchetypeAffinity.mercante,
      };
}

/// Immutable item definition.
///
/// Each entry in [effects] pairs the effect at the current [tier] with the
/// amount added to that effect's value whenever the item advances one tier.
class Item {
  static int _nextInstanceSequence = 0;
  static final RegExp _ownedInstancePattern = RegExp(r'^item_(\d+)$');

  final String name;
  final String description;
  final ItemArchetypeAffinity affinity;
  final RarityTier tier;
  final int baseCost;
  final int sellValue;
  final List<EntityTag> tags;
  final String asset;
  final Map<Effect, int> effects;
  final String? instanceId;
  final bool isGhostly;

  /// Creates an item and resolves its sprite for the lifetime of the run.
  ///
  /// When [asset] is omitted, [randomizer] must be the run random source.
  Item({
    required this.name,
    required this.description,
    required this.affinity,
    required this.tier,
    required this.baseCost,
    required this.sellValue,
    List<EntityTag> tags = const <EntityTag>[],
    String? asset,
    RandomSource? randomizer,
    Map<Effect, int> effects = const <Effect, int>{},
    this.instanceId,
    this.isGhostly = false,
  })  : tags = List<EntityTag>.unmodifiable(tags),
        effects = Map<Effect, int>.unmodifiable(effects),
        asset = _resolveAsset(asset, randomizer);

  /// Stable catalog identity. Item names are canonical data, not localized UI.
  String get catalogKey => name;

  bool get canUpgrade => !tier.isMaxTier;

  /// Advances the tier and applies each effect's configured upgrade value.
  Item upgraded() {
    if (!canUpgrade) return this;

    return copyWith(
      tier: tier.nextTier,
      effects: <Effect, int>{
        for (final entry in effects.entries)
          entry.key.withValue(entry.key.value + entry.value): entry.value,
      },
    );
  }

  Item copyWith({
    String? name,
    String? description,
    ItemArchetypeAffinity? affinity,
    RarityTier? tier,
    int? baseCost,
    int? sellValue,
    List<EntityTag>? tags,
    String? asset,
    Map<Effect, int>? effects,
    String? instanceId,
    bool? isGhostly,
  }) {
    return Item(
      name: name ?? this.name,
      description: description ?? this.description,
      affinity: affinity ?? this.affinity,
      tier: tier ?? this.tier,
      baseCost: baseCost ?? this.baseCost,
      sellValue: sellValue ?? this.sellValue,
      tags: tags ?? this.tags,
      asset: asset ?? this.asset,
      effects: effects ?? this.effects,
      instanceId: instanceId ?? this.instanceId,
      isGhostly: isGhostly ?? this.isGhostly,
    );
  }

  static String _resolveAsset(String? asset, RandomSource? randomizer) {
    if (asset == null || asset.trim().isEmpty) {
      if (randomizer == null) {
        throw ArgumentError.notNull('randomizer');
      }
      return itemAssetPool[randomizer.nextInt(itemAssetPool.length)];
    }

    final normalizedAsset = asset.trim().replaceAll('\\', '/');
    final filename = normalizedAsset.startsWith(itemAssetDirectory)
        ? normalizedAsset.substring(itemAssetDirectory.length)
        : normalizedAsset;
    if (filename.isEmpty || filename.contains('/') || filename.contains('..')) {
      throw ArgumentError.value(
        asset,
        'asset',
        'Item assets must be filenames inside $itemAssetDirectory.',
      );
    }
    return '$itemAssetDirectory$filename';
  }

  // Read-only views used by gameplay and presentation.
  RarityTier get rarity => tier;
  String get iconEmoji => '\u{1F9F0}';

  List<ActionEffect> get actionEffects => List<ActionEffect>.unmodifiable(
        effects.keys.whereType<ActionEffect>(),
      );

  List<PatternEffect> get patternEffects => List<PatternEffect>.unmodifiable(
        effects.keys.whereType<PatternEffect>(),
      );

  List<PassiveEffect> get passiveEffects => List<PassiveEffect>.unmodifiable(
        effects.keys.whereType<PassiveEffect>(),
      );

  ActionEffect? get primaryActionEffect =>
      actionEffects.isEmpty ? null : actionEffects.first;

  PatternEffect? get primaryPatternEffect =>
      patternEffects.isEmpty ? null : patternEffects.first;

  OperativePatternBonus? get primaryPatternBonus {
    final effect = primaryPatternEffect;
    if (effect == null ||
        effect.actionEffect.actionType == ItemActionType.none) {
      return null;
    }
    return OperativePatternBonus(
      kind: switch (effect.actionEffect.actionType) {
        ItemActionType.attack => OperativePatternBonusKind.attack,
        ItemActionType.block => OperativePatternBonusKind.barrier,
        ItemActionType.heal => OperativePatternBonusKind.health,
        ItemActionType.none => throw StateError('Handled above.'),
      },
      amount: effect.value,
    );
  }

  /// Pattern actions enabled by [patternPoints] at this item's [itemPoint].
  List<PatternEffect> matchingPatternEffects({
    required List<OperativePatternPoint> patternPoints,
    required OperativePatternPoint itemPoint,
  }) {
    return List<PatternEffect>.unmodifiable(
      patternEffects.where(
        (effect) => effect.patternType.isSatisfiedBy(
          patternPoints: patternPoints,
          itemPoint: itemPoint,
        ),
      ),
    );
  }

  bool get isEquippable => true;
  bool get isInstanced => instanceId != null;
  bool get hasEffect => effects.isNotEmpty;
  bool get hasTags => tags.isNotEmpty;
  bool hasTag(EntityTag tag) => tags.contains(tag);
  bool get isWeaponLike => hasTag(EntityTag.arma);
  bool get isAccessoryLike => hasTag(EntityTag.accesorio);
  bool hasArchetypeAffinity(ItemArchetypeAffinity affinity) =>
      this.affinity == affinity;
  bool hasAnyArchetypeAffinity(Iterable<ItemArchetypeAffinity> affinities) =>
      affinities.contains(affinity);
  String get displayName => name;
  String get displayDescription => description;
  String get tooltipDescription => description;
  Item toOwnedInstance() => toRuntimeInstance();
  Item toRuntimeInstance({bool forceNewInstance = false}) {
    if (isInstanced && !forceNewInstance) return this;
    return copyWith(instanceId: _nextOwnedInstanceId());
  }

  static String _nextOwnedInstanceId() => 'item_${_nextInstanceSequence++}';

  static void syncInstanceSequenceFromExistingIds(
    Iterable<String?> instanceIds,
  ) {
    var nextSequence = _nextInstanceSequence;
    for (final instanceId in instanceIds) {
      if (instanceId == null) continue;
      final match = _ownedInstancePattern.firstMatch(instanceId);
      if (match == null) continue;
      final sequence = int.tryParse(match.group(1) ?? '');
      if (sequence != null) nextSequence = max(nextSequence, sequence + 1);
    }
    _nextInstanceSequence = nextSequence;
  }

  static Item presetForKey(String catalogKey) {
    final preset = itemPresetRegistry[catalogKey];
    if (preset != null) return preset;
    throw StateError('No item preset exists for $catalogKey.');
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
