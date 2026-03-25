import '_imports.dart';

const _inventoryTileExtent = 70.0;
const _inventoryTileHeight = 84.0;
class EndpointInventoryOverlay extends StatelessWidget {
  final Battler player;
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
    required this.player,
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
    final availableHeight = MediaQuery.of(context).size.height;
    final overlayHeight = max(
      220.0,
      min(maxHeight, availableHeight - bottomInset - 40),
    );

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: overlayHeight,
            ),
            child: EndpointPanel(
              accent: accent,
              backgroundColor: EndpointPalette.panelBackgroundOpaque,
              borderRadius: 18,
              glowOpacity: 0.12,
              blurRadius: 22,
              spreadRadius: 2,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EndpointText(
                              title,
                              style: textMediumBold.copyWith(
                                color: EndpointPalette.softForeground,
                                letterSpacing: 1.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            EndpointText(
                              subtitle,
                              style: textSmallBold.copyWith(
                                color: Colors.white.withOpacity(0.72),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      EndpointSceneCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: closeTooltip,
                        accent: accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      EndpointText(
                        'OBJETOS',
                        style: textSmallBold.copyWith(
                          color: accent,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Spacer(),
                      EndpointText(
                        '${items.length}',
                        style: textSmallBold.copyWith(
                          color: Colors.white.withOpacity(0.76),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
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
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: _inventoryTileExtent,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              mainAxisExtent: _inventoryTileHeight,
                            ),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return EndpointInventoryItemTile(
                                item: item,
                                onPressed: () =>
                                    _openItemDetails(context, item),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
