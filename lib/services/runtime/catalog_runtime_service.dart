import '_imports.dart';

/// Centraliza el paso de presets compartidos a instancias runtime.
///
/// Los presets siguen siendo tablas canonicas e inmutables; este servicio marca
/// los puntos donde un item, habilidad o battler entra en una run y debe quedar
/// limpio de estado temporal antes de guardarse o mutarse.
class CatalogRuntimeService {
  const CatalogRuntimeService();

  /// Devuelve una copia runtime de [template] lista para pertenecer a un jugador.
  Item runtimeItem(
    Item template, {
    bool forceNewInstance = false,
  }) {
    return template.toRuntimeInstance(forceNewInstance: forceNewInstance);
  }

  /// Resuelve un item por id y lo materializa como copia runtime propia.
  Item runtimeItemForId(
    ItemId id, {
    bool forceNewInstance = false,
  }) {
    return runtimeItem(
      Item.presetForId(id),
      forceNewInstance: forceNewInstance,
    );
  }

  /// Devuelve una habilidad sin cooldowns, flags activos ni bonus temporales.
  BattlerAbility runtimeAbility(BattlerAbility template) {
    return template.toRuntimeInstance();
  }

  /// Resuelve una habilidad por id y la limpia para entrar en estado runtime.
  BattlerAbility runtimeAbilityForId(BattlerAbilityId id) {
    return runtimeAbility(BattlerAbility.presetForId(id));
  }

  /// Promociona un item hasta una rareza exacta; devuelve null si no puede llegar.
  Item? promoteItemToExactRarity(Item template, RarityTier targetRarity) {
    if (template.rarity.index > targetRarity.index) return null;

    var promotedItem = template;
    while (promotedItem.rarity.index < targetRarity.index &&
        promotedItem.canUpgrade) {
      promotedItem = promotedItem.upgraded();
    }

    if (promotedItem.rarity != targetRarity) return null;

    return runtimeItem(promotedItem);
  }

  /// Promociona una habilidad hasta una rareza exacta; devuelve null si no puede llegar.
  BattlerAbility? promoteAbilityToExactRarity(
    BattlerAbility template,
    RarityTier targetRarity,
  ) {
    if (template.rarity.index > targetRarity.index) return null;

    var promotedAbility = runtimeAbility(template);
    while (promotedAbility.rarity.index < targetRarity.index &&
        promotedAbility.canUpgrade) {
      promotedAbility = promotedAbility.upgraded();
    }

    if (promotedAbility.rarity != targetRarity) return null;

    return runtimeAbility(promotedAbility);
  }

  /// Promociona una habilidad al menos hasta la rareza indicada.
  BattlerAbility promoteAbilityToAtLeastRarity(
    BattlerAbility template,
    RarityTier targetRarity,
  ) {
    var promotedAbility = runtimeAbility(template);
    while (promotedAbility.rarity.index < targetRarity.index &&
        promotedAbility.canUpgrade) {
      promotedAbility = promotedAbility.upgraded();
    }
    if (promotedAbility.rarity.index >= targetRarity.index) {
      return runtimeAbility(promotedAbility);
    }

    return runtimeAbility(promotedAbility.copyWith(rarity: targetRarity));
  }

  /// Limpia un battler de preset para usarlo como combatiente de una escena.
  Battler runtimeBattler(Battler template) {
    return template.materializeOwnedItems().resetAllAbilities();
  }
}
