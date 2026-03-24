import '_imports.dart';

const _inventoryTileExtent = 70.0;
const _inventoryTileHeight = 84.0;
const _inventoryTileEmojiSize = 18.0;

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
    this.accent = const Color(0xFF5AF78E),
    this.bottomInset = 112,
    this.maxWidth = 360,
    this.maxHeight = 340,
    this.priceBuilder,
  });

  Future<void> _openItemDetails(BuildContext context, Item item) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Detalle de objeto',
      barrierColor: Colors.black.withOpacity(0.62),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return EndpointItemDetailsDialog(
          item: item,
          player: player,
          accent: item.rarity.accent,
          price: priceBuilder?.call(item) ?? item.cost,
          statusText: detailStatusBuilder(item),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
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
              backgroundColor: const Color(0xF107120D),
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
                                color: const Color(0xFFE6FFF0),
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
                              return _InventoryOverlayItemTile(
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

class _InventoryOverlayItemTile extends StatelessWidget {
  final Item item;
  final VoidCallback onPressed;

  const _InventoryOverlayItemTile({
    required this.item,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return HoldTooltip(
      message: item.description,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: EndpointPanel(
            backgroundColor: const Color(0xCC07120D),
            borderRadius: 12,
            glowOpacity: 0.03,
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/slots/equipment_slot_base.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                      ),
                      Center(
                        child: EndpointText(
                          item.iconEmoji,
                          style: const TextStyle(
                            fontSize: _inventoryTileEmojiSize,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                EndpointText(
                  item.name,
                  textAlign: TextAlign.center,
                  style: textSmallBold.copyWith(
                    color: const Color(0xFFE6FFF0),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
