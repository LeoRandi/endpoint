import '../_imports.dart';

const _shopOwnedTileHeight = 48.0;
const _shopOfferHeight = 64.0;

EndpointScenePreset _buildShopScenePreset({
  required Color accent,
  required Color foreground,
  required Color mutedForeground,
  required Color panelBackground,
}) {
  return EndpointScenePreset(
    accent: accent,
    foreground: foreground,
    mutedForeground: mutedForeground,
    background: EndpointGradients.shop(accent),
    panelBackground: panelBackground,
    closeButtonBackground: panelBackground,
    viewportPadding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
  );
}

class WeaponShopPage extends StatefulWidget {
  final Battler player;
  final ShopPathNode shop;
  final RunRandomizer randomizer;
  final RunHourPhase phase;
  final int dayNumber;
  final List<Item> stockPool;

  const WeaponShopPage({
    super.key,
    required this.player,
    required this.shop,
    required this.randomizer,
    required this.phase,
    this.dayNumber = 1,
    this.stockPool = itemPresets,
  });

  @override
  State<WeaponShopPage> createState() => _WeaponShopPageState();
}

class _WeaponShopPageState extends State<WeaponShopPage> {
  late final WeaponShopController _controller;
  bool _isShopDescriptionOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = WeaponShopController(
      player: widget.player,
      stockCriterion: widget.shop.stockCriterion,
      phase: widget.phase,
      randomizer: widget.randomizer,
      shopRarity: widget.shop.rarity,
      dayNumber: widget.dayNumber,
      stockPool: widget.stockPool,
      priceMultiplier: widget.shop.priceMultiplier,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeShop() {
    Navigator.of(context).pop(_controller.buildResult());
  }

  Future<void> _openStockItemDetails(Item item) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de objeto en venta',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return EndpointItemDetailsDialog(
              item: item,
              accent: item.rarity.accent,
              price: _controller.purchasePriceFor(item),
              priceLabel: 'COMPRA',
              statusText: _controller.stockStatusLabelFor(item),
              actionLabel: _controller.stockActionLabelFor(item),
              onPrimaryAction: _controller.canBuy(item)
                  ? () {
                      _controller.buyItem(item);
                      Navigator.of(context).pop();
                    }
                  : null,
              isActionEnabled: _controller.canBuy(item),
              enabledActionTooltip:
                  _controller.stockPrimaryActionTooltipFor(item),
              disabledActionTooltip: 'No tienes dinero suficiente',
              showPrimaryActionUpgradeIndicator:
                  _controller.willUpgradeItem(item),
              primaryActionUpgradeIndicatorColor:
                  endpointUpgradeIndicatorNeonYellow,
            );
          },
        );
      },
    );
  }

  Future<void> _openInventoryItemDetails(Item item) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de objeto del inventario',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return EndpointItemDetailsDialog(
              item: item,
              accent: item.rarity.accent,
              price: _controller.sellPriceFor(item),
              priceLabel: 'VENTA',
              statusText: _controller.inventoryStatusLabelFor(item),
              secondaryActionLabel:
                  _controller.inventorySecondaryActionLabelFor(item),
              secondaryActionIcon: Icons.arrow_upward_rounded,
              onSecondaryAction: _controller.canEquipFromInventory(item)
                  ? () {
                      _controller.equipInventoryItem(item);
                    }
                  : null,
              isSecondaryActionEnabled: _controller.canEquipFromInventory(item),
              enabledSecondaryActionTooltip:
                  _controller.inventorySecondaryActionTooltipFor(item),
              disabledSecondaryActionTooltip:
                  _controller.inventorySecondaryActionTooltipFor(item),
            );
          },
        );
      },
    );
  }

  Future<void> _openEquippedItemDetails(Item item) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de objeto equipado',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return EndpointItemDetailsDialog(
              item: item,
              accent: item.rarity.accent,
              price: _controller.sellPriceFor(item),
              priceLabel: 'VENTA',
              statusText: _controller.equippedStatusLabelFor(item),
              secondaryActionLabel:
                  _controller.equippedSecondaryActionLabelFor(item),
              secondaryActionIcon: Icons.arrow_downward_rounded,
              onSecondaryAction: _controller.canUnequip(item)
                  ? () {
                      _controller.unequipItem(item);
                    }
                  : null,
              isSecondaryActionEnabled: _controller.canUnequip(item),
              enabledSecondaryActionTooltip:
                  _controller.equippedSecondaryActionTooltipFor(item),
              disabledSecondaryActionTooltip:
                  _controller.equippedSecondaryActionTooltipFor(item),
            );
          },
        );
      },
    );
  }

  void _buyStockItem(Item item) {
    _controller.buyItem(item);
  }

  void _sellOwnedItem(Item item) {
    _controller.sellItem(item);
  }

  void _equipOwnedItem(Item item) {
    _controller.equipInventoryItem(item);
  }

  void _unequipOwnedItem(Item item) {
    _controller.unequipItem(item);
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _closeShop();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final player = _controller.player;
          final stock = _controller.stock;
          final accent = shop.accent;
          final foreground = EndpointPalette.soften(accent);
          final mutedForeground = EndpointPalette.softForeground.withAlpha(209);
          final panelBackground = EndpointPalette.blend(
            EndpointPalette.panelBackgroundGold,
            accent,
            0.08,
          );
          final scenePreset = _buildShopScenePreset(
            accent: accent,
            foreground: foreground,
            mutedForeground: mutedForeground,
            panelBackground: panelBackground,
          );

          return Scaffold(
            body: NodeSceneWrapper(
              showTitle: '',
              child: EndpointSceneLayout(
                preset: scenePreset,
                backdrop: _ShopBackdrop(accent: accent),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      children: [
                        _ShopTopBar(
                          shop: shop,
                          accent: accent,
                          foreground: foreground,
                          panelBackground: panelBackground,
                          isDescriptionOpen: _isShopDescriptionOpen,
                          onToggleDescription: () {
                            setState(() {
                              _isShopDescriptionOpen = !_isShopDescriptionOpen;
                            });
                          },
                          onClose: _closeShop,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 6,
                          child: _ShopDropTarget(
                            controller: _controller,
                            accent: accent,
                            foreground: foreground,
                            panelBackground: panelBackground,
                            onAcceptItem: _sellOwnedItem,
                            child: _ShopStockPanel(
                              stock: stock,
                              controller: _controller,
                              accent: accent,
                              foreground: foreground,
                              panelBackground: panelBackground,
                              onOpenDetails: _openStockItemDetails,
                              onBuy: _buyStockItem,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 5,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _ShopOwnedColumn(
                                      title: 'Equipped',
                                      countLabel:
                                          '${player.equippedItemCost}/${player.equipmentCapacity}',
                                      items: player.equippedItems,
                                      controller: _controller,
                                      foreground: foreground,
                                      emptyLabel: 'Sin objetos equipados.',
                                      onItemPressed: _openEquippedItemDetails,
                                      canAcceptItem:
                                          _controller.canEquipFromInventory,
                                      onAcceptItem: _equipOwnedItem,
                                      blockedDropLabel: 'Full capacity',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ShopOwnedColumn(
                                      title: 'Inventory',
                                      countLabel:
                                          '${player.inventoryItems.length}',
                                      items: player.inventoryItems,
                                      controller: _controller,
                                      foreground: foreground,
                                      emptyLabel: 'Inventario vacio.',
                                      onItemPressed: _openInventoryItemDetails,
                                      canAcceptItem: _controller.canUnequip,
                                      onAcceptItem: _unequipOwnedItem,
                                      blockedDropLabel: 'Already in inventory',
                                    ),
                                  ),
                                ],
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Align(
                                    alignment: const Alignment(0, 0.72),
                                    child: _CreditsCircle(
                                      value: player.money,
                                      accent: EndpointPalette.warningAccent,
                                      foreground:
                                          EndpointPalette.softForegroundWarm,
                                      backgroundColor: panelBackground,
                                      size: 42,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_isShopDescriptionOpen)
                      Positioned(
                        top: 58,
                        left: 76,
                        right: 54,
                        child: _ShopDescriptionPopup(
                          shop: shop,
                          accent: accent,
                          foreground: foreground,
                          panelBackground: panelBackground,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShopTopBar extends StatelessWidget {
  final ShopPathNode shop;
  final Color accent;
  final Color foreground;
  final Color panelBackground;
  final bool isDescriptionOpen;
  final VoidCallback onToggleDescription;
  final VoidCallback onClose;

  const _ShopTopBar({
    required this.shop,
    required this.accent,
    required this.foreground,
    required this.panelBackground,
    required this.isDescriptionOpen,
    required this.onToggleDescription,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          EndpointPanel(
            accent: accent,
            backgroundColor: panelBackground,
            padding: const EdgeInsets.all(5),
            borderRadius: 8,
            glowOpacity: 0.05,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Center(
                child: EndpointText(
                  shop.iconEmoji,
                  style: const TextStyle(fontSize: 24, height: 1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggleDescription,
                borderRadius: BorderRadius.circular(8),
                child: EndpointPanel(
                  accent: accent,
                  backgroundColor: panelBackground,
                  padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                  borderRadius: 8,
                  glowOpacity: 0.05,
                  child: Row(
                    children: [
                      Expanded(
                        child: EndpointMarqueeText(
                          shop.shopSubtitle,
                          style: textSmallBold.copyWith(
                            color: foreground,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isDescriptionOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: accent,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          EndpointSceneCloseButton(
            onPressed: onClose,
            tooltip: 'Salir de la tienda',
            accent: accent,
            foregroundColor: foreground,
            backgroundColor: panelBackground,
          ),
        ],
      ),
    );
  }
}

class _ShopDescriptionPopup extends StatelessWidget {
  final ShopPathNode shop;
  final Color accent;
  final Color foreground;
  final Color panelBackground;

  const _ShopDescriptionPopup({
    required this.shop,
    required this.accent,
    required this.foreground,
    required this.panelBackground,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      accent: accent,
      backgroundColor: EndpointPalette.blend(panelBackground, Colors.black, 0.2)
          .withValues(alpha: 0.98),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      borderRadius: 8,
      glowOpacity: 0.18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          EndpointText(
            shop.shopTitle,
            style: textMediumBold.copyWith(
              color: foreground,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          EndpointText(
            shop.shopSubtitle,
            maxLines: null,
            style: textSmallBold.copyWith(
              color: EndpointPalette.softForeground.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopDropTarget extends StatelessWidget {
  final WeaponShopController controller;
  final Color accent;
  final Color foreground;
  final Color panelBackground;
  final ValueChanged<Item> onAcceptItem;
  final Widget child;

  const _ShopDropTarget({
    required this.controller,
    required this.accent,
    required this.foreground,
    required this.panelBackground,
    required this.onAcceptItem,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Item>(
      onWillAcceptWithDetails: (details) => controller.canSell(details.data),
      onAcceptWithDetails: (details) => onAcceptItem(details.data),
      builder: (context, candidateItems, rejectedItems) {
        final item = candidateItems.isNotEmpty ? candidateItems.first : null;

        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (item != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent, width: 1.5),
                  ),
                  child: Center(
                    child: EndpointText(
                      'Sell item for ${controller.sellPriceFor(item)}',
                      textAlign: TextAlign.center,
                      style: textTitleMediumBold.copyWith(
                        color: foreground,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ShopStockPanel extends StatelessWidget {
  final List<Item> stock;
  final WeaponShopController controller;
  final Color accent;
  final Color foreground;
  final Color panelBackground;
  final ValueChanged<Item> onOpenDetails;
  final ValueChanged<Item> onBuy;

  const _ShopStockPanel({
    required this.stock,
    required this.controller,
    required this.accent,
    required this.foreground,
    required this.panelBackground,
    required this.onOpenDetails,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final canReroll = controller.canRerollStock;

    return EndpointPanel(
      accent: accent,
      backgroundColor: panelBackground,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      borderRadius: 8,
      glowOpacity: 0.08,
      child: Column(
        children: [
          Expanded(
            child: stock.isEmpty
                ? Center(
                    child: EndpointText(
                      'No queda mercancia a la venta.',
                      textAlign: TextAlign.center,
                      maxLines: null,
                      style: textSmallBold.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var index = 0; index < stock.length; index++) ...[
                          _ShopOfferRow(
                            item: stock[index],
                            foreground: foreground,
                            price: controller.purchasePriceFor(stock[index]),
                            canBuy: controller.canBuy(stock[index]),
                            onPressed: () => onOpenDetails(stock[index]),
                            onBuy: () => onBuy(stock[index]),
                          ),
                          if (index < stock.length - 1)
                            const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Divider(
            height: 1,
            thickness: 1.5,
            color: accent.withValues(alpha: 0.62),
          ),
          const SizedBox(height: 6),
          Opacity(
            opacity: canReroll ? 1 : 0.42,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canReroll ? controller.rerollStock : null,
                borderRadius: BorderRadius.circular(8),
                child: EndpointPanel(
                  accent: accent,
                  backgroundColor: EndpointPalette.blend(
                    EndpointPalette.controlBackground,
                    accent,
                    canReroll ? 0.1 : 0.02,
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
                  borderRadius: 8,
                  glowOpacity: canReroll ? 0.05 : 0,
                  child: Row(
                    children: [
                      Expanded(
                        child: EndpointText(
                          'Reroll',
                          style: textMediumBold.copyWith(
                            color: foreground,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _PriceCircle(
                        value: controller.rerollCost,
                        accent: accent,
                        foreground: foreground,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopOfferRow extends StatelessWidget {
  final Item item;
  final int price;
  final bool canBuy;
  final Color foreground;
  final VoidCallback onPressed;
  final VoidCallback onBuy;

  const _ShopOfferRow({
    required this.item,
    required this.price,
    required this.canBuy,
    required this.foreground,
    required this.onPressed,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final itemAccent = item.rarity.accent;

    return SizedBox(
      height: _shopOfferHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: EndpointPanel(
            accent: itemAccent,
            backgroundColor: EndpointPalette.blend(
              EndpointPalette.panelBackgroundSoft,
              itemAccent,
              0.14,
            ),
            borderRadius: 8,
            glowOpacity: 0.04,
            padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
            child: Row(
              children: [
                _ItemIconBox(
                  accent: itemAccent,
                  emoji: item.iconEmoji,
                  size: 42,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: EndpointMarqueeText(
                    '${item.displayName}: ${item.tooltipDescription}',
                    style: textSmallBold.copyWith(
                      color: foreground,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Opacity(
                  opacity: canBuy ? 1 : 0.42,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: canBuy ? onBuy : null,
                    child: _PriceCircle(
                      value: price,
                      accent: itemAccent,
                      foreground: foreground,
                    ),
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

class _ShopOwnedColumn extends StatelessWidget {
  final String title;
  final String countLabel;
  final List<Item> items;
  final WeaponShopController controller;
  final Color foreground;
  final String emptyLabel;
  final ValueChanged<Item> onItemPressed;
  final bool Function(Item item) canAcceptItem;
  final ValueChanged<Item> onAcceptItem;
  final String blockedDropLabel;

  const _ShopOwnedColumn({
    required this.title,
    required this.countLabel,
    required this.items,
    required this.controller,
    required this.foreground,
    required this.emptyLabel,
    required this.onItemPressed,
    required this.canAcceptItem,
    required this.onAcceptItem,
    required this.blockedDropLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 18,
          child: Row(
            children: [
              Expanded(
                child: EndpointText(
                  title,
                  style: textSmallBold.copyWith(
                    color: foreground,
                    fontSize: 11,
                  ),
                ),
              ),
              EndpointText(
                countLabel,
                style: textSmallNumericBold.copyWith(
                  color: EndpointPalette.softForeground,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: DragTarget<Item>(
            onWillAcceptWithDetails: (details) {
              return canAcceptItem(details.data);
            },
            onAcceptWithDetails: (details) {
              onAcceptItem(details.data);
            },
            builder: (context, candidateItems, rejectedItems) {
              final canDrop = candidateItems.isNotEmpty;
              final blockedDrop = rejectedItems.isNotEmpty;

              return Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: canDrop || blockedDrop
                          ? Border.all(
                              color: canDrop
                                  ? foreground
                                  : EndpointPalette.dangerAccent,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: EndpointPanel(
                      accent: foreground,
                      backgroundColor: EndpointPalette.panelBackgroundSoft,
                      padding: const EdgeInsets.all(6),
                      borderRadius: 8,
                      glowOpacity: canDrop ? 0.1 : 0.03,
                      child: items.isEmpty
                          ? Center(
                              child: EndpointText(
                                emptyLabel,
                                textAlign: TextAlign.center,
                                maxLines: null,
                                style: textSmallBold.copyWith(
                                  color: Colors.white.withValues(alpha: 0.68),
                                  fontSize: 11,
                                ),
                              ),
                            )
                          : GridView.builder(
                              itemCount: items.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                                mainAxisExtent: _shopOwnedTileHeight,
                              ),
                              itemBuilder: (context, index) {
                                final item = items[index];

                                return _DraggableOwnedShopTile(
                                  item: item,
                                  price: controller.sellPriceFor(item),
                                  onPressed: () => onItemPressed(item),
                                );
                              },
                            ),
                    ),
                  ),
                  if (canDrop || blockedDrop)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: canDrop ? 0.34 : 0.58,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: EndpointText(
                            canDrop ? 'Drop item' : blockedDropLabel,
                            textAlign: TextAlign.center,
                            style: textSmallBold.copyWith(
                              color: canDrop
                                  ? foreground
                                  : EndpointPalette.dangerAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DraggableOwnedShopTile extends StatelessWidget {
  final Item item;
  final int price;
  final VoidCallback onPressed;

  const _DraggableOwnedShopTile({
    required this.item,
    required this.price,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final tile = _OwnedShopTile(
      item: item,
      price: price,
      onPressed: onPressed,
    );

    return Draggable<Item>(
      data: item,
      maxSimultaneousDrags: 1,
      rootOverlay: true,
      feedback: SizedBox(
        width: 78,
        height: _shopOwnedTileHeight,
        child: Material(
          color: Colors.transparent,
          child: _OwnedShopTile(
            item: item,
            price: price,
            onPressed: null,
            glowOpacity: 0.16,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.45,
        child: tile,
      ),
      child: tile,
    );
  }
}

class _OwnedShopTile extends StatelessWidget {
  final Item item;
  final int price;
  final VoidCallback? onPressed;
  final double glowOpacity;

  const _OwnedShopTile({
    required this.item,
    required this.price,
    required this.onPressed,
    this.glowOpacity = 0.04,
  });

  @override
  Widget build(BuildContext context) {
    final accent = item.rarity.accent;

    return HoldTooltip(
      message: item.tooltipDescription,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: EndpointPanel(
            accent: accent,
            backgroundColor: EndpointPalette.blend(
              EndpointPalette.controlBackground,
              accent,
              0.08,
            ),
            borderRadius: 8,
            glowOpacity: glowOpacity,
            padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: EndpointText(
                      item.iconEmoji,
                      style: const TextStyle(fontSize: 20, height: 1),
                    ),
                  ),
                ),
                _MiniPricePill(
                  value: price,
                  accent: accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemIconBox extends StatelessWidget {
  final Color accent;
  final String emoji;
  final double size;

  const _ItemIconBox({
    required this.accent,
    required this.emoji,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.7)),
      ),
      alignment: Alignment.center,
      child: EndpointText(
        emoji,
        style: TextStyle(fontSize: size * 0.45, height: 1),
      ),
    );
  }
}

class _PriceCircle extends StatelessWidget {
  final int value;
  final Color accent;
  final Color foreground;

  const _PriceCircle({
    required this.value,
    required this.accent,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.22),
        border: Border.all(color: accent, width: 2),
      ),
      alignment: Alignment.center,
      child: EndpointText(
        '$value',
        style: textSmallNumericBold.copyWith(
          color: foreground,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _MiniPricePill extends StatelessWidget {
  final int value;
  final Color accent;

  const _MiniPricePill({
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.24),
        border: Border.all(color: accent, width: 1.5),
      ),
      alignment: Alignment.center,
      child: EndpointText(
        '$value',
        style: textSmallNumericBold.copyWith(
          color: EndpointPalette.softForeground,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _CreditsCircle extends StatelessWidget {
  final int value;
  final Color accent;
  final Color foreground;
  final Color backgroundColor;
  final double size;

  const _CreditsCircle({
    required this.value,
    required this.accent,
    required this.foreground,
    required this.backgroundColor,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      accent: accent,
      backgroundColor: EndpointPalette.blend(backgroundColor, Colors.black, 0.2)
          .withValues(alpha: 0.96),
      padding: EdgeInsets.zero,
      borderRadius: 999,
      borderOpacity: 0.95,
      glowOpacity: 0.14,
      child: SizedBox(
        width: size,
        height: size,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monetization_on_rounded,
              color: accent,
              size: size * 0.28,
            ),
            EndpointText(
              '$value',
              style: textSmallNumericBold.copyWith(
                color: foreground,
                fontSize: size * 0.24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopBackdrop extends StatelessWidget {
  final Color accent;

  const _ShopBackdrop({
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ShopBackdropPainter(accent: accent),
      ),
    );
  }
}

class _ShopBackdropPainter extends CustomPainter {
  final Color accent;

  const _ShopBackdropPainter({
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = accent.withAlpha(31)
      ..strokeWidth = 1;
    final beamPaint = Paint()
      ..color = accent.withAlpha(46)
      ..strokeWidth = 2;

    for (double y = 28; y <= size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final beamOffsets = [
      size.width * 0.22,
      size.width * 0.5,
      size.width * 0.78,
    ];

    for (final dx in beamOffsets) {
      canvas.drawLine(
        Offset(dx, size.height * 0.18),
        Offset(dx, size.height * 0.82),
        beamPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShopBackdropPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
