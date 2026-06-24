import '_imports.dart';

typedef ItemCustomActionHandler = ItemEffectResolution Function({
  required Battler owner,
  required Battler opponent,
  required ActionEffect effect,
});

typedef ItemPassiveEffectHandler = ItemEffectResolution Function({
  required Battler owner,
  required Battler opponent,
  required Item item,
  required PassiveEffect effect,
});

/// Central execution registry for bespoke item behavior.
///
/// Standard attack, block and heal actions are resolved directly by battle.
/// Content-specific actions use a stable key so their behavior remains
/// serializable and does not depend on localized description text.
abstract final class ItemEffectDispatcher {
  static final Map<String, ItemCustomActionHandler> _customActions = {};
  static final Map<ItemEffectHook, ItemPassiveEffectHandler> _passiveHandlers =
      {};

  static void registerCustomAction(
    String key,
    ItemCustomActionHandler handler,
  ) {
    _customActions[key] = handler;
  }

  static void registerPassive(
    ItemEffectHook hook,
    ItemPassiveEffectHandler handler,
  ) {
    _passiveHandlers[hook] = handler;
  }

  static ItemEffectResolution resolveCustomAction({
    required Battler owner,
    required Battler opponent,
    required ActionEffect effect,
  }) {
    final key = effect.customEffectKey;
    final handler = key == null ? null : _customActions[key];
    return handler?.call(owner: owner, opponent: opponent, effect: effect) ??
        ItemEffectResolution(owner: owner, opponent: opponent);
  }

  static ItemEffectResolution resolvePassiveHook({
    required Battler owner,
    required Battler opponent,
    required ItemEffectHook hook,
    Item? onlyItem,
  }) {
    final handler = _passiveHandlers[hook];
    if (handler == null) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    var updatedOwner = owner;
    var updatedOpponent = opponent;
    final items = onlyItem == null ? owner.equippedItems : <Item>[onlyItem];
    for (final item in items) {
      for (final effect in item.passiveEffects.where(
        (effect) => effect.hook == hook,
      )) {
        final resolution = handler(
          owner: updatedOwner,
          opponent: updatedOpponent,
          item: item,
          effect: effect,
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
}
