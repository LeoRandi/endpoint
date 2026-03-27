import '_imports.dart';
import '../../coordinators/run_node_flow_coordinator.dart';

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
  static const _abilitiesBottomInset = 164.0;
  static const _flowCoordinator = RunNodeFlowCoordinator();

  late final RunSessionController _sessionController;

  @override
  void initState() {
    super.initState();
    _sessionController = RunSessionController(
      player: widget.player,
      battleEnemyTurnDelay: widget.battleEnemyTurnDelay,
      battleCombatEndDelay: widget.battleCombatEndDelay,
      availableNodes: widget.availableNodes,
      nodeCount: widget.nodeCount,
      randomSeed: widget.randomSeed,
    );
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _handleOpenAbilities() async {
    await showEndpointOverlay<void>(
      context: context,
      builder: (_) => EndpointAbilitiesOverlay(
        player: _sessionController.player,
        screenContext: BattlerAbilityActivationContext.pathSelection,
        subtitle: 'Protocolos disponibles en ruta',
        bottomInset: _abilitiesBottomInset,
        onPlayerChanged: _sessionController.updatePlayer,
      ),
    );
  }

  Future<void> _handleOpenOperatives() async {
    await showEndpointOverlay<void>(
      context: context,
      barrierColor: EndpointPalette.overlayScrimStrong,
      builder: (_) => OperativesOverlay(
        player: _sessionController.player,
        onPlayerChanged: _sessionController.updatePlayer,
      ),
    );
  }

  Future<void> _handleNodePressed(PathNode node) async {
    if (!_sessionController.beginNodeResolution()) return;
    await _flowCoordinator.handleNodeSelection(
      context: context,
      node: node,
      session: _sessionController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: EndpointGradients.path),
        child: AnimatedBuilder(
          animation: _sessionController,
          builder: (context, child) {
            final player = _sessionController.player;
            final nodes = _sessionController.nodes;
            final currentHour = _sessionController.currentHour;
            final isOpeningNode = _sessionController.isResolvingNode;

            return Stack(
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
                                  final nodeWidth = min(
                                    112.0,
                                    availableWidth / encounterCount,
                                  );

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
                                  onOpenAbilities: _handleOpenAbilities,
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
            );
          },
        ),
      ),
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
      backgroundColor: EndpointPalette.panelBackgroundSoft,
      borderRadius: 18,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: _RunTimelineMeter(currentHour: currentHour),
    );
  }
}

class _PathBottomHud extends StatelessWidget {
  final Battler player;
  final Future<void> Function() onOpenOperatives;
  final Future<void> Function() onOpenAbilities;

  const _PathBottomHud({
    required this.player,
    required this.onOpenOperatives,
    required this.onOpenAbilities,
  });

  @override
  Widget build(BuildContext context) {
    final chipTextStyle = textMediumNumericBold.copyWith(
      fontSize: 14,
      letterSpacing: 1.2,
    );

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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: avatarSize,
                        height: avatarSize,
                        child: EndpointEmojiSprite(
                          emoji: player.iconEmoji,
                          accent: EndpointPalette.primaryAccent,
                          size: avatarSize,
                        ),
                      ),
                      const SizedBox(height: 6),
                      EndpointValueChip(
                        icon: Icons.monetization_on_rounded,
                        value: player.money,
                        accent: EndpointPalette.warningAccent,
                        foreground: EndpointPalette.softForegroundWarm,
                        textStyle: chipTextStyle,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 118),
                      child: PathActionButton(
                        label: 'Habilidades',
                        icon: Icons.auto_awesome_rounded,
                        onPressed: onOpenAbilities,
                        tooltip: 'Abrir panel de habilidades',
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
    const accent = EndpointPalette.primaryAccent;
    final statChipTextStyle = textMediumNumericBold.copyWith(
      fontSize: 14,
      letterSpacing: 1.2,
    );
    final healthFactor = player.maxHealth <= 0
        ? 0.0
        : (player.health / player.maxHealth).clamp(0.0, 1.0).toDouble();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: EndpointPanel(
        accent: accent,
        backgroundColor: EndpointPalette.panelBackgroundStrong,
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
                      color: EndpointPalette.softForeground,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                EndpointText(
                  '${player.health} / ${player.maxHealth}',
                  style: textMediumNumericBold.copyWith(
                    fontSize: 14,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            EndpointHealthBarWithStatuses(
              battler: player,
              value: healthFactor,
              accent: accent,
              badgeAlignment: WrapAlignment.start,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                EndpointValueChip(
                  label: 'ATK',
                  value: player.attack,
                  accent: accent,
                  foreground: EndpointPalette.soften(accent, amount: 0.24),
                  textStyle: statChipTextStyle,
                ),
                EndpointValueChip(
                  label: 'DEF',
                  value: player.defense,
                  accent: accent,
                  foreground: EndpointPalette.soften(accent, amount: 0.24),
                  textStyle: statChipTextStyle,
                ),
                EndpointValueChip(
                  icon: Icons.trending_up_rounded,
                  value: player.income,
                  accent: EndpointPalette.infoAccent,
                  foreground:
                      EndpointPalette.soften(EndpointPalette.infoAccent),
                  textStyle: statChipTextStyle,
                ),
              ],
            ),
          ],
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

    return SizedBox(
      height: 20,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.34),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: EndpointPalette.primaryAccent.withOpacity(0.2),
              ),
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
                    EndpointPalette.primaryAccent,
                    EndpointPalette.shopAccent,
                    EndpointPalette.infoAccent,
                    EndpointPalette.warningAccent,
                  ],
                ),
              ),
            ),
          ),
          ..._buildMarkers(),
        ],
      ),
    );
  }

  List<Widget> _buildMarkers() {
    return [
      _buildMarker(
        alignmentX: -1,
        icon: Icons.wb_sunny_outlined,
        color: EndpointPalette.primaryAccent,
      ),
      _buildMarker(
        alignmentX: _alignmentForProgress(
            PathNodeService.duskStageIndex / PathNodeService.sunriseStageIndex),
        icon: Icons.dark_mode_outlined,
        color: EndpointPalette.infoAccent,
      ),
      _buildMarker(
        alignmentX: 1,
        icon: Icons.sunny,
        color: EndpointPalette.warningAccent,
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
          color: EndpointPalette.panelBackground,
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
      ..color = EndpointPalette.primaryAccent.withOpacity(0.07)
      ..strokeWidth = 1;
    final pathPaint = Paint()
      ..color = EndpointPalette.primaryAccent.withOpacity(0.14)
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
