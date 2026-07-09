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
    final opponentDebuffs = <AugmentDebuffApplication>[];
    var ownerBarrierDelta = 0;

    for (final augment in augments) {
      final resolution = augment.resolvePattern(
        patternPoints: pattern.patternPoints,
      );
      weaponAttackBonusDelta += resolution.weaponAttackBonusDelta;
      targetWeaponPermanentAttackBonusDelta +=
          resolution.targetWeaponPermanentAttackBonusDelta;
      targetWeaponPermanentAttackBonusPoint ??=
          resolution.targetWeaponPermanentAttackBonusPoint;
      opponentDebuffs.addAll(resolution.opponentDebuffs);
      ownerBarrierDelta += resolution.ownerBarrierDelta;
    }

    return AugmentPatternResolution(
      weaponAttackBonusDelta: weaponAttackBonusDelta,
      targetWeaponPermanentAttackBonusDelta:
          targetWeaponPermanentAttackBonusDelta,
      targetWeaponPermanentAttackBonusPoint:
          targetWeaponPermanentAttackBonusPoint,
      opponentDebuffs: List<AugmentDebuffApplication>.unmodifiable(
        opponentDebuffs,
      ),
      ownerBarrierDelta: ownerBarrierDelta,
    );
  }

  ({Battler owner, List<BattlerStatus> opponentStatuses})
      applyAugmentPatternEffects({
    required BattlePatternMatchContext pattern,
  }) {
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

    var updatedOwner = this;
    final opponentStatuses = <BattlerStatus>[];
    for (final augment in augments) {
      final resolution = augment.resolvePattern(
        patternPoints: pattern.patternPoints,
      );
      if (resolution.ownerBarrierDelta > 0) {
        updatedOwner = updatedOwner.gainCombatBarrier(
          resolution.ownerBarrierDelta,
        );
      }

      final amount = resolution.weaponAttackBonusDelta;
      if (amount > 0 && weapons.isNotEmpty) {
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

      for (final debuff in resolution.opponentDebuffs) {
        final status = _statusForAugmentDebuff(debuff);
        if (status == null) continue;
        opponentStatuses.add(status);
      }
    }
    return (
      owner: updatedOwner,
      opponentStatuses: List<BattlerStatus>.unmodifiable(opponentStatuses),
    );
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

  BattlerStatus? _statusForAugmentDebuff(AugmentDebuffApplication debuff) {
    if (debuff.value <= 0) return null;

    return switch (debuff.type) {
      AugmentDebuffType.fragilidad => FragilidadStatus(value: debuff.value),
      AugmentDebuffType.conmocion => ConmocionStatus(value: debuff.value),
      AugmentDebuffType.intoxicacion => IntoxicacionStatus(value: debuff.value),
      AugmentDebuffType.quemadura => QuemaduraStatus(
          remainingTurns: debuff.value,
        ),
    };
  }
}
