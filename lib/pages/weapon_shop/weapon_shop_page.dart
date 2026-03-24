import '_imports.dart';

class WeaponShopPage extends StatefulWidget {
  final Battler player;
  final List<Item> catalog;
  final String showTitle;
  final String shopTitle;
  final String shopSubtitle;
  final String iconEmoji;
  final Color accent;

  const WeaponShopPage({
    super.key,
    required this.player,
    this.catalog = itemPresets,
    this.showTitle = 'Bienvenido a la tienda',
    this.shopTitle = 'TIENDA DE ARMAS',
    this.shopSubtitle = 'Adquiere y equipa piezas para la ruta.',
    this.iconEmoji = '\u{2694}',
    this.accent = const Color(0xFFDBB95A),
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
          final foreground = Color.lerp(Colors.white, accent, 0.32) ??
              const Color(0xFFEEDB96);

          return Scaffold(
            body: NodeSceneWrapper(
              showTitle: widget.showTitle,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(const Color(0xFF090705), accent, 0.12) ??
                          const Color(0xFF090705),
                      Color.lerp(const Color(0xFF11120A), accent, 0.08) ??
                          const Color(0xFF11120A),
                      const Color(0xFF030403),
                    ],
                  ),
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
                              child: HoldTooltip(
                                message: 'Salir de la tienda',
                                child: IconButton(
                                  onPressed: _closeShop,
                                  style: IconButton.styleFrom(
                                    foregroundColor: foreground,
                                    backgroundColor: const Color(0xFF17130B),
                                    side: BorderSide(color: accent),
                                  ),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            EndpointEmojiSprite(
                              emoji: widget.iconEmoji,
                              accent: accent,
                              size: 132,
                            ),
                            const SizedBox(height: 16),
                            EndpointText(
                              widget.shopTitle,
                              textAlign: TextAlign.center,
                              style: textLargeBold.copyWith(
                                color: foreground,
                                letterSpacing: 2.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            EndpointText(
                              widget.shopSubtitle,
                              textAlign: TextAlign.center,
                              style: textMedium.copyWith(
                                color: Colors.white.withOpacity(0.82),
                              ),
                            ),
                            const SizedBox(height: 18),
                            EndpointPanel(
                              accent: accent,
                              backgroundColor: const Color(0xCC17130B),
                              glowOpacity: 0.08,
                              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                              child: Column(
                                children: [
                                  EndpointText(
                                    player.name,
                                    style: textMediumBold.copyWith(
                                      color: foreground,
                                      letterSpacing: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  EndpointText(
                                    'ATK ${player.attack}   DEF ${player.defense}   HP ${player.health}/${player.maxHealth}',
                                    textAlign: TextAlign.center,
                                    style: textMedium.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  EndpointText(
                                    _equippedSummary(player),
                                    textAlign: TextAlign.center,
                                    style: textMedium.copyWith(
                                      color: Colors.white.withOpacity(0.74),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.separated(
                                itemCount: _controller.catalog.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = _controller.catalog[index];
                                  return _ShopItemCard(
                                    item: item,
                                    statusLabel: _statusLabel(item),
                                    actionLabel: _controller.actionLabelFor(item),
                                    isActionEnabled:
                                        _controller.isActionEnabled(item),
                                    accent: accent,
                                    foreground: foreground,
                                    onPrimaryAction: () =>
                                        _controller.handlePrimaryAction(item),
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

  String _statusLabel(Item item) {
    if (_controller.isItemEquipped(item)) return 'Equipado';
    if (_controller.isItemInInventory(item)) return 'En inventario';
    return 'No adquirido';
  }

  String _equippedSummary(Battler player) {
    if (player.equippedItems.isEmpty) return 'Equipo activo: sin piezas equipadas';

    return 'Equipo activo: ${player.equippedItems.map((item) => item.name).join(' | ')}';
  }
}

class _ShopItemCard extends StatelessWidget {
  final Item item;
  final String statusLabel;
  final String actionLabel;
  final bool isActionEnabled;
  final Color accent;
  final Color foreground;
  final VoidCallback onPrimaryAction;

  const _ShopItemCard({
    required this.item,
    required this.statusLabel,
    required this.actionLabel,
    required this.isActionEnabled,
    required this.accent,
    required this.foreground,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      accent: accent,
      backgroundColor: const Color(0xCC17130B),
      glowOpacity: 0.08,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EndpointEmojiSprite(
                emoji: item.iconEmoji,
                accent: accent,
                size: 62,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EndpointText(
                      item.name,
                      style: textMediumBold.copyWith(
                        color: foreground,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    EndpointText(
                      item.slot?.label ?? 'Consumible',
                      style: textSmallBold.copyWith(
                        color: accent,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    EndpointText(
                      statusLabel,
                      style: textMedium.copyWith(
                        color: Colors.white.withOpacity(0.74),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EndpointText(
            item.description,
            style: textMedium.copyWith(
              color: Colors.white.withOpacity(0.82),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: EndpointActionButton(
              label: actionLabel,
              icon: Icons.inventory_2_outlined,
              onPressed: isActionEnabled ? onPrimaryAction : null,
              tooltip: isActionEnabled
                  ? 'Aplicar accion de tienda'
                  : 'Ya tienes este objeto listo',
              accent: accent,
              backgroundColor: const Color(0xFF2A2212),
              foregroundColor: foreground,
              borderWidth: 1.3,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              textStyle: textMediumBold.copyWith(letterSpacing: 1.2),
            ),
          ),
        ],
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

