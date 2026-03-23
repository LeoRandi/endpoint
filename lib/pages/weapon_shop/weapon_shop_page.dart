import '_imports.dart';

class WeaponShopPage extends StatefulWidget {
  final Battler player;
  final List<Item> catalog;

  const WeaponShopPage({
    super.key,
    required this.player,
    this.catalog = itemPresets,
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

          return Scaffold(
            body: NodeSceneWrapper(
              showTitle: 'Bienvenido a la tienda',
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF090705),
                      Color(0xFF11120A),
                      Color(0xFF030403),
                    ],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const _ShopBackdrop(),
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
                                    foregroundColor: const Color(0xFFE9E4C4),
                                    backgroundColor: const Color(0xFF17130B),
                                    side: const BorderSide(color: Color(0xFFDBB95A)),
                                  ),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const EndpointEmojiSprite(
                              emoji: '\u{2694}',
                              accent: Color(0xFFDBB95A),
                              size: 132,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'TIENDA DE ARMAS',
                              textAlign: TextAlign.center,
                              style: textLargeBold.copyWith(
                                color: const Color(0xFFEEDB96),
                                letterSpacing: 2.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Adquiere y equipa piezas para la ruta.',
                              textAlign: TextAlign.center,
                              style: textMedium.copyWith(
                                color: Colors.white.withOpacity(0.82),
                              ),
                            ),
                            const SizedBox(height: 18),
                            EndpointPanel(
                              accent: const Color(0xFFDBB95A),
                              backgroundColor: const Color(0xCC17130B),
                              glowOpacity: 0.08,
                              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                              child: Column(
                                children: [
                                  Text(
                                    player.name,
                                    style: textMediumBold.copyWith(
                                      color: const Color(0xFFFFF4CC),
                                      letterSpacing: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ATK ${player.attack}   DEF ${player.defense}   HP ${player.health}/${player.maxHealth}',
                                    textAlign: TextAlign.center,
                                    style: textMedium.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
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
  final VoidCallback onPrimaryAction;

  const _ShopItemCard({
    required this.item,
    required this.statusLabel,
    required this.actionLabel,
    required this.isActionEnabled,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFDBB95A);

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
                    Text(
                      item.name,
                      style: textMediumBold.copyWith(
                        color: const Color(0xFFFFF4CC),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.slot?.label ?? 'Consumible',
                      style: textSmallBold.copyWith(
                        color: accent,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
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
          Text(
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
              foregroundColor: const Color(0xFFFFF4CC),
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
  const _ShopBackdrop();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _ShopBackdropPainter(),
      ),
    );
  }
}

class _ShopBackdropPainter extends CustomPainter {
  const _ShopBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x12DBB95A)
      ..strokeWidth = 1;
    final beamPaint = Paint()
      ..color = const Color(0x1FDBB95A)
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
