import '../archetype_id.dart';
import '../entity_tag.dart';
import '../pattern/_exports.dart';
import '../rarity_tier.dart';

const String augmentAssetDirectory = 'assets/sprites/augments/';

enum AugmentAffinity {
  general,
  veloz,
  inamovible,
  imparable,
  mercante,
}

extension AugmentAffinityMapping on AugmentAffinity {
  bool get isSpecific => this != AugmentAffinity.general;

  ArchetypeId? get archetypeId => switch (this) {
        AugmentAffinity.general => null,
        AugmentAffinity.veloz => ArchetypeId.veloz,
        AugmentAffinity.inamovible => ArchetypeId.inamovible,
        AugmentAffinity.imparable => ArchetypeId.imparable,
        AugmentAffinity.mercante => ArchetypeId.mercante,
      };
}

extension ArchetypeIdAugmentAffinity on ArchetypeId {
  AugmentAffinity get augmentAffinity => switch (this) {
        ArchetypeId.veloz => AugmentAffinity.veloz,
        ArchetypeId.inamovible => AugmentAffinity.inamovible,
        ArchetypeId.imparable => AugmentAffinity.imparable,
        ArchetypeId.mercante => AugmentAffinity.mercante,
      };
}

enum AugmentEffectType {
  patternGlobalAttackDamageBonus,
}

class AugmentEffect {
  final AugmentEffectType type;
  final int value;
  final String description;

  const AugmentEffect({
    required this.type,
    required this.value,
    required this.description,
  }) : assert(description != '');

  const AugmentEffect.patternAttackDamageBonus({
    required int value,
    required String description,
  }) : this(
          type: AugmentEffectType.patternGlobalAttackDamageBonus,
          value: value,
          description: description,
        );

  AugmentEffect withValue(int value) {
    return AugmentEffect(
      type: type,
      value: value,
      description: description,
    );
  }
}

class AugmentEffects {
  static const int tierPatternCount = 5;

  final Map<List<OperativePatternPoint>, AugmentEffect> patternEffects;

  AugmentEffects({
    required Map<List<OperativePatternPoint>, AugmentEffect> patternEffects,
  })  : assert(
          patternEffects.length == tierPatternCount,
          'AugmentEffects needs one ordered pattern/effect pair per tier.',
        ),
        patternEffects =
            Map<List<OperativePatternPoint>, AugmentEffect>.unmodifiable(
          patternEffects.map(
            (points, effect) => MapEntry(
              List<OperativePatternPoint>.unmodifiable(points),
              effect,
            ),
          ),
        );

  AugmentEffect? bestMatchingEffect({
    required List<OperativePatternPoint> drawnPattern,
    required RarityTier augmentTier,
  }) {
    final normalizedPattern =
        OperativePatternRequirement.normalizedSequence(drawnPattern);
    AugmentEffect? bestEffect;

    var tierIndex = 0;
    for (final entry in patternEffects.entries) {
      if (tierIndex <= augmentTier.index &&
          _containsOrderedPattern(
            normalizedPattern,
            OperativePatternRequirement.normalizedSequence(entry.key),
          )) {
        bestEffect = entry.value;
      }
      tierIndex++;
    }

    return bestEffect;
  }

  static bool _containsOrderedPattern(
    List<OperativePatternPoint> pattern,
    List<OperativePatternPoint> candidate,
  ) {
    if (candidate.isEmpty || candidate.length > pattern.length) return false;

    final maxStart = pattern.length - candidate.length;
    for (var start = 0; start <= maxStart; start++) {
      var matched = true;
      for (var index = 0; index < candidate.length; index++) {
        if (pattern[start + index] != candidate[index]) {
          matched = false;
          break;
        }
      }
      if (matched) return true;
    }

    return false;
  }
}

class AugmentPatternResolution {
  final int attackBonusDelta;

  const AugmentPatternResolution({
    this.attackBonusDelta = 0,
  });

  bool get isEmpty => attackBonusDelta == 0;
}

class Augment {
  final int id;
  final String name;
  final String description;
  final RarityTier tier;
  final String assetPath;
  final AugmentAffinity affinity;
  final List<EntityTag> tags;
  final AugmentEffects effects;

  Augment({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required String assetPath,
    this.affinity = AugmentAffinity.general,
    List<EntityTag> tags = const <EntityTag>[],
    required this.effects,
  })  : assert(id >= 0),
        assert(name != ''),
        assert(description != ''),
        assetPath = _resolveAssetPath(assetPath),
        tags = List<EntityTag>.unmodifiable(tags);

  bool get canUpgrade => !tier.isMaxTier;
  RarityTier get rarity => tier;
  String get displayName => name;
  String get displayDescription => description;
  bool get hasTags => tags.isNotEmpty;
  bool hasTag(EntityTag tag) => tags.contains(tag);
  bool hasAffinity(AugmentAffinity affinity) => this.affinity == affinity;

  Augment upgraded() {
    if (!canUpgrade) return this;
    return copyWith(tier: tier.nextTier);
  }

  Augment copyWith({
    String? name,
    String? description,
    RarityTier? tier,
    String? assetPath,
    AugmentAffinity? affinity,
    List<EntityTag>? tags,
    AugmentEffects? effects,
  }) {
    return Augment(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      tier: tier ?? this.tier,
      assetPath: assetPath ?? this.assetPath,
      affinity: affinity ?? this.affinity,
      tags: tags ?? this.tags,
      effects: effects ?? this.effects,
    );
  }

  AugmentPatternResolution resolvePattern({
    required List<OperativePatternPoint> patternPoints,
  }) {
    final effect = effects.bestMatchingEffect(
      drawnPattern: patternPoints,
      augmentTier: tier,
    );
    if (effect == null) return const AugmentPatternResolution();

    return switch (effect.type) {
      AugmentEffectType.patternGlobalAttackDamageBonus =>
        AugmentPatternResolution(attackBonusDelta: effect.value),
    };
  }

  static String _resolveAssetPath(String assetPath) {
    final normalized = assetPath.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) {
      throw ArgumentError.value(assetPath, 'assetPath', 'Asset path is empty.');
    }

    return normalized.startsWith('/') ? normalized.substring(1) : normalized;
  }
}
