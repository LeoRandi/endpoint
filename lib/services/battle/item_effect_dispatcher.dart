import '_imports.dart';

typedef ItemCustomActionHandler = ItemEffectResolution Function({
  required Battler owner,
  required Battler opponent,
  required Item item,
  required ActionEffect effect,
  required BattlePatternMatchContext pattern,
  required List<ActionEffect> previousActions,
});

typedef ItemPassiveEffectHandler = ItemEffectResolution Function({
  required Battler owner,
  required Battler opponent,
  required Item item,
  required PassiveEffect effect,
  required bool isOwnerTurn,
});

/// Central execution registry for bespoke item behavior.
///
/// Standard attack, block and heal actions are resolved directly by battle.
/// Content-specific actions use a stable key so their behavior remains
/// serializable and does not depend on localized description text.
abstract final class ItemEffectDispatcher {
  static final Map<String, ItemCustomActionHandler> _customActions = {
    ItemEffectKeys.sunglasses: _resolveSunglasses,
    ItemEffectKeys.sHarpEner: _resolveSHarpEner,
  };
  static final Map<String, ItemPassiveEffectHandler> _passiveHandlers = {
    ItemEffectKeys.nanoBandageTurnStartHeal: _resolveNanoBandageTurnStartHeal,
  };

  static void registerCustomAction(
    String key,
    ItemCustomActionHandler handler,
  ) {
    _customActions[key] = handler;
  }

  static void registerPassive(
    String effectKey,
    ItemPassiveEffectHandler handler,
  ) {
    _passiveHandlers[effectKey] = handler;
  }

  static ItemEffectResolution resolveCustomAction({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    List<ActionEffect> previousActions = const <ActionEffect>[],
  }) {
    final key = effect.customEffectKey;
    final handler = key == null ? null : _customActions[key];
    return handler?.call(
          owner: owner,
          opponent: opponent,
          item: item,
          effect: effect,
          pattern: pattern,
          previousActions: previousActions,
        ) ??
        ItemEffectResolution(owner: owner, opponent: opponent);
  }

  static ItemEffectResolution resolvePassiveHook({
    required Battler owner,
    required Battler opponent,
    required ItemEffectHook hook,
    Item? onlyItem,
    bool isOwnerTurn = false,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;
    final items = onlyItem == null ? owner.equippedItems : <Item>[onlyItem];
    for (final item in items) {
      for (final effect in item.passiveEffects.where(
        (effect) => effect.hook == hook,
      )) {
        final handler = _passiveHandlers[effect.effectKey];
        if (handler == null) continue;
        final resolution = handler(
          owner: updatedOwner,
          opponent: updatedOpponent,
          item: item,
          effect: effect,
          isOwnerTurn: isOwnerTurn,
        );
        updatedOwner = resolution.owner;
        updatedOpponent = resolution.opponent;
      }
    }
    return ItemEffectResolution(
      owner: updatedOwner,
      opponent: updatedOpponent,
    );
  }

  static ItemEffectResolution _resolveSunglasses({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    return ItemEffectResolution(
      owner: owner,
      opponent: opponent,
      followUpActions: List<ActionEffect>.unmodifiable(previousActions),
    );
  }

  static ItemEffectResolution _resolveSHarpEner({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required ActionEffect effect,
    required BattlePatternMatchContext pattern,
    required List<ActionEffect> previousActions,
  }) {
    const sourceKey = 'item:s_harp_ener';
    final sourcePointKey = OperativePatternLayoutService.pointKeyForItem(
      player: owner,
      item: item,
    );
    if (sourcePointKey == null) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final sourcePoint = operativePatternPointsByKey[sourcePointKey];
    if (sourcePoint == null) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    var updatedOwner = owner;
    final boostedPointKeys = _adjacentPointKeys(sourcePoint);
    for (final targetItem in owner.equippedItems) {
      if (!targetItem.isWeaponLike) continue;
      final targetPointKey = OperativePatternLayoutService.pointKeyForItem(
        player: owner,
        item: targetItem,
      );
      if (targetPointKey == null || !boostedPointKeys.contains(targetPointKey)) {
        continue;
      }

      final currentBonus = targetItem.actionBonusValueForSource(
        actionType: ItemActionType.attack,
        sourceKey: sourceKey,
      );
      updatedOwner = updatedOwner.replaceOwnedItem(
        currentItem: targetItem,
        replacementItem: targetItem.withActionBonus(
          actionType: ItemActionType.attack,
          sourceKey: sourceKey,
          bonusValue: currentBonus + max(0, effect.totalValue),
        ),
      );
    }

    return ItemEffectResolution(owner: updatedOwner, opponent: opponent);
  }

  static Set<String> _adjacentPointKeys(OperativePatternPoint sourcePoint) {
    final pointKeys = <String>{};
    for (final offset in const [
      (dx: 0, dy: 1),
      (dx: 0, dy: -1),
      (dx: 1, dy: 0),
      (dx: -1, dy: 0),
    ]) {
      final point = operativePatternPointAt(
        x: sourcePoint.x + offset.dx,
        y: sourcePoint.y + offset.dy,
      );
      if (point != null) pointKeys.add(point.key);
    }
    return pointKeys;
  }

  static ItemEffectResolution _resolveNanoBandageTurnStartHeal({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required PassiveEffect effect,
    required bool isOwnerTurn,
  }) {
    return ItemEffectResolution(
      owner: isOwnerTurn ? owner.heal(effect.value) : owner,
      opponent: opponent,
    );
  }
}
