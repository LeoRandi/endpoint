import '../_imports.dart';

/// Describe las reglas que debe cumplir un objeto para aparecer en una tienda.
class ShopInventoryCriterion {
  final String label;
  final String description;
  final ItemSlot? requiredSlot;
  final RarityTier? exactRarity;
  final RarityTier? minimumRarity;
  final BattlerStat? requiredPositiveModifierStat;

  /// Crea un criterio declarativo que puede combinar slot, rareza y stat requerida.
  const ShopInventoryCriterion({
    required this.label,
    required this.description,
    this.requiredSlot,
    this.exactRarity,
    this.minimumRarity,
    this.requiredPositiveModifierStat,
  }) : assert(exactRarity == null || minimumRarity == null);

  /// Comprueba si un objeto concreto cumple todas las reglas del criterio.
  bool matches(Item item) {
    if (requiredSlot != null && item.slot != requiredSlot) {
      return false;
    }
    if (exactRarity != null && item.rarity != exactRarity) {
      return false;
    }
    if (minimumRarity != null && item.rarity.index < minimumRarity!.index) {
      return false;
    }
    if (requiredPositiveModifierStat != null &&
        item.modifier(requiredPositiveModifierStat!) <= 0) {
      return false;
    }

    return true;
  }
}

/// Define una tienda de ruta con su criterio de stock y el multiplicador de precios aplicado.
class ShopPathNode extends PathNode {
  final String showTitle;
  final String shopTitle;
  final String shopSubtitle;
  final ShopInventoryCriterion stockCriterion;
  final double priceMultiplier;

  /// Crea una tienda concreta con su criterio de stock y multiplicador de precio.
  ShopPathNode({
    required String label,
    required String tooltip,
    required String iconEmoji,
    required RarityTier rarity,
    required Color accent,
    required String badgeLabel,
    required this.showTitle,
    required this.shopTitle,
    required this.shopSubtitle,
    required this.stockCriterion,
    this.priceMultiplier = 1,
  }) : super.base(
          type: PathNodeType.shop,
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: rarity,
          accent: accent,
          badgeLabel: badgeLabel,
        );

  /// Clona el nodo cambiando solo el multiplicador para variantes premium o rebajadas.
  ShopPathNode withPriceMultiplier(double multiplier) {
    return ShopPathNode(
      label: label,
      tooltip: tooltip,
      iconEmoji: iconEmoji,
      rarity: rarity,
      accent: accent,
      badgeLabel: badgeLabel,
      showTitle: showTitle,
      shopTitle: shopTitle,
      shopSubtitle: shopSubtitle,
      stockCriterion: stockCriterion,
      priceMultiplier: multiplier,
    );
  }
}
