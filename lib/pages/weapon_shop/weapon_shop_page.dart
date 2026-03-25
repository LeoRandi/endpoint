import '_imports.dart';

class WeaponShopPage extends StatefulWidget {
  final Battler player;
  final List<Item> catalog;
  final double priceMultiplier;
  final String showTitle;
  final String shopTitle;
  final String shopSubtitle;
  final String iconEmoji;
  final Color accent;

  const WeaponShopPage({
    super.key,
    required this.player,
    this.catalog = itemPresets,
    this.priceMultiplier = 1,
    this.showTitle = 'Bienvenido a la tienda',
    this.shopTitle = 'TIENDA DE ARMAS',
    this.shopSubtitle = 'Adquiere y equipa piezas para la ruta.',
    this.iconEmoji = '\u{2694}',
    this.accent = EndpointPalette.shopAccent,
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
      catalog: widget.catalog,
      priceMultiplier: widget.priceMultiplier,
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

  Future<void> _openItemDetails(Item item) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de objeto',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return EndpointItemDetailsDialog(
              item: item,
              accent: widget.accent,
              price: _controller.costFor(item),
              statusText: _controller.detailStatusLabelFor(item),
              actionLabel: _controller.actionLabelFor(item),
              onPrimaryAction: _controller.isActionEnabled(item)
                  ? () => _controller.handlePrimaryAction(item)
                  : null,
              isActionEnabled: _controller.isActionEnabled(item),
              enabledActionTooltip: 'Aplicar accion de tienda',
              disabledActionTooltip: 'No tienes credito suficiente',
            );
          },
        );
      },
    );
  }

  Future<bool> _handleWillPop() async {
    _closeShop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final player = _controller.player;
          final accent = widget.accent;
          final foreground = EndpointPalette.soften(accent);
          final panelBackground = EndpointPalette.blend(
            EndpointPalette.panelBackgroundGold,
            accent,
            0.08,
          );
          final tileBackground = EndpointPalette.blend(
            EndpointPalette.panelBackgroundSoft,
            accent,
            0.12,
          );

          return Scaffold(
            body: NodeSceneWrapper(
              showTitle: widget.showTitle,
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
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
                            EndpointText(
                              widget.shopTitle,
                              textAlign: TextAlign.center,
                              style: textLargeBold.copyWith(
                                color: foreground,
                                letterSpacing: 2.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            EndpointText(
                              widget.shopSubtitle,
                              textAlign: TextAlign.center,
                              style: textMedium.copyWith(
                                color:
                                    EndpointPalette.softForeground.withOpacity(0.82),
                              ),
                            ),
                            const SizedBox(height: 14),
                            EndpointPanel(
                              accent: accent,
                              backgroundColor: panelBackground,
                              glowOpacity: 0.08,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 14),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      EndpointEmojiSprite(
                                        emoji: widget.iconEmoji,
                                        accent: accent,
                                        size: 74,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            EndpointText(
                                              player.name,
                                              style: textMediumBold.copyWith(
                                                color: foreground,
                                                letterSpacing: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            _ShopEconomyStrip(
                                              money: player.money,
                                              income: player.income,
                                            ),
                                            const SizedBox(height: 8),
                                            EndpointText(
                                              'ATK ${player.attack}   DEF ${player.defense}   HP ${player.health}/${player.maxHealth}',
                                              style: textSmallBold.copyWith(
                                                color: EndpointPalette.softForeground
                                                    .withOpacity(0.8),
                                                letterSpacing: 0.9,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  EndpointText(
                                    _equippedSummary(player),
                                    textAlign: TextAlign.center,
                                    style: textSmallBold.copyWith(
                                      color: Colors.white.withOpacity(0.74),
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: GridView.builder(
                                itemCount: _controller.catalog.length,
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 132,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  mainAxisExtent: 148,
                                ),
                                itemBuilder: (context, index) {
                                  final item = _controller.catalog[index];
                                  return _ShopItemTile(
                                    onPressed: () => _openItemDetails(item),
                                    item: item,
                                    price: _controller.costFor(item),
                                    statusLabel:
                                        _controller.availabilityLabelFor(item),
                                    accent: accent,
                                    backgroundColor: tileBackground,
                                    foreground: foreground,
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
            ),
          );
        },
      ),
    );
  }

  String _equippedSummary(Battler player) {
    if (player.equippedItems.isEmpty)
      return 'Equipo activo: sin piezas equipadas';

    return 'Equipo activo: ${player.equippedItems.map((item) => item.name).join(' | ')}';
  }
}

class _ShopItemTile extends StatelessWidget {
  final Item item;
  final int price;
  final String statusLabel;
  final Color accent;
  final Color backgroundColor;
  final Color foreground;
  final VoidCallback onPressed;

  const _ShopItemTile({
    required this.item,
    required this.price,
    required this.statusLabel,
    required this.accent,
    required this.backgroundColor,
    required this.foreground,
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
          borderRadius: BorderRadius.circular(16),
          child: EndpointPanel(
            accent: accent,
            backgroundColor: backgroundColor,
            glowOpacity: 0.06,
            borderRadius: 16,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EndpointEmojiSprite(
                  emoji: item.iconEmoji,
                  accent: accent,
                  size: 56,
                ),
                const SizedBox(height: 8),
                EndpointText(
                  item.name,
                  textAlign: TextAlign.center,
                  style: textMediumBold.copyWith(
                    color: foreground,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                EndpointText(
                  '${price}C',
                  style: textSmallBold.copyWith(
                    fontSize: 10,
                    color: accent,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                EndpointText(
                  statusLabel,
                  textAlign: TextAlign.center,
                  style: textSmallBold.copyWith(
                    fontSize: 10,
                    color: EndpointPalette.softForeground.withOpacity(0.72),
                    letterSpacing: 0.9,
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
      ..color = accent.withOpacity(0.12)
      ..strokeWidth = 1;
    final beamPaint = Paint()
      ..color = accent.withOpacity(0.18)
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
