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
  });

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

  Future<void> _handleOpenOperatives() async {
    await showEndpointOverlay<void>(
      context: context,
      barrierColor: const Color(0xB0000000),
      builder: (_) => OperativesOverlay(player: _sessionController.player),
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
    if (_sessionController.isRunComplete && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _handleOpenWeaponShop(ShopPathNode node) async {
    final result = await Navigator.of(context).push<WeaponShopVisitResult>(
      _buildSceneRoute<WeaponShopVisitResult>(
        WeaponShopPage(
          player: _sessionController.player,
          catalog: node.catalog,
          showTitle: node.showTitle,
          shopTitle: node.shopTitle,
          shopSubtitle: node.shopSubtitle,
          iconEmoji: node.iconEmoji,
          accent: node.accent,
        ),
      ),
    );

    if (!mounted) return;
    if (result == null) {
      _sessionController.cancelNodeResolution();
      return;
    }

    _sessionController.completeWeaponShopVisit(result);
    if (_sessionController.isRunComplete && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
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
    if (_sessionController.isRunComplete && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _handleOpenEvent(EventPathNode node) async {
    final result = await Navigator.of(context).push<PathEventVisitResult>(
      _buildSceneRoute<PathEventVisitResult>(
        PathEventPage(
          player: _sessionController.player,
          showTitle: node.showTitle,
          eventTitle: node.eventTitle,
          description: node.description,
          outcomeText: node.outcomeText,
          iconEmoji: node.iconEmoji,
          accent: node.accent,
        ),
      ),
    );

    if (!mounted) return;
    if (result == null) {
      _sessionController.cancelNodeResolution();
      return;
    }

    _sessionController.completeEventVisit(result);
    if (_sessionController.isRunComplete && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _handleNodePressed(PathNode node) async {
    if (!_sessionController.beginNodeResolution()) return;

    switch (node.type) {
      case PathNodeType.encounter:
        await _handleStartEncounter(node as CombatPathNode);
        break;
      case PathNodeType.shop:
        await _handleOpenWeaponShop(node as ShopPathNode);
        break;
      case PathNodeType.campSite:
        await _handleOpenCampSite();
        break;
      case PathNodeType.event:
        await _handleOpenEvent(node as EventPathNode);
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
        final currentHour = _sessionController.currentHour;
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
                _PathBackdrop(nodeCount: nodes.length),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Column(
                      children: [
                        _PathHeader(currentHour: currentHour),
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
                                    mainAxisAlignment: encounterCount == 1
                                        ? MainAxisAlignment.center
                                        : MainAxisAlignment.start,
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
                                  onOpenOperatives: _handleOpenOperatives,
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
  final RunHourSnapshot currentHour;

  const _PathHeader({
    required this.currentHour,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      backgroundColor: const Color(0xCC07120D),
      borderRadius: 18,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EndpointText(
            currentHour.title,
            style: textMediumBold.copyWith(
              color: const Color(0xFF5AF78E),
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 6),
          EndpointText(
            currentHour.subtitle,
            style: textMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 14),
          _RunTimelineMeter(currentHour: currentHour),
        ],
      ),
    );
  }
}

class _PathBottomHud extends StatelessWidget {
  final Battler player;
  final Future<void> Function() onOpenOperatives;
  final Future<void> Function() onOpenItems;

  const _PathBottomHud({
    required this.player,
    required this.onOpenOperatives,
    required this.onOpenItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PathPlayerStatus(player: player),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final avatarSize = constraints.maxWidth < 360 ? 82.0 : 98.0;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 132),
                      child: PathActionButton(
                        label: 'Operativos',
                        icon: Icons.groups_2_outlined,
                        onPressed: onOpenOperatives,
                        tooltip: 'Abrir ventana de operativos',
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: avatarSize,
                    height: avatarSize,
                    child: EndpointEmojiSprite(
                      emoji: '\u{1F916}',
                      accent: const Color(0xFF5AF78E),
                      size: avatarSize,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 118),
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
                  child: EndpointText(
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
                EndpointText(
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
        child: EndpointText(
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

class _RunTimelineMeter extends StatelessWidget {
  final RunHourSnapshot currentHour;

  const _RunTimelineMeter({
    required this.currentHour,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        (currentHour.stageIndex / PathNodeService.sunriseStageIndex).clamp(
          0.0,
          1.0,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.34),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x335AF78E)),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF5AF78E),
                        Color(0xFFDBB95A),
                        Color(0xFF59B7FF),
                        Color(0xFFF3D35C),
                      ],
                    ),
                  ),
                ),
              ),
              ..._buildMarkers(),
            ],
          ),
        ),
        const SizedBox(height: 6),
        EndpointText(
          'Ruta de 12 horas: dia, anochecer, noche y sunrise.',
          style: textSmallBold.copyWith(
            color: Colors.white.withOpacity(0.68),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMarkers() {
    return [
      _buildMarker(
        alignmentX: -1,
        icon: Icons.wb_sunny_outlined,
        color: const Color(0xFF5AF78E),
      ),
      _buildMarker(
        alignmentX:
            _alignmentForProgress(PathNodeService.duskStageIndex / PathNodeService.sunriseStageIndex),
        icon: Icons.dark_mode_outlined,
        color: const Color(0xFF59B7FF),
      ),
      _buildMarker(
        alignmentX: 1,
        icon: Icons.sunny,
        color: const Color(0xFFF3D35C),
      ),
    ];
  }

  Widget _buildMarker({
    required double alignmentX,
    required IconData icon,
    required Color color,
  }) {
    return Align(
      alignment: Alignment(alignmentX, 0),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFF07120D),
          shape: BoxShape.circle,
          border: Border.all(color: color),
        ),
        child: Icon(icon, size: 12, color: color),
      ),
    );
  }

  double _alignmentForProgress(double progress) {
    return (progress * 2) - 1;
  }
}

class _PathBackdrop extends StatelessWidget {
  final int nodeCount;

  const _PathBackdrop({
    required this.nodeCount,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _PathBackdropPainter(nodeCount: nodeCount),
      ),
    );
  }
}

class _PathBackdropPainter extends CustomPainter {
  final int nodeCount;

  const _PathBackdropPainter({
    required this.nodeCount,
  });

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
    final targets = nodeCount <= 1
        ? [
            Offset(size.width * 0.5, size.height * 0.36),
          ]
        : [
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
  bool shouldRepaint(covariant _PathBackdropPainter oldDelegate) {
    return oldDelegate.nodeCount != nodeCount;
  }
}

