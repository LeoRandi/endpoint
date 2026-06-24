import '../../entities/_exports.dart';

/// Names the combat event currently asking effects to resolve.
///
/// The pipeline still calls the existing effect methods, but routing through an
/// explicit event makes priority rules visible and extensible instead of hiding
/// them in one-off list helpers.
enum BattlerEffectEventType {
  attackResolved,
  turnEnd,
  patternUsed,
  forcedPatternUsed,
  patternMatchResolved,
}

/// Immutable event metadata used to order item and ability handlers.
class BattlerEffectEvent {
  final BattlerEffectEventType type;

  const BattlerEffectEvent(this.type);

  static const attackResolved = BattlerEffectEvent(
    BattlerEffectEventType.attackResolved,
  );
  static const turnEnd = BattlerEffectEvent(BattlerEffectEventType.turnEnd);
  static const patternUsed = BattlerEffectEvent(
    BattlerEffectEventType.patternUsed,
  );
  static const forcedPatternUsed = BattlerEffectEvent(
    BattlerEffectEventType.forcedPatternUsed,
  );
  static const patternMatchResolved = BattlerEffectEvent(
    BattlerEffectEventType.patternMatchResolved,
  );

  bool get defersContagioHandlers {
    switch (type) {
      case BattlerEffectEventType.attackResolved:
      case BattlerEffectEventType.patternUsed:
      case BattlerEffectEventType.forcedPatternUsed:
      case BattlerEffectEventType.patternMatchResolved:
        return true;
      case BattlerEffectEventType.turnEnd:
        return false;
    }
  }
}

/// Central priority policy for effect handlers.
///
/// Use this when adding mechanics that must run before or after another family
/// of effects. Keeping the ordering here avoids scattering priority hacks
/// through BattlerEffectPipeline.
abstract final class BattlerEffectPriorityPolicy {
  static List<Item> orderItemsForEvent({
    required BattlerEffectEvent event,
    required Iterable<Item> items,
  }) {
    Iterable<Item> orderedItems = items;

    if (event.defersContagioHandlers) {
      orderedItems = _deferItemsWhere(
        orderedItems,
        (item) => item.hasTag(EntityTag.contagio),
      );
    }
    return List<Item>.unmodifiable(orderedItems);
  }

  static List<BattlerAbilityId> orderAbilityIdsForEvent({
    required BattlerEffectEvent event,
    required Battler owner,
    required Iterable<BattlerAbilityId> abilityIds,
  }) {
    Iterable<BattlerAbilityId> orderedAbilityIds = abilityIds;

    if (event.defersContagioHandlers) {
      orderedAbilityIds = _deferAbilityIdsWhere(
        orderedAbilityIds,
        owner,
        (ability) => ability.hasTag(EntityTag.contagio),
      );
    }

    return List<BattlerAbilityId>.unmodifiable(orderedAbilityIds);
  }

  static List<Item> _deferItemsWhere(
    Iterable<Item> items,
    bool Function(Item item) shouldDefer,
  ) {
    final immediateItems = <Item>[];
    final deferredItems = <Item>[];
    for (final item in items) {
      if (shouldDefer(item)) {
        deferredItems.add(item);
      } else {
        immediateItems.add(item);
      }
    }

    return <Item>[...immediateItems, ...deferredItems];
  }

  static List<BattlerAbilityId> _deferAbilityIdsWhere(
    Iterable<BattlerAbilityId> abilityIds,
    Battler owner,
    bool Function(BattlerAbility ability) shouldDefer,
  ) {
    final immediateAbilityIds = <BattlerAbilityId>[];
    final deferredAbilityIds = <BattlerAbilityId>[];
    for (final abilityId in abilityIds) {
      final ability = owner.abilityById(abilityId);
      if (ability != null && shouldDefer(ability)) {
        deferredAbilityIds.add(abilityId);
      } else {
        immediateAbilityIds.add(abilityId);
      }
    }

    return <BattlerAbilityId>[...immediateAbilityIds, ...deferredAbilityIds];
  }
}
