import '../entities/_exports.dart';

/// Shared UI copy helpers for controller-level dialog labels and tooltips.
///
/// Controllers sit between immutable domain models and visual widgets. Keeping
/// repeated status wording here prevents battle and operative controllers from
/// drifting apart while still leaving localization migration to the app layer.
abstract final class ControllerUiText {
  static const itemUnavailableTooltip = 'El objeto ya no esta disponible';
  static const unequipItemTooltip = 'Quitar objeto del equipo activo';

  /// Builds the status sentence used by item detail dialogs.
  ///
  /// The same item can be shown from inventory, equipment slots, battle, or
  /// operative panels, so the controller always checks ownership against the
  /// current [owner] snapshot instead of trusting the stale tile item source.
  static String itemStatusLabel({
    required Battler owner,
    required Item item,
  }) {
    if (owner.equippedItems.contains(item)) {
      return 'Estado actual: equipado';
    }
    if (owner.inventoryItems.contains(item)) {
      return 'Estado actual: en inventario';
    }
    return 'Estado actual: no disponible';
  }

  /// Returns the primary action label for toggling an equippable player item.
  ///
  /// Callers still decide whether the action is enabled; this helper only keeps
  /// the visible equip/unequip wording consistent.
  static String? itemToggleActionLabel({
    required Battler owner,
    required Item item,
  }) {
    if (!item.isEquippable) return null;
    if (owner.equippedItems.contains(item)) return 'Quitar';
    if (owner.inventoryItems.contains(item)) return 'Equipar';
    return null;
  }

  /// Returns the remove label for an equipped item when the current screen can
  /// edit the [owner].
  static String? unequipActionLabel({
    required Battler owner,
    required Item item,
    required bool canUnequip,
  }) {
    if (!canUnequip) return null;
    if (owner.equippedItems.contains(item)) return 'Quitar';
    return null;
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
}
