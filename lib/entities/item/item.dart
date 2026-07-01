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
/// values it should use for this tier and every reachable higher tier.
class Item {
  static int _nextInstanceSequence = 0;
  static final RegExp _ownedInstancePattern = RegExp(r'^item_(\d+)$');

  final String name;
  final String description;
  final ItemArchetypeAffinity affinity;
  final RarityTier tier;
  final int valueModifier;
  final List<EntityTag> tags;
  final String asset;
  final Map<Effect, List<int>> effects;
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
    this.valueModifier = 0,
    List<EntityTag> tags = const <EntityTag>[],
    String? asset,
    RandomSource? randomizer,
    Map<Effect, List<int>> effects = const <Effect, List<int>>{},
    this.instanceId,
    this.isGhostly = false,
  })  : tags = List<EntityTag>.unmodifiable(tags),
        effects = Map<Effect, List<int>>.unmodifiable({
          for (final entry in effects.entries)
            entry.key: List<int>.unmodifiable(entry.value),
        }),
        asset = _resolveAsset(asset, randomizer);

  /// Stable catalog identity. Item names are canonical data, not localized UI.
  String get catalogKey => name;

  bool get canUpgrade => !tier.isMaxTier;

  int get baseCost => tier.factor * 2;
  int get sellValue => max(0, tier.factor + valueModifier);

  /// Advances the tier and applies each effect's next configured tier value.
  Item upgraded() {
    if (!canUpgrade) return this;

    return copyWith(
      tier: tier.nextTier,
      effects: _effectsAdvancedBy(1),
    );
  }

  Item withActionBonus({
    required ItemActionType actionType,
    required String sourceKey,
    required int bonusValue,
  }) {
    final safeSourceKey = sourceKey.trim();
    if (safeSourceKey.isEmpty) return this;

    return copyWith(
      effects: <Effect, List<int>>{
        for (final entry in effects.entries)
          _effectWithActionBonus(
            effect: entry.key,
            actionType: actionType,
            sourceKey: safeSourceKey,
            bonusValue: bonusValue,
          ): entry.value,
      },
    );
  }

  int actionBonusValueForSource({
    required ItemActionType actionType,
    required String sourceKey,
  }) {
    var currentValue = 0;
    for (final action in actionEffects) {
      if (action.actionType == actionType) {
        currentValue = max(
          currentValue,
          action.bonusValueForSource(sourceKey),
        );
      }
    }
    for (final patternEffect in patternEffects) {
      final action = patternEffect.actionEffect;
      if (action.actionType == actionType) {
        currentValue = max(
          currentValue,
          action.bonusValueForSource(sourceKey),
        );
      }
    }
    return currentValue;
  }

  Item copyWith({
    String? name,
    String? description,
    ItemArchetypeAffinity? affinity,
    RarityTier? tier,
    int? valueModifier,
    List<EntityTag>? tags,
    String? asset,
    Map<Effect, List<int>>? effects,
    String? instanceId,
    bool? isGhostly,
  }) {
    final targetTier = tier ?? this.tier;
    final tierStep = targetTier.index - this.tier.index;
    final resolvedEffects =
        effects ?? (tierStep > 0 ? _effectsAdvancedBy(tierStep) : this.effects);

    return Item(
      name: name ?? this.name,
      description: description ?? this.description,
      affinity: affinity ?? this.affinity,
      tier: targetTier,
      valueModifier: valueModifier ?? this.valueModifier,
      tags: tags ?? this.tags,
      asset: asset ?? this.asset,
      effects: resolvedEffects,
      instanceId: instanceId ?? this.instanceId,
      isGhostly: isGhostly ?? this.isGhostly,
    );
  }

  Map<Effect, List<int>> _effectsAdvancedBy(int steps) {
    if (steps <= 0) return effects;

    return <Effect, List<int>>{
      for (final entry in effects.entries)
        _effectAtValueIndex(entry.key, entry.value, steps):
            _remainingTierValues(entry.value, steps),
    };
  }

  static Effect _effectAtValueIndex(
    Effect effect,
    List<int> values,
    int index,
  ) {
    if (values.isEmpty) return effect;
    return effect.withValue(values[min(index, values.length - 1)]);
  }

  static List<int> _remainingTierValues(List<int> values, int consumedCount) {
    if (values.isEmpty) return const <int>[];
    if (consumedCount <= 0) return List<int>.unmodifiable(values);
    if (consumedCount >= values.length) {
      return List<int>.unmodifiable(<int>[values.last]);
    }
    return List<int>.unmodifiable(values.skip(consumedCount));
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
      amount: effect.totalValue,
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

  static Effect _effectWithActionBonus({
    required Effect effect,
    required ItemActionType actionType,
    required String sourceKey,
    required int bonusValue,
  }) {
    if (effect is ActionEffect && effect.actionType == actionType) {
      return effect.withBonusSource(
        sourceKey: sourceKey,
        bonusValue: bonusValue,
      );
    }
    if (effect is PatternEffect &&
        effect.actionEffect.actionType == actionType) {
      return effect.withActionBonusSource(
        sourceKey: sourceKey,
        bonusValue: bonusValue,
      );
    }
    return effect;
  }
}
