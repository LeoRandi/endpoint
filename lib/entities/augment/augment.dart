import '../archetype_id.dart';
import '../entity_tag.dart';
import '../pattern/_exports.dart';
import '../rarity_tier.dart';

const String augmentAssetDirectory = 'assets/sprites/augments/';

enum AugmentAffinity {
  general,
  crepitans,
  diabolicus,
  hercules,
  sacer,
}

extension AugmentAffinityMapping on AugmentAffinity {
  bool get isSpecific => this != AugmentAffinity.general;

  ArchetypeId? get archetypeId => switch (this) {
        AugmentAffinity.general => null,
        AugmentAffinity.crepitans => ArchetypeId.crepitans,
        AugmentAffinity.diabolicus => ArchetypeId.diabolicus,
        AugmentAffinity.hercules => ArchetypeId.hercules,
        AugmentAffinity.sacer => ArchetypeId.sacer,
      };
}

extension ArchetypeIdAugmentAffinity on ArchetypeId {
  AugmentAffinity get augmentAffinity => switch (this) {
        ArchetypeId.crepitans => AugmentAffinity.crepitans,
        ArchetypeId.diabolicus => AugmentAffinity.diabolicus,
        ArchetypeId.hercules => AugmentAffinity.hercules,
        ArchetypeId.sacer => AugmentAffinity.sacer,
      };
}

enum AugmentEffectType {
  patternWeaponCombatAttackBoost,
  patternTargetWeaponPermanentAttackBoost,
  patternOpponentDebuffs,
  patternOwnerBarrierBoost,
}

enum AugmentDebuffType {
  fragilidad,
  conmocion,
  intoxicacion,
  quemadura,
}

class AugmentDebuffApplication {
  final AugmentDebuffType type;
  final int value;

  const AugmentDebuffApplication({
    required this.type,
    required this.value,
  }) : assert(value > 0);
}

class AugmentEffect {
  final AugmentEffectType type;
  final int value;
  final String description;
  final OperativePatternPoint? targetPoint;
  final List<AugmentDebuffApplication> opponentDebuffs;

  const AugmentEffect({
    required this.type,
    required this.value,
    required this.description,
    this.targetPoint,
    this.opponentDebuffs = const [],
  })  : assert(description != ''),
        assert(
          type != AugmentEffectType.patternTargetWeaponPermanentAttackBoost ||
              targetPoint != null,
        );

  const AugmentEffect.patternAttackDamageBonus({
    required int value,
    required String description,
  }) : this(
          type: AugmentEffectType.patternWeaponCombatAttackBoost,
          value: value,
          description: description,
        );

  const AugmentEffect.patternTargetWeaponPermanentAttackDamageBonus({
    required int value,
    required String description,
    required OperativePatternPoint targetPoint,
  }) : this(
          type: AugmentEffectType.patternTargetWeaponPermanentAttackBoost,
          value: value,
          description: description,
          targetPoint: targetPoint,
        );

  const AugmentEffect.patternOpponentDebuffs({
    required String description,
    required List<AugmentDebuffApplication> opponentDebuffs,
  }) : this(
          type: AugmentEffectType.patternOpponentDebuffs,
          value: 0,
          description: description,
          opponentDebuffs: opponentDebuffs,
        );

  const AugmentEffect.patternOwnerBarrierBonus({
    required int value,
    required String description,
  }) : this(
          type: AugmentEffectType.patternOwnerBarrierBoost,
          value: value,
          description: description,
        );

  AugmentEffect withValue(int value) {
    return AugmentEffect(
      type: type,
      value: value,
      description: description,
      targetPoint: targetPoint,
      opponentDebuffs: opponentDebuffs,
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
  final int weaponAttackBonusDelta;
  final int targetWeaponPermanentAttackBonusDelta;
  final OperativePatternPoint? targetWeaponPermanentAttackBonusPoint;
  final List<AugmentDebuffApplication> opponentDebuffs;
  final int ownerBarrierDelta;

  const AugmentPatternResolution({
    this.weaponAttackBonusDelta = 0,
    this.targetWeaponPermanentAttackBonusDelta = 0,
    this.targetWeaponPermanentAttackBonusPoint,
    this.opponentDebuffs = const [],
    this.ownerBarrierDelta = 0,
  });

  bool get isEmpty =>
      weaponAttackBonusDelta == 0 &&
      targetWeaponPermanentAttackBonusDelta == 0 &&
      opponentDebuffs.isEmpty &&
      ownerBarrierDelta == 0;
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
      AugmentEffectType.patternWeaponCombatAttackBoost =>
        AugmentPatternResolution(weaponAttackBonusDelta: effect.value),
      AugmentEffectType.patternTargetWeaponPermanentAttackBoost =>
        AugmentPatternResolution(
          targetWeaponPermanentAttackBonusDelta: effect.value,
          targetWeaponPermanentAttackBonusPoint: effect.targetPoint,
        ),
      AugmentEffectType.patternOpponentDebuffs => AugmentPatternResolution(
          opponentDebuffs: effect.opponentDebuffs,
        ),
      AugmentEffectType.patternOwnerBarrierBoost =>
        AugmentPatternResolution(ownerBarrierDelta: effect.value),
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
