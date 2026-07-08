import '../entities/_exports.dart';

/// Describes where an item currently lives for one battler snapshot.
enum ControllerItemPlacement {
  equipped,
  inventory,
  unavailable,
}

/// Presentation data for an item action inside controller-owned dialogs.
class ControllerItemActionPresentation {
  final ControllerItemPlacement placement;
  final String statusLabel;
  final String? actionLabel;
  final bool isActionEnabled;
  final String enabledActionTooltip;
  final String disabledActionTooltip;

  /// Creates immutable presentation data for a controller item action.
  const ControllerItemActionPresentation({
    required this.placement,
    required this.statusLabel,
    required this.actionLabel,
    required this.isActionEnabled,
    required this.enabledActionTooltip,
    required this.disabledActionTooltip,
  });

  /// Indicates whether the item is still owned by the battler snapshot.
  bool get isAvailable => placement != ControllerItemPlacement.unavailable;
}

/// Shared UI copy helpers for controller-level dialog labels and tooltips.
///
/// Controllers sit between immutable domain models and visual widgets. Keeping
/// repeated status wording here prevents battle and operative controllers from
/// drifting apart while still leaving localization migration to the app layer.
abstract final class ControllerUiText {
  static const itemUnavailableTooltip = 'El objeto ya no esta disponible';
  static const unequipItemTooltip = 'Quitar objeto del equipo activo';
  static const unavailableItemStatusLabel = 'Estado actual: no disponible';
  static const equippedItemStatusLabel = 'Estado actual: equipado';
  static const inventoryItemStatusLabel = 'Estado actual: en inventario';

  /// Resolves where [item] currently lives inside [owner].
  static ControllerItemPlacement itemPlacement({
    required Battler owner,
    required Item item,
  }) {
    if (owner.equippedItems.contains(item)) {
      return ControllerItemPlacement.equipped;
    }
    if (owner.inventoryItems.contains(item)) {
      return ControllerItemPlacement.inventory;
    }
    return ControllerItemPlacement.unavailable;
  }

  /// Builds the status sentence used by item detail dialogs.
  ///
  /// The same item can be shown from inventory, equipment slots, battle, or
  /// operative panels, so the controller always checks ownership against the
  /// current [owner] snapshot instead of trusting the stale tile item source.
  static String itemStatusLabel({
    required Battler owner,
    required Item item,
  }) {
    return switch (itemPlacement(owner: owner, item: item)) {
      ControllerItemPlacement.equipped => equippedItemStatusLabel,
      ControllerItemPlacement.inventory => inventoryItemStatusLabel,
      ControllerItemPlacement.unavailable => unavailableItemStatusLabel,
    };
  }

  /// Returns the primary action label for toggling an equippable player item.
  ///
  /// Callers still decide whether the action is enabled; this helper only keeps
  /// the visible equip/unequip wording consistent.
  static String? itemToggleActionLabel({
    required Battler owner,
    required Item item,
  }) {
    return itemToggleActionPresentation(owner: owner, item: item).actionLabel;
  }

  /// Returns the remove label for an equipped item when the current screen can
  /// edit the [owner].
  static String? unequipActionLabel({
    required Battler owner,
    required Item item,
    required bool canUnequip,
  }) {
    return equippedItemActionPresentation(
      owner: owner,
      item: item,
      canUnequip: canUnequip,
    ).actionLabel;
  }

  /// Builds the positive tooltip for equipping [item] on [owner].
  ///
  /// The next cost is derived from the current owner snapshot, which keeps drag
  /// and dialog tooltips synchronized after equipment changes.
  static String equipItemTooltip({
    required Battler owner,
    required Item item,
  }) {
    if (owner.equippedItems.contains(item)) return unequipItemTooltip;
    final nextCost = owner.equippedItemCost + 1;
    return 'Equipar objeto al jugador ($nextCost/${owner.equipmentCapacity})';
  }

  /// Builds all UI decisions for the common equip/unequip toggle action.
  static ControllerItemActionPresentation itemToggleActionPresentation({
    required Battler owner,
    required Item item,
  }) {
    final placement = itemPlacement(owner: owner, item: item);
    final actionLabel = switch (placement) {
      ControllerItemPlacement.equipped when item.isEquippable => 'Quitar',
      ControllerItemPlacement.inventory when item.isEquippable => 'Equipar',
      _ => null,
    };
    final isEnabled = switch (placement) {
      ControllerItemPlacement.equipped => owner.hasInventorySpace,
      ControllerItemPlacement.inventory => owner.canEquipItem(item),
      ControllerItemPlacement.unavailable => false,
    };
    final disabledTooltip = switch (placement) {
      ControllerItemPlacement.equipped =>
        'Inventario lleno (${Battler.maxInventoryItems}/${Battler.maxInventoryItems})',
      ControllerItemPlacement.inventory =>
        owner.equipItemBlockReason(item) ?? itemUnavailableTooltip,
      ControllerItemPlacement.unavailable => itemUnavailableTooltip,
    };

    return ControllerItemActionPresentation(
      placement: placement,
      statusLabel: itemStatusLabel(owner: owner, item: item),
      actionLabel: actionLabel,
      isActionEnabled: isEnabled,
      enabledActionTooltip: equipItemTooltip(owner: owner, item: item),
      disabledActionTooltip: disabledTooltip,
    );
  }

  /// Builds UI decisions for removing an equipped item back to inventory.
  static ControllerItemActionPresentation equippedItemActionPresentation({
    required Battler owner,
    required Item item,
    required bool canUnequip,
  }) {
    final placement = itemPlacement(owner: owner, item: item);
    final isEnabled = canUnequip &&
        placement == ControllerItemPlacement.equipped &&
        owner.hasInventorySpace;

    return ControllerItemActionPresentation(
      placement: placement,
      statusLabel: itemStatusLabel(owner: owner, item: item),
      actionLabel: isEnabled ? 'Quitar' : null,
      isActionEnabled: isEnabled,
      enabledActionTooltip: unequipItemTooltip,
      disabledActionTooltip: placement == ControllerItemPlacement.equipped
          ? 'Inventario lleno (${Battler.maxInventoryItems}/${Battler.maxInventoryItems})'
          : 'El objeto ya no esta equipado',
    );
  }
}
