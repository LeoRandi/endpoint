import '_imports.dart';

typedef ItemCustomActionHandler = ItemEffectResolution Function({
  required Battler owner,
  required Battler opponent,
  required ActionEffect effect,
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
    required ActionEffect effect,
    List<ActionEffect> previousActions = const <ActionEffect>[],
  }) {
    final key = effect.customEffectKey;
    final handler = key == null ? null : _customActions[key];
    return handler?.call(
          owner: owner,
          opponent: opponent,
          effect: effect,
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
    required ActionEffect effect,
    required List<ActionEffect> previousActions,
  }) {
    return ItemEffectResolution(
      owner: owner,
      opponent: opponent,
      followUpActions: List<ActionEffect>.unmodifiable(previousActions),
    );
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
