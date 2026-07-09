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
    var weaponAttackBonusDelta = 0;
    var targetWeaponPermanentAttackBonusDelta = 0;
    OperativePatternPoint? targetWeaponPermanentAttackBonusPoint;

    for (final augment in augments) {
      final resolution = augment.resolvePattern(
        patternPoints: pattern.patternPoints,
      );
      weaponAttackBonusDelta += resolution.weaponAttackBonusDelta;
      targetWeaponPermanentAttackBonusDelta +=
          resolution.targetWeaponPermanentAttackBonusDelta;
      targetWeaponPermanentAttackBonusPoint ??=
          resolution.targetWeaponPermanentAttackBonusPoint;
    }

    return AugmentPatternResolution(
      weaponAttackBonusDelta: weaponAttackBonusDelta,
      targetWeaponPermanentAttackBonusDelta:
          targetWeaponPermanentAttackBonusDelta,
      targetWeaponPermanentAttackBonusPoint:
          targetWeaponPermanentAttackBonusPoint,
    );
  }

  Battler applyAugmentPatternWeaponBoost({
    required BattlePatternMatchContext pattern,
  }) {
    if (pattern.usedItemPointKeys.isEmpty) return this;

    final usedPointKeys = pattern.usedItemPointKeys.toSet();
    final weapons = <Item>[];
    final seenItemKeys = <String>{};
    for (final item in equippedItems) {
      final pointKey =
          patternItemPointKeys[item.instanceId ?? item.catalogKey] ??
              patternItemPointKeys[item.catalogKey];
      if (pointKey == null || !usedPointKeys.contains(pointKey)) continue;
      if (!item.isWeaponLike ||
          !seenItemKeys.add(item.instanceId ?? item.catalogKey)) {
        continue;
      }
      weapons.add(item);
    }

    if (weapons.isEmpty) return this;

    var updatedOwner = this;
    for (final augment in augments) {
      final resolution = augment.resolvePattern(
        patternPoints: pattern.patternPoints,
      );
      final amount = resolution.weaponAttackBonusDelta;
      if (amount > 0) {
        updatedOwner = updatedOwner.addCombatAttackBonusToWeapons(
          weapons: weapons,
          amount: amount,
          sourceKey: 'augment:${augment.id}',
        );
      }

      final permanentAmount =
          resolution.targetWeaponPermanentAttackBonusDelta;
      final targetPoint = resolution.targetWeaponPermanentAttackBonusPoint;
      if (permanentAmount <= 0 || targetPoint == null) continue;

      final targetWeapon = updatedOwner._equippedWeaponAtPatternPoint(
        targetPoint,
      );
      if (targetWeapon == null) continue;

      final sourceKey = 'augment:${augment.id}';
      final currentBonus = targetWeapon.actionBonusValueForSource(
        actionType: ItemActionType.attack,
        sourceKey: sourceKey,
      );
      updatedOwner = updatedOwner.replaceOwnedItem(
        currentItem: targetWeapon,
        replacementItem: targetWeapon.withActionBonus(
          actionType: ItemActionType.attack,
          sourceKey: sourceKey,
          bonusValue: currentBonus + permanentAmount,
        ),
      );
    }
    return updatedOwner;
  }

  Item? _equippedWeaponAtPatternPoint(OperativePatternPoint point) {
    for (final item in equippedItems) {
      if (!item.isWeaponLike) continue;
      final pointKey =
          patternItemPointKeys[item.instanceId ?? item.catalogKey] ??
              patternItemPointKeys[item.catalogKey];
      if (pointKey == point.key) return item;
    }
    return null;
  }
}
