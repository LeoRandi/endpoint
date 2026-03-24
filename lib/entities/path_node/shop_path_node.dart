import '_imports.dart';

class ShopPathNode extends PathNode {
  final String showTitle;
  final String shopTitle;
  final String shopSubtitle;
  final List<Item> catalog;
  final double priceMultiplier;

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
    this.priceMultiplier = 1,
    required List<Item> catalog,
  })  : catalog = List<Item>.unmodifiable(catalog),
        super.base(
          type: PathNodeType.shop,
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: rarity,
          accent: accent,
          badgeLabel: badgeLabel,
        );

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
      priceMultiplier: multiplier,
      catalog: catalog,
    );
  }
}
