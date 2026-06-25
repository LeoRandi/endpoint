part of 'battler.dart';

extension BattlerAugmentManagement on Battler {
  bool get hasAugments => augments.isNotEmpty;

  Augment? augmentById(int augmentId) {
    return _derivedState.augmentsById[augmentId];
  }

  bool hasAugment(Augment augment) {
    return augmentById(augment.id) != null;
  }

  bool wouldUpgradeAugment(Augment augment) {
    final existingAugment = augmentById(augment.id);
    return existingAugment != null &&
        existingAugment.rarity == augment.rarity &&
        existingAugment.canUpgrade;
  }

  Battler addAugment(Augment augment) {
    if (!CodexDiscoveryHook.isSuppressed) {
      CodexDiscoveryHook.onAugmentAdded?.call(augment.id);
    }
    final existingIndex = augments.indexWhere(
      (activeAugment) => activeAugment.id == augment.id,
    );
    if (existingIndex < 0) {
      return copyWith(
        augments: List<Augment>.unmodifiable([
          ...augments,
          augment,
        ]),
      );
    }

    final existingAugment = augments[existingIndex];
    if (existingAugment.tier != augment.tier || !existingAugment.canUpgrade) {
      return this;
    }

    final updatedAugments = List<Augment>.from(augments);
    updatedAugments[existingIndex] = existingAugment.upgraded();
    return copyWith(augments: List<Augment>.unmodifiable(updatedAugments));
  }

  Battler replaceAugment({
    required Augment currentAugment,
    required Augment replacementAugment,
  }) {
    final updatedAugments = List<Augment>.from(augments);
    final existingIndex = updatedAugments.indexWhere(
      (activeAugment) => activeAugment.id == currentAugment.id,
    );
    if (existingIndex < 0) return addAugment(replacementAugment);

    updatedAugments[existingIndex] = replacementAugment;
    return copyWith(augments: List<Augment>.unmodifiable(updatedAugments));
  }

  AugmentPatternResolution resolveAugmentPatternEffects({
    required BattlePatternMatchContext pattern,
  }) {
    var attackBonusDelta = 0;

    for (final augment in augments) {
      final resolution = augment.resolvePattern(
        patternPoints: pattern.patternPoints,
      );
      attackBonusDelta += resolution.attackBonusDelta;
    }

    return AugmentPatternResolution(attackBonusDelta: attackBonusDelta);
  }
}
