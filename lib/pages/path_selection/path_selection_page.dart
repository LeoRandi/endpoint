import '_imports.dart';

class PathSelectionPage extends StatefulWidget {
  final Battler player;
  final List<PathNode>? availableNodes;
  final int nodeCount;
  final int? randomSeed;
  final Duration battleEnemyTurnDelay;
  final Duration battleCombatEndDelay;

  const PathSelectionPage({
    super.key,
    this.player = defaultPlayerBattler,
    this.availableNodes,
    this.nodeCount = 3,
    this.randomSeed,
    this.battleEnemyTurnDelay = const Duration(milliseconds: 900),
    this.battleCombatEndDelay = const Duration(seconds: 2),
  }) : assert(nodeCount > 0);

  @override
  State<PathSelectionPage> createState() => _PathSelectionPageState();
}

class _PathSelectionPageState extends State<PathSelectionPage> {
  static const _itemsBottomInset = 164.0;

  late final RunSessionController _sessionController;

  @override
  void initState() {
    super.initState();
    _sessionController = RunSessionController(
      player: widget.player,
      availableNodes: widget.availableNodes ?? defaultPathNodePool,
      nodeCount: widget.nodeCount,
      battleEnemyTurnDelay: widget.battleEnemyTurnDelay,
      battleCombatEndDelay: widget.battleCombatEndDelay,
      randomSeed: widget.randomSeed,
    );
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _handleOpenItems() async {
    await showEndpointOverlay<void>(
      context: context,
      builder: (_) => BattleItemsDialog(
        items: _sessionController.player.inventoryItems,
        subtitle: 'Inventario de ruta',
        bottomInset: _itemsBottomInset,
      ),
    );
  }

  Future<void> _handleStartEncounter(CombatPathNode node) async {
    final result = await Navigator.of(context).push<BattleFlowResult>(
      _buildSceneRoute<BattleFlowResult>(
        BattlePage(
          enemy: node.enemy,
          player: _sessionController.player,
          showTitle: node.showTitle,
          enemyTurnDelay: _sessionController.state.battleEnemyTurnDelay,
          combatEndDelay: _sessionController.state.battleCombatEndDelay,
          returnPlayerOnCombatEnd: true,
        ),
      ),
    );

    if (!mounted) return;
    if (result == null) {
      _sessionController.cancelNodeResolution();
      return;
    }
    if (result.shouldPopToRoot) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    _sessionController.completeEncounter(result);
  }

  Future<void> _handleOpenWeaponShop() async {
    final result = await Navigator.of(context).push<WeaponShopVisitResult>(
      _buildSceneRoute<WeaponShopVisitResult>(
        WeaponShopPage(player: _sessionController.player),
      ),
    );

    if (!mounted) return;
    if (result == null) {
      _sessionController.cancelNodeResolution();
      return;
    }

    _sessionController.completeWeaponShopVisit(result);
  }

  Future<void> _handleOpenCampSite() async {
    final result = await Navigator.of(context).push<CampSiteVisitResult>(
      _buildSceneRoute<CampSiteVisitResult>(
        CampSitePage(player: _sessionController.player),
      ),
    );

    if (!mounted) return;
    if (result == null) {
      _sessionController.cancelNodeResolution();
      return;
    }

    _sessionController.completeCampVisit(result);
  }

  Future<void> _handleNodePressed(PathNode node) async {
    if (!_sessionController.beginNodeResolution()) return;

    switch (node.type) {
      case PathNodeType.encounter:
        await _handleStartEncounter(node as CombatPathNode);
        break;
      case PathNodeType.weaponShop:
        await _handleOpenWeaponShop();
        break;
      case PathNodeType.campSite:
        await _handleOpenCampSite();
        break;
    }
  }

  Route<T> _buildSceneRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (context, animation, secondaryAnimation) {
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );
        final blackoutOpacity = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0, end: 1),
            weight: 52,
          ),
          TweenSequenceItem(
            tween: ConstantTween<double>(1),
            weight: 48,
          ),
        ]).animate(curved);
        final childOpacity = TweenSequence<double>([
          TweenSequenceItem(
            tween: ConstantTween<double>(0),
            weight: 38,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 0, end: 1),
            weight: 62,
          ),
        ]).animate(curved);

        return Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(
              opacity: blackoutOpacity,
              child: const ColoredBox(color: Colors.black),
            ),
            FadeTransition(
              opacity: childOpacity,
              child: child,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sessionController,
      builder: (context, child) {
        final player = _sessionController.player;
        final nodes = _sessionController.nodes;
        final isOpeningNode = _sessionController.isResolvingNode;

        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF050A08),
                  Color(0xFF09120D),
                  Color(0xFF020403),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _PathBackdrop(),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Column(
                      children: [
                        const _PathHeader(),
                        Expanded(
                          child: Column(
                            children: [
                              const Spacer(),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  const spacing = 14.0;
                                  final encounterCount = nodes.length;
                                  final availableWidth = constraints.maxWidth -
                                      (spacing * (encounterCount - 1));
                                  final nodeWidth =
                                      min(112.0, availableWidth / encounterCount);

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (int index = 0;
                                          index < encounterCount;
                                          index++) ...[
                                        if (index > 0)
                                          const SizedBox(width: spacing),
                                        SizedBox(
                                          width: nodeWidth,
                                          child: PathNodeCard(
                                            node: nodes[index],
                                            onPressed: isOpeningNode
                                                ? null
                                                : () => _handleNodePressed(
                                                      nodes[index],
                                                    ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                child: _PathBottomHud(
                                  player: player,
                                  onOpenItems: _handleOpenItems,
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
        );
      },
    );
  }
}

class _PathHeader extends StatelessWidget {
  const _PathHeader();

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      backgroundColor: const Color(0xCC07120D),
      borderRadius: 18,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECCION DE RUTA',
            style: textMediumBold.copyWith(
              color: const Color(0xFF5AF78E),
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Elige un nodo para avanzar.',
            style: textMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathBottomHud extends StatelessWidget {
  final Battler player;
  final Future<void> Function() onOpenItems;

  const _PathBottomHud({
    required this.player,
    required this.onOpenItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PathPlayerStatus(player: player),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final avatarSize = constraints.maxWidth < 360 ? 92.0 : 112.0;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 146),
                      child: const PathActionButton(
                        label: 'Operativos',
                        icon: Icons.groups_2_outlined,
                        tooltip: 'Gestion de operativos no disponible',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: EndpointEmojiSprite(
                    emoji: '\u{1F916}',
                    accent: const Color(0xFF5AF78E),
                    size: avatarSize,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 132),
                      child: PathActionButton(
                        label: 'Objetos',
                        icon: Icons.inventory_2_outlined,
                        onPressed: onOpenItems,
                        tooltip: 'Abrir inventario de ruta',
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PathPlayerStatus extends StatelessWidget {
  final Battler player;

  const _PathPlayerStatus({
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF5AF78E);
    final healthFactor = player.maxHealth <= 0
        ? 0.0
        : (player.health / player.maxHealth).clamp(0.0, 1.0).toDouble();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: EndpointPanel(
        accent: accent,
        backgroundColor: const Color(0xD907120D),
        borderRadius: 16,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textMediumBold.copyWith(
                      color: const Color(0xFFE6FFF0),
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${player.health} / ${player.maxHealth}',
                  style: textMediumBold.copyWith(
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 12,
                color: Colors.black.withOpacity(0.35),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: healthFactor,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xA65AF78E),
                            Color(0xFF5AF78E),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatChip(
                  label: 'ATK',
                  value: player.attack,
                ),
                _StatChip(
                  label: 'DEF',
                  value: player.defense,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x335AF78E)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          '$label $value',
          style: textSmallBold.copyWith(
            color: const Color(0xFFBDEECC),
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}

class _PathBackdrop extends StatelessWidget {
  const _PathBackdrop();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _PathBackdropPainter(),
      ),
    );
  }
}

class _PathBackdropPainter extends CustomPainter {
  const _PathBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x115AF78E)
      ..strokeWidth = 1;
    final pathPaint = Paint()
      ..color = const Color(0x245AF78E)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    for (double y = 36; y <= size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final start = Offset(size.width / 2, size.height - 120);
    final targets = [
      Offset(size.width * 0.24, size.height * 0.42),
      Offset(size.width * 0.5, size.height * 0.34),
      Offset(size.width * 0.76, size.height * 0.42),
    ];

    for (final target in targets) {
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          (start.dx + target.dx) / 2,
          size.height * 0.58,
          target.dx,
          target.dy,
        );
      canvas.drawPath(path, pathPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
