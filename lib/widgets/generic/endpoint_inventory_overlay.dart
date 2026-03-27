import '../_imports.dart';

const _inventoryTileExtent = 70.0;
const _inventoryTileHeight = 84.0;

class EndpointInventoryOverlay extends StatelessWidget {
  final List<Item> items;
  final String title;
  final String subtitle;
  final String emptyText;
  final String closeTooltip;
  final Color accent;
  final double bottomInset;
  final double maxWidth;
  final double maxHeight;
  final String Function(Item item) detailStatusBuilder;
  final int Function(Item item)? priceBuilder;

  const EndpointInventoryOverlay({
    super.key,
    required this.detailStatusBuilder,
    this.items = const [],
    this.title = 'Objetos',
    this.subtitle = 'Inventario',
    this.emptyText = EndpointStrings.noItems,
    this.closeTooltip = 'Cerrar inventario',
    this.accent = EndpointPalette.primaryAccent,
    this.bottomInset = 112,
    this.maxWidth = 360,
    this.maxHeight = 340,
    this.priceBuilder,
  });

  Future<void> _openItemDetails(BuildContext context, Item item) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de objeto',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return EndpointItemDetailsDialog(
          item: item,
          accent: item.rarity.accent,
          price: priceBuilder?.call(item) ?? item.cost,
          statusText: detailStatusBuilder(item),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return EndpointOverlayScaffold(
      title: title,
      subtitle: subtitle,
      sectionLabel: 'OBJETOS',
      sectionValue: '${items.length}',
      closeTooltip: closeTooltip,
      accent: accent,
      bottomInset: bottomInset,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      child: items.isEmpty
          ? Center(
              child: EndpointText(
                emptyText,
                textAlign: TextAlign.center,
                style: textSmallBold.copyWith(
                  color: Colors.white.withOpacity(0.72),
                ),
              ),
            )
          : GridView.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: _inventoryTileExtent,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: _inventoryTileHeight,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return EndpointInventoryItemTile(
                  item: item,
                  onPressed: () => _openItemDetails(context, item),
                );
              },
            ),
    );
  }
}
