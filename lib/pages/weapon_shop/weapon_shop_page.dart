import '../_imports.dart';

const _shopInventoryTileExtent = 66.0;
const _shopInventoryTileHeight = 80.0;
const _shopEquippedTileExtent = 58.0;
const _shopEquippedTileHeight = 70.0;
const _shopEquippedEmojiSize = 15.0;

class WeaponShopPage extends StatefulWidget {
  final Battler player;
  final ShopPathNode shop;
  final RunRandomizer randomizer;
  final RunHourPhase phase;

  const WeaponShopPage({
    super.key,
    required this.player,
    required this.shop,
    required this.randomizer,
    required this.phase,
  });

  @override
  State<WeaponShopPage> createState() => _WeaponShopPageState();
}

class _WeaponShopPageState extends State<WeaponShopPage> {
  late final WeaponShopController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WeaponShopController(
      player: widget.player,
      stockCriterion: widget.shop.stockCriterion,
      phase: widget.phase,
      randomizer: widget.randomizer,
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
              priceLabel: 'COMPRA (${_controller.purchasePriceFor(item)}C)',
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
                  'Comprar objeto por ${_controller.purchasePriceFor(item)}C',
              disabledActionTooltip: 'No tienes dinero suficiente',
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
              actionLabel: _controller.inventoryActionLabelFor(item),
              actionIcon: Icons.sell_outlined,
              onPrimaryAction: _controller.canSell(item)
                  ? () {
                      _controller.sellItem(item);
                      Navigator.of(context).pop();
                    }
                  : null,
              isActionEnabled: _controller.canSell(item),
              enabledActionTooltip: _controller.inventorySellTooltipFor(item),
              disabledActionTooltip: _controller.inventorySellTooltipFor(item),
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
              price: item.cost,
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

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
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
          final panelBackground = EndpointPalette.blend(
            EndpointPalette.panelBackgroundGold,
            accent,
            0.08,
          );

          return Scaffold(
            body: NodeSceneWrapper(
              showTitle: shop.showTitle,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: EndpointGradients.shop(accent),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ShopBackdrop(accent: accent),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: EndpointSceneCloseButton(
                                onPressed: _closeShop,
                                tooltip: 'Salir de la tienda',
                                accent: accent,
                                foregroundColor: foreground,
                                backgroundColor: panelBackground,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        SizedBox(
                                          width: 118,
                                          child: _ShopInfoColumn(
                                            shop: shop,
                                            accent: accent,
                                            foreground: foreground,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: EndpointPanel(
                                            accent: accent,
                                            backgroundColor: panelBackground,
                                            glowOpacity: 0.08,
                                            padding: const EdgeInsets.fromLTRB(
                                                8, 8, 8, 8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _ShopSectionHeader(
                                                  title: 'OBJETOS DISPONIBLES',
                                                  caption:
                                                      '${stock.length} EN TIENDA',
                                                  accent: accent,
                                                  foreground: foreground,
                                                ),
                                                const SizedBox(height: 10),
                                                Expanded(
                                                  child: stock.isEmpty
                                                      ? Center(
                                                          child: EndpointText(
                                                            'No queda mercancia a la venta.',
                                                            textAlign: TextAlign
                                                                .center,
                                                            maxLines: null,
                                                            style: textSmallBold
                                                                .copyWith(
                                                              color: Colors
                                                                  .white
                                                                  .withAlpha(
                                                                184,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : ListView.separated(
                                                          itemCount:
                                                              stock.length,
                                                          itemBuilder:
                                                              (context, index) {
                                                            final item =
                                                                stock[index];
                                                            return _ShopOfferCard(
                                                              item: item,
                                                              foreground:
                                                                  foreground,
                                                              price: _controller
                                                                  .purchasePriceFor(
                                                                item,
                                                              ),
                                                              statusLabel:
                                                                  _controller
                                                                      .stockStatusLabelFor(
                                                                item,
                                                              ),
                                                              onPressed: () =>
                                                                  _openStockItemDetails(
                                                                item,
                                                              ),
                                                            );
                                                          },
                                                          separatorBuilder:
                                                              (context,
                                                                      index) =>
                                                                  const SizedBox(
                                                            height: 10,
                                                          ),
                                                        ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: EndpointPanel(
                                      accent: accent,
                                      backgroundColor: panelBackground,
                                      glowOpacity: 0.06,
                                      padding:
                                          const EdgeInsets.fromLTRB(8, 8, 8, 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              final isCompact =
                                                  constraints.maxWidth < 420;
                                              final infoColumn = Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _ShopSectionHeader(
                                                    title: 'INVENTARIO',
                                                    caption:
                                                        '${player.inventoryItems.length} OBJETOS',
                                                    accent: accent,
                                                    foreground: foreground,
                                                  ),
                                                ],
                                              );

                                              if (isCompact) {
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    infoColumn,
                                                    const SizedBox(height: 10),
                                                    _ShopEconomyStrip(
                                                      money: player.money,
                                                      income: player.income,
                                                    ),
                                                  ],
                                                );
                                              }

                                              return Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: infoColumn),
                                                  const SizedBox(width: 12),
                                                  _ShopEconomyStrip(
                                                    money: player.money,
                                                    income: player.income,
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          Center(
                                            child: EndpointEquipmentSlotsStrip(
                                              battler: player,
                                              layout: EndpointEquipmentLayout
                                                  .standard,
                                              tileExtent:
                                                  _shopEquippedTileExtent,
                                              tileHeight:
                                                  _shopEquippedTileHeight,
                                              emojiSize: _shopEquippedEmojiSize,
                                              spacing: 6,
                                              borderColor:
                                                  accent.withAlpha(112),
                                              backgroundColor: EndpointPalette
                                                  .controlBackground,
                                              textColor: foreground,
                                              onItemPressed:
                                                  _openEquippedItemDetails,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Expanded(
                                            child: player.inventoryItems.isEmpty
                                                ? Center(
                                                    child: EndpointText(
                                                      'No llevas ningun objeto sin equipar.',
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: null,
                                                      style: textSmallBold
                                                          .copyWith(
                                                        color: Colors.white
                                                            .withAlpha(184),
                                                      ),
                                                    ),
                                                  )
                                                : GridView.builder(
                                                    itemCount: player
                                                        .inventoryItems.length,
                                                    gridDelegate:
                                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                                      maxCrossAxisExtent:
                                                          _shopInventoryTileExtent,
                                                      crossAxisSpacing: 8,
                                                      mainAxisSpacing: 8,
                                                      mainAxisExtent:
                                                          _shopInventoryTileHeight,
                                                    ),
                                                    itemBuilder:
                                                        (context, index) {
                                                      final item =
                                                          player.inventoryItems[
                                                              index];

                                                      return EndpointInventoryItemTile(
                                                        item: item,
                                                        onPressed: () =>
                                                            _openInventoryItemDetails(
                                                          item,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

class _ShopInfoColumn extends StatelessWidget {
  final ShopPathNode shop;
  final Color accent;
  final Color foreground;

  const _ShopInfoColumn({
    required this.shop,
    required this.accent,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: EndpointEmojiSprite(
              emoji: shop.iconEmoji,
              accent: accent,
              size: 74,
            ),
          ),
          const SizedBox(height: 10),
          EndpointText(
            shop.shopTitle,
            maxLines: null,
            style: textMediumBold.copyWith(
              color: foreground,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          EndpointText(
            shop.shopSubtitle,
            maxLines: null,
            style: textMedium.copyWith(
              color: EndpointPalette.softForeground.withAlpha(209),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopOfferCard extends StatelessWidget {
  final Item item;
  final int price;
  final String statusLabel;
  final Color foreground;
  final VoidCallback onPressed;

  const _ShopOfferCard({
    required this.item,
    required this.price,
    required this.statusLabel,
    required this.foreground,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final itemAccent = item.rarity.accent;

    return SizedBox(
      width: double.infinity,
      height: 74,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: EndpointPanel(
            accent: itemAccent,
            backgroundColor: EndpointPalette.blend(
              EndpointPalette.panelBackgroundSoft,
              itemAccent,
              0.14,
            ),
            borderRadius: 14,
            glowOpacity: 0.05,
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
            child: Row(
              children: [
                _ShopOfferLead(
                  accent: itemAccent,
                  emoji: item.iconEmoji,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EndpointText(
                        item.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: textMediumBold.copyWith(
                          color: foreground,
                          fontSize: 14,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      EndpointText(
                        '${item.slot?.label ?? 'Consumible'}',
                        overflow: TextOverflow.ellipsis,
                        style: textSmallBold.copyWith(
                          color: item.rarity.accent,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      EndpointText(
                        item.tooltipDescription,
                        overflow: TextOverflow.ellipsis,
                        style: textSmallBold.copyWith(
                          color: Colors.white.withAlpha(173),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    EndpointText(
                      '${price}C',
                      style: textSmallNumericBold.copyWith(
                        color: itemAccent,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopOfferLead extends StatelessWidget {
  final Color accent;
  final String emoji;

  const _ShopOfferLead({
    required this.accent,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(56),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withAlpha(143),
        ),
      ),
      alignment: Alignment.center,
      child: EndpointText(
        emoji,
        style: const TextStyle(
          fontSize: 18,
          height: 1,
        ),
      ),
    );
  }
}

class _ShopSectionHeader extends StatelessWidget {
  final String title;
  final String caption;
  final Color accent;
  final Color foreground;

  const _ShopSectionHeader({
    required this.title,
    required this.caption,
    required this.accent,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: EndpointText(
            title,
            style: textMediumBold.copyWith(
              color: foreground,
              letterSpacing: 1.6,
            ),
          ),
        ),
        EndpointText(
          caption,
          style: textSmallBold.copyWith(
            color: accent,
            fontSize: 10,
            letterSpacing: 1.3,
          ),
        ),
      ],
    );
  }
}

class _ShopEconomyStrip extends StatelessWidget {
  final int money;
  final int income;

  const _ShopEconomyStrip({
    required this.money,
    required this.income,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        EndpointValueChip(
          icon: Icons.monetization_on_rounded,
          value: money,
          accent: EndpointPalette.warningAccent,
          foreground: EndpointPalette.softForegroundWarm,
        ),
        EndpointValueChip(
          icon: Icons.trending_up_rounded,
          value: income,
          accent: EndpointPalette.infoAccent,
          foreground: EndpointPalette.soften(EndpointPalette.infoAccent),
        ),
      ],
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
