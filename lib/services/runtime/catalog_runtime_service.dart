import '_imports.dart';

/// Centraliza el paso de presets compartidos a instancias runtime.
///
/// Los presets siguen siendo tablas canonicas e inmutables; este servicio marca
/// los puntos donde un item, aumento o battler entra en una run y debe quedar
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

  /// Resuelve un item por clave de catalogo y lo materializa como copia runtime.
  Item runtimeItemForKey(
    String catalogKey, {
    bool forceNewInstance = false,
  }) {
    return runtimeItem(
      Item.presetForKey(catalogKey),
      forceNewInstance: forceNewInstance,
    );
  }

  Augment runtimeAugment(Augment template) {
    return template;
  }

  Augment runtimeAugmentForId(int id) {
    final augment = augmentCatalogById[id];
    if (augment == null) {
      throw StateError('No augment exists for id $id.');
    }
    return runtimeAugment(augment);
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

  Augment? promoteAugmentToExactRarity(
    Augment template,
    RarityTier targetRarity,
  ) {
    if (template.rarity.index > targetRarity.index) return null;

    var promotedAugment = runtimeAugment(template);
    while (promotedAugment.rarity.index < targetRarity.index &&
        promotedAugment.canUpgrade) {
      promotedAugment = promotedAugment.upgraded();
    }

    if (promotedAugment.rarity != targetRarity) return null;

    return runtimeAugment(promotedAugment);
  }

  Augment promoteAugmentToAtLeastRarity(
    Augment template,
    RarityTier targetRarity,
  ) {
    var promotedAugment = runtimeAugment(template);
    while (promotedAugment.rarity.index < targetRarity.index &&
        promotedAugment.canUpgrade) {
      promotedAugment = promotedAugment.upgraded();
    }
    if (promotedAugment.rarity.index >= targetRarity.index) {
      return runtimeAugment(promotedAugment);
    }

    return runtimeAugment(promotedAugment.copyWith(tier: targetRarity));
  }

  /// Limpia un battler de preset para usarlo como combatiente de una escena.
  Battler runtimeBattler(Battler template) {
    return template.materializeOwnedItems();
  }
}
