import '_imports.dart';

class ShopPathNode extends PathNode {
  final String showTitle;
  final String shopTitle;
  final String shopSubtitle;
  final List<Item> catalog;

  ShopPathNode({
    required String label,
    required String tooltip,
    required String iconEmoji,
    required Color accent,
    required String badgeLabel,
    required this.showTitle,
    required this.shopTitle,
    required this.shopSubtitle,
    required List<Item> catalog,
  })  : catalog = List<Item>.unmodifiable(catalog),
        super.base(
          type: PathNodeType.shop,
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          accent: accent,
          badgeLabel: badgeLabel,
        );
}
