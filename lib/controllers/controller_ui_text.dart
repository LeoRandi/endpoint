import '../entities/_exports.dart';

/// Shared UI copy helpers for controller-level dialog labels and tooltips.
///
/// Controllers sit between immutable domain models and visual widgets. Keeping
/// repeated status wording here prevents battle, ability, and operative
/// controllers from drifting apart while still leaving localization migration to
/// the app layer.
abstract final class ControllerUiText {
  static const abilityNotImplementedTooltip =
      'La habilidad aun no esta implementada';
  static const abilityUnavailableTooltip =
      'No se puede activar desde esta pantalla';
  static const itemUnavailableTooltip = 'El objeto ya no esta disponible';
  static const manageOwnAbilitiesTooltip =
      'Solo puedes gestionar habilidades propias';
  static const playerTurnAbilityTooltip =
      'Solo puedes gestionar habilidades en tu turno';
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

  /// Builds the status sentence for the current lifecycle of [ability].
  ///
  /// Passive, active, cooldown, and ready states are represented in multiple
  /// dialogs; this method keeps their exact wording stable across controllers.
  static String abilityStateSentence(BattlerAbility ability) {
    if (ability.isPassive) return 'Estado actual: pasiva.';
    if (ability.isActive) return 'Estado actual: activa.';
    if (ability.isOnCooldown) {
      return 'Estado actual: en cooldown (${ability.remainingCooldownLabel}).';
    }
    return 'Estado actual: lista.';
  }

  /// Builds the activation sentence for [ability].
  ///
  /// This separates manual activation context text from the ability state so
  /// battle dialogs can insert ownership copy between the two pieces.
  static String abilityActivationSentence(BattlerAbility ability) {
    final context = ability.manualActivationContext;
    if (context == null) return 'Se aplica sin activacion manual.';
    return 'Se puede activar manualmente en ${context.label}.';
  }

  /// Combines ability state, optional [ownershipSentence], and activation copy
  /// into the dialog status paragraph.
  static String abilityStatusText(
    BattlerAbility ability, {
    String? ownershipSentence,
  }) {
    final parts = <String>[
      abilityStateSentence(ability),
      if (ownershipSentence != null) ownershipSentence,
      abilityActivationSentence(ability),
    ];
    return parts.join(' ');
  }

  /// Returns the visible label for a manual ability toggle.
  ///
  /// Controllers call this only after verifying that the current screen exposes
  /// a toggle action for the ability.
  static String abilityToggleActionLabel(BattlerAbility ability) {
    return ability.isActive ? 'Desactivar' : 'Activar';
  }

  /// Returns the common fallback tooltip for an ability that cannot be enabled.
  ///
  /// Screen-specific blocks such as "not your turn" are handled before this
  /// helper; this method covers implementation and cooldown state shared by all
  /// manual-activation surfaces.
  static String abilityUnavailableReason(BattlerAbility ability) {
    if (!ability.isImplemented) return abilityNotImplementedTooltip;
    if (ability.isOnCooldown) {
      return 'Recarga restante: ${ability.remainingCooldownLabel}';
    }
    return abilityUnavailableTooltip;
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
