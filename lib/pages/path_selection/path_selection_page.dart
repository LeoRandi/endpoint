import '_imports.dart';
import '../../coordinators/run_node_flow_coordinator.dart';
import 'package:showcaseview/showcaseview.dart';

const _pathTutorialShowcaseScope = 'path_selection.tutorial';

class PathSelectionPage extends StatefulWidget {
  final Battler player;
  final List<PathNode>? availableNodes;
  final Map<int, List<PathNode>>? scriptedNodesByStage;
  final int nodeCount;
  final int? randomSeed;
  final Duration battleEnemyTurnDelay;
  final Duration battleCombatEndDelay;
  final EndpointCurrentRunSnapshot? restoredRun;
  final bool isTutorialRun;
  final bool persistRun;
  final EndpointSettingsSnapshot initialSettings;

  const PathSelectionPage({
    super.key,
    this.player = defaultPlayerBattler,
    this.availableNodes,
    this.scriptedNodesByStage,
    this.nodeCount = 3,
    this.randomSeed,
    this.battleEnemyTurnDelay = const Duration(milliseconds: 900),
    this.battleCombatEndDelay = const Duration(seconds: 2),
    this.isTutorialRun = false,
    this.persistRun = true,
    this.initialSettings = const EndpointSettingsSnapshot.defaults(),
  }) : restoredRun = null;

  PathSelectionPage.tutorial({
    super.key,
    this.battleEnemyTurnDelay = const Duration(milliseconds: 900),
    this.battleCombatEndDelay = const Duration(seconds: 2),
    this.initialSettings = const EndpointSettingsSnapshot.defaults(),
  })  : player = defaultPlayerBattler,
        availableNodes = null,
        scriptedNodesByStage = TutorialRunDefinition.scriptedNodesByStage,
        nodeCount = TutorialRunDefinition.nodeCount,
        randomSeed = TutorialRunDefinition.randomSeed,
        restoredRun = null,
        isTutorialRun = true,
        persistRun = false;

  const PathSelectionPage.continueRun({
    super.key,
    required this.restoredRun,
    this.initialSettings = const EndpointSettingsSnapshot.defaults(),
  })  : player = defaultPlayerBattler,
        availableNodes = null,
        scriptedNodesByStage = null,
        nodeCount = 3,
        randomSeed = null,
        battleEnemyTurnDelay = const Duration(milliseconds: 900),
        battleCombatEndDelay = const Duration(seconds: 2),
        isTutorialRun = false,
        persistRun = true;

  @override
  State<PathSelectionPage> createState() => _PathSelectionPageState();
}

class _PathSelectionPageState extends State<PathSelectionPage> {
  static const _augmentsBottomInset = 164.0;
  static const _flowCoordinator = RunNodeFlowCoordinator();
  static const _levelUpRewardService = LevelUpRewardService();

  late final RunSessionController _sessionController;
  late final _PathTutorialShowcaseKeys _tutorialKeys;
  ShowcaseView? _tutorialShowcase;
  bool _isPresentingRunOutcome = false;
  bool _isPresentingDaySummary = false;
  bool _isPresentingGhostItemResolution = false;
  bool _didResumeSavedNode = false;
  bool _didStartOpeningTutorial = false;

  @override
  void initState() {
    super.initState();
    _sessionController = widget.restoredRun == null
        ? RunSessionController(
            player: widget.player,
            battleEnemyTurnDelay: widget.battleEnemyTurnDelay,
            battleCombatEndDelay: widget.battleCombatEndDelay,
            availableNodes: widget.availableNodes,
            scriptedNodesByStage: widget.scriptedNodesByStage,
            nodeCount: widget.nodeCount,
            randomSeed: widget.randomSeed,
            runRulesMode: widget.initialSettings.runRulesMode,
            persistRun: widget.persistRun,
            snapshotRepository: const PreferencesRunSnapshotRepository(),
          )
        : RunSessionController.resume(
            snapshot: widget.restoredRun!,
            runRulesMode: widget.initialSettings.runRulesMode,
            snapshotRepository: const PreferencesRunSnapshotRepository(),
          );

    _tutorialKeys = _PathTutorialShowcaseKeys();
    if (widget.isTutorialRun) {
      _tutorialShowcase = ShowcaseView.register(
        scope: _pathTutorialShowcaseScope,
        disableBarrierInteraction: true,
        disableMovingAnimation: false,
        disableScaleAnimation: false,
        blurValue: 0,
        skipIfTargetNotPresent: true,
        globalTooltipActionConfig: const TooltipActionConfig(
          alignment: MainAxisAlignment.end,
          actionGap: 8,
          position: TooltipActionPosition.inside,
        ),
        globalTooltipActions: [
          TooltipActionButton(
            type: TooltipDefaultActionType.next,
            name: 'SIGUIENTE',
            backgroundColor: EndpointPalette.blend(
              EndpointPalette.panelBackgroundBattle,
              EndpointPalette.infoAccent,
              0.22,
            ),
            textStyle: textSmallBold.copyWith(
              color: EndpointPalette.softForegroundWarm,
              letterSpacing: 0.8,
            ),
            border: Border.all(
              color: EndpointPalette.infoAccent.withValues(alpha: 0.72),
            ),
          ),
        ],
      );
      _scheduleOpeningTutorialShowcase();
    }

    if (_sessionController.isResolvingNode &&
        _sessionController.activeNode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_resumeSavedNodeIfNeeded());
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybePresentGhostItemResolution());
      unawaited(_maybePresentDaySummary());
    });
  }

  @override
  void dispose() {
    _tutorialShowcase?.unregister();
    _sessionController.dispose();
    super.dispose();
  }

  void _scheduleOpeningTutorialShowcase() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didStartOpeningTutorial) return;

      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted || _didStartOpeningTutorial) return;

        _didStartOpeningTutorial = true;
        _tutorialShowcase?.startShowCase(
          [
            _tutorialKeys.nodes,
            _tutorialKeys.playerStats,
            _tutorialKeys.money,
            _tutorialKeys.operatives,
            _tutorialKeys.augments,
            _tutorialKeys.timeline,
            _tutorialKeys.archetypeNode,
          ],
        );
      });
    });
  }

  Future<void> _handleOpenAugments() async {
    if (_sessionController.isRunComplete ||
        _sessionController.hasPendingDaySummary ||
        _sessionController.hasPendingGhostItemResolution) {
      return;
    }

    await showEndpointOverlay<void>(
      context: context,
      builder: (_) => EndpointAugmentsOverlay(
        player: _sessionController.player,
        subtitle: 'Protocolos disponibles en ruta',
        bottomInset: _augmentsBottomInset,
      ),
    );
    if (!mounted) return;

    await _maybePresentGhostItemResolution();
    await _maybePresentDaySummary();
    await _maybePresentRunOutcome();
  }

  Future<void> _handleOpenOperatives() async {
    if (_sessionController.isRunComplete ||
        _sessionController.hasPendingDaySummary ||
        _sessionController.hasPendingGhostItemResolution) {
      return;
    }

    await showEndpointOverlay<void>(
      context: context,
      barrierColor: EndpointPalette.overlayScrimStrong,
      builder: (_) => OperativesOverlay(
        player: _sessionController.player,
        gameMode: widget.initialSettings.gameMode,
        onPlayerChanged: _sessionController.updatePlayer,
      ),
    );
    if (!mounted) return;

    await _maybePresentGhostItemResolution();
    await _maybePresentDaySummary();
    await _maybePresentRunOutcome();
  }

  Future<void> _handleNodePressed(PathNode node) async {
    if (_sessionController.hasPendingDaySummary) return;
    if (_sessionController.hasPendingGhostItemResolution) {
      await _maybePresentGhostItemResolution();
      return;
    }
    if (!_sessionController.beginNodeResolution(node: node)) return;
    await _openNode(node);
  }

  Widget _buildPathNodeCard({
    required PathNode node,
    required bool isTutorialTarget,
    required bool isDailyBossStage,
    VoidCallback? onPressed,
  }) {
    final card = PathNodeCard(
      node: node,
      onPressed: onPressed,
      highlightAsDailyBoss: isDailyBossStage,
    );
    if (!isTutorialTarget) return card;

    return _PathShowcaseStep(
      showcaseKey: _tutorialKeys.archetypeNode,
      title: 'Elige Imparable',
      description:
          'Para empezar la primera hora del tutorial, pulsa este arquetipo. El resto de la pantalla queda bloqueado hasta que lo elijas.',
      allowTargetInteraction: true,
      tooltipActions: const [],
      targetBorderRadius: BorderRadius.circular(18),
      targetPadding: const EdgeInsets.all(8),
      onTargetClick: () {
        if (!mounted) return;
        unawaited(_handleNodePressed(node));
      },
      child: card,
    );
  }

  Future<void> _resumeSavedNodeIfNeeded() async {
    if (_didResumeSavedNode || !mounted) return;

    final activeNode = _sessionController.activeNode;
    if (!_sessionController.isResolvingNode || activeNode == null) return;

    _didResumeSavedNode = true;
    await _openNode(activeNode);
  }

  Future<void> _openNode(PathNode node) async {
    await _flowCoordinator.handleNodeSelection(
      context: context,
      node: node,
      session: _sessionController,
      isTutorialRun: widget.isTutorialRun,
    );
    if (!mounted) return;

    if (_sessionController.isRunComplete) {
      await _maybePresentRunOutcome();
      return;
    }
    await _maybePresentGhostItemResolution();
    await _maybePresentDaySummary();
  }

  Future<void> _handleOpenLevelUp() async {
    if (_sessionController.isRunComplete ||
        _sessionController.hasPendingDaySummary ||
        _sessionController.hasPendingGhostItemResolution ||
        !_sessionController.player.canLevelUp) {
      return;
    }

    final player = _sessionController.player;
    final offer = _levelUpRewardService.buildOffer(
      player: player,
      randomizer: _sessionController.randomizer,
    );
    final reward = await showEndpointDialog<BattlerLevelRewardChoice>(
      context: context,
      barrierLabel: 'Seleccionar recompensa de nivel',
      barrierDismissible: false,
      barrierColor: EndpointPalette.overlayScrimStrong,
      builder: (context) => LevelUpRewardDialog(
        player: player,
        offer: offer,
      ),
    );
    if (!mounted || reward == null) return;

    _sessionController.updatePlayerWithRewards(
      player.applyLevelReward(reward),
    );
    await _maybePresentGhostItemResolution();
    await _maybePresentDaySummary();
  }

  Future<void> _maybePresentGhostItemResolution() async {
    if (!mounted ||
        _isPresentingGhostItemResolution ||
        _sessionController.isRunComplete ||
        _sessionController.hasPendingDaySummary ||
        !_sessionController.hasPendingGhostItemResolution) {
      return;
    }

    final item = _sessionController.pendingGhostItem;
    if (item == null) return;

    _isPresentingGhostItemResolution = true;
    final price = const PathEventService().tintoreriaFantasmaPriceFor(item);
    final keepItem = await Navigator.of(context).push<bool>(
      buildEndpointSceneRoute<bool>(
        GhostItemResolutionPage(
          player: _sessionController.player,
          item: item,
          price: price,
        ),
      ),
    );
    if (!mounted) return;

    _sessionController.resolveGhostItemLease(keepItem: keepItem == true);
    _isPresentingGhostItemResolution = false;
  }

  Future<void> _maybePresentDaySummary() async {
    if (!mounted ||
        _isPresentingDaySummary ||
        _sessionController.isRunComplete ||
        !_sessionController.hasPendingDaySummary) {
      return;
    }

    final summary = _sessionController.pendingDaySummary;
    if (summary == null) return;

    _isPresentingDaySummary = true;
    final shouldContinue = await Navigator.of(context).push<bool>(
      buildEndpointSceneRoute<bool>(
        RunDaySummaryPage(
          summary: summary,
          player: _sessionController.player,
        ),
      ),
    );
    if (!mounted) return;

    if (shouldContinue == true && _sessionController.hasPendingDaySummary) {
      _sessionController.continueToNextDay();
    }
    _isPresentingDaySummary = false;
    await _maybePresentGhostItemResolution();
  }

  /// Presenta la pantalla final cuando la run ya se ha cerrado por victoria, derrota o retirada.
  Future<void> _maybePresentRunOutcome() async {
    if (!mounted ||
        _isPresentingRunOutcome ||
        !_sessionController.isRunComplete) {
      return;
    }

    final completionType = _sessionController.completionType;
    if (completionType == null) return;

    _isPresentingRunOutcome = true;
    await _sessionController.clearPersistedRunSnapshot();
    if (!mounted) return;

    if (completionType == RunCompletionType.retreated) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    await Navigator.of(context).push<void>(
      buildEndpointSceneRoute<void>(
        RunOutcomePage(
          completionType: completionType,
          player: _sessionController.player,
          runSummary: _sessionController.runSummary,
        ),
      ),
    );
    if (!mounted) return;

    _isPresentingRunOutcome = false;
    Navigator.of(context).popUntil((route) => route.isFirst);
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
            final hasEndedRun = _sessionController.isRunComplete;
            final hasPendingDaySummary =
                _sessionController.hasPendingDaySummary;
            final hasPendingGhostItemResolution =
                _sessionController.hasPendingGhostItemResolution;
            final isDailyBossStage = PathNodeService.isDailyBossStage(
              currentHour.stageIndex,
            );
            final canOpenLevelUp = player.canLevelUp &&
                !isOpeningNode &&
                !hasEndedRun &&
                !hasPendingDaySummary &&
                !hasPendingGhostItemResolution;
            final tutorialKeys = widget.isTutorialRun ? _tutorialKeys : null;
            Widget pathHeader = _PathHeader(currentHour: currentHour);
            if (tutorialKeys != null) {
              pathHeader = _PathShowcaseStep(
                showcaseKey: tutorialKeys.timeline,
                title: 'Horas',
                description:
                    'Esta barra muestra el avance del dia actual. La run termina tras completar el dia 5.',
                child: pathHeader,
              );
            }

            return _DailyBossScreenShake(
              enabled: isDailyBossStage,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PathBackdrop(nodeCount: nodes.length),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        children: [
                          pathHeader,
                          Expanded(
                            child: Column(
                              children: [
                                const Spacer(),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    const spacing = 14.0;
                                    final encounterCount = nodes.length;
                                    if (encounterCount == 0) {
                                      return Center(
                                        child: EndpointText(
                                          hasPendingDaySummary
                                              ? 'Resumen del dia pendiente'
                                              : 'No hay nodos disponibles',
                                          textAlign: TextAlign.center,
                                          style: textMediumBold.copyWith(
                                            color: EndpointPalette
                                                .softForeground
                                                .withAlpha(205),
                                          ),
                                        ),
                                      );
                                    }
                                    final availableWidth =
                                        constraints.maxWidth -
                                            (spacing * (encounterCount - 1));
                                    final nodeWidth = min(
                                      112.0,
                                      availableWidth / encounterCount,
                                    );

                                    Widget nodesRow = Row(
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
                                            child: _buildPathNodeCard(
                                              node: nodes[index],
                                              isTutorialTarget:
                                                  tutorialKeys != null &&
                                                      index == 0,
                                              isDailyBossStage:
                                                  isDailyBossStage,
                                              onPressed: isOpeningNode ||
                                                      hasEndedRun ||
                                                      hasPendingDaySummary ||
                                                      hasPendingGhostItemResolution
                                                  ? null
                                                  : () => _handleNodePressed(
                                                        nodes[index],
                                                      ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    );

                                    if (tutorialKeys != null) {
                                      nodesRow = _PathShowcaseStep(
                                        showcaseKey: tutorialKeys.nodes,
                                        title: 'Nodos',
                                        description:
                                            'En Death at Sunrise, deberas sobrevivir cinco dias. Cada etapa te pide elegir un nodo para avanzar; el arquetipo solo aparece al empezar.',
                                        targetPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        child: nodesRow,
                                      );
                                    }

                                    return nodesRow;
                                  },
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  child: _PathBottomHud(
                                    player: player,
                                    onOpenOperatives: _handleOpenOperatives,
                                    onOpenAugments: _handleOpenAugments,
                                    onOpenLevelUp: _handleOpenLevelUp,
                                    canOpenLevelUp: canOpenLevelUp,
                                    tutorialKeys: tutorialKeys,
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
            );
          },
        ),
      ),
    );
  }
}

class _PathTutorialShowcaseKeys {
  final GlobalKey nodes = GlobalKey();
  final GlobalKey playerStats = GlobalKey();
  final GlobalKey money = GlobalKey();
  final GlobalKey operatives = GlobalKey();
  final GlobalKey augments = GlobalKey();
  final GlobalKey timeline = GlobalKey();
  final GlobalKey archetypeNode = GlobalKey();
}

class _DailyBossScreenShake extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const _DailyBossScreenShake({
    required this.enabled,
    required this.child,
  });

  @override
  State<_DailyBossScreenShake> createState() => _DailyBossScreenShakeState();
}

class _DailyBossScreenShakeState extends State<_DailyBossScreenShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _shakeTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    );
    _syncShakeTimer();
  }

  @override
  void didUpdateWidget(covariant _DailyBossScreenShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _syncShakeTimer();
    }
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _syncShakeTimer() {
    _shakeTimer?.cancel();
    _shakeTimer = null;
    if (!widget.enabled) {
      _controller
        ..stop()
        ..value = 0;
      return;
    }

    _triggerShake();
    _shakeTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _triggerShake(),
    );
  }

  void _triggerShake() {
    if (!mounted || !widget.enabled || _controller.isAnimating) return;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final progress = _controller.value;
        if (!widget.enabled || progress <= 0) {
          return child!;
        }

        final falloff = 1 - Curves.easeOutCubic.transform(progress);
        final dx = sin(progress * pi * 13) * 3.4 * falloff;
        final dy = cos(progress * pi * 17) * 1.4 * falloff;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: child,
        );
      },
    );
  }
}

class _PathShowcaseStep extends StatelessWidget {
  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;
  final bool allowTargetInteraction;
  final VoidCallback? onTargetClick;
  final List<TooltipActionButton>? tooltipActions;
  final EdgeInsets targetPadding;
  final BorderRadius targetBorderRadius;

  const _PathShowcaseStep({
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.allowTargetInteraction = false,
    this.onTargetClick,
    this.tooltipActions,
    this.targetPadding = const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    this.targetBorderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return Showcase(
      key: showcaseKey,
      scope: _pathTutorialShowcaseScope,
      title: title,
      description: description,
      targetBorderRadius: targetBorderRadius,
      targetPadding: targetPadding,
      overlayColor: EndpointPalette.overlayScrimStrong,
      overlayOpacity: 0.9,
      tooltipBackgroundColor: EndpointPalette.panelBackgroundOpaque,
      tooltipBorderRadius: BorderRadius.circular(12),
      tooltipPadding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      titleTextStyle: textMediumBold.copyWith(
        color: EndpointPalette.infoAccent,
        letterSpacing: 1.1,
      ),
      descTextStyle: textSmallBold.copyWith(
        color: EndpointPalette.softForeground,
        fontSize: 14,
        letterSpacing: 0.4,
        height: 1.25,
      ),
      textColor: EndpointPalette.softForeground,
      disableDefaultTargetGestures: !allowTargetInteraction,
      disableBarrierInteraction: true,
      movingAnimationDuration: const Duration(milliseconds: 240),
      onTargetClick: onTargetClick,
      disposeOnTap: onTargetClick == null ? null : true,
      tooltipActions: tooltipActions,
      child: child,
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
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: EndpointText(
                  currentHour.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textSmallBold.copyWith(
                    color: EndpointPalette.softForeground,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              EndpointText(
                'DIA ${PathNodeService.dayNumberForStageIndex(currentHour.stageIndex)}/${PathNodeService.maxDayNumber}',
                style: textSmallNumericBold.copyWith(
                  color: EndpointPalette.rewardAccent,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _RunTimelineMeter(currentHour: currentHour),
        ],
      ),
    );
  }
}

class _PathBottomHud extends StatelessWidget {
  final Battler player;
  final Future<void> Function() onOpenOperatives;
  final Future<void> Function() onOpenAugments;
  final Future<void> Function() onOpenLevelUp;
  final bool canOpenLevelUp;
  final _PathTutorialShowcaseKeys? tutorialKeys;

  const _PathBottomHud({
    required this.player,
    required this.onOpenOperatives,
    required this.onOpenAugments,
    required this.onOpenLevelUp,
    required this.canOpenLevelUp,
    this.tutorialKeys,
  });

  @override
  Widget build(BuildContext context) {
    final chipTextStyle = textMediumNumericBold.copyWith(
      fontSize: 14,
      letterSpacing: 1.2,
    );

    Widget playerStatus = _PathPlayerStatus(player: player);
    if (tutorialKeys != null) {
      playerStatus = _PathShowcaseStep(
        showcaseKey: tutorialKeys!.playerStats,
        title: 'Operativo',
        description:
            'Aqui ves tu personaje, su vida y sus stats principales antes de escoger el siguiente nodo.',
        child: playerStatus,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        playerStatus,
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final avatarSize = constraints.maxWidth < 360 ? 82.0 : 98.0;
            Widget operativesButton = PathActionButton(
              label: 'Operativos',
              icon: Icons.groups_2_outlined,
              onPressed: onOpenOperatives,
              tooltip: 'Abrir ventana de operativos',
            );
            Widget augmentsButton = PathActionButton(
              label: 'AUMENTOS',
              icon: Icons.auto_awesome_rounded,
              onPressed: onOpenAugments,
              tooltip: 'Abrir panel de AUMENTOS',
            );
            Widget moneyChip = EndpointValueChip(
              icon: Icons.monetization_on_rounded,
              value: player.money,
              accent: EndpointPalette.warningAccent,
              foreground: EndpointPalette.softForegroundWarm,
              textStyle: chipTextStyle,
            );

            final keys = tutorialKeys;
            if (keys != null) {
              operativesButton = _PathShowcaseStep(
                showcaseKey: keys.operatives,
                title: 'Operativos',
                description:
                    'Este boton abre la gestion del operativo, su inventario y el equipo disponible.',
                child: operativesButton,
              );
              augmentsButton = _PathShowcaseStep(
                showcaseKey: keys.augments,
                title: 'AUMENTOS',
                description:
                    'Este boton abre los protocolos y aumentos pasivos que puedes revisar en ruta.',
                child: augmentsButton,
              );
              moneyChip = _PathShowcaseStep(
                showcaseKey: keys.money,
                title: 'Creditos',
                description:
                    'Este contador muestra el dinero disponible. Los creditos sirven para comprar y activar ciertos efectos.',
                targetPadding: const EdgeInsets.all(4),
                child: moneyChip,
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 132),
                      child: operativesButton,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PathLevelUpAvatarButton(
                          player: player,
                          size: avatarSize,
                          onPressed: canOpenLevelUp ? onOpenLevelUp : null,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            moneyChip,
                            const SizedBox(width: 8),
                            EndpointValueChip(
                              icon: Icons.trending_up_rounded,
                              value: player.income,
                              accent: EndpointPalette.infoAccent,
                              foreground: EndpointPalette.soften(
                                  EndpointPalette.infoAccent),
                              textStyle: chipTextStyle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 118),
                      child: augmentsButton,
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

class _PathLevelUpAvatarButton extends StatelessWidget {
  final Battler player;
  final double size;
  final Future<void> Function()? onPressed;

  const _PathLevelUpAvatarButton({
    required this.player,
    required this.size,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const accent = EndpointPalette.primaryAccent;
    final isEnabled = onPressed != null;
    final avatar = EndpointEmojiSprite(
      emoji: player.iconEmoji,
      accent: isEnabled ? EndpointPalette.rewardAccent : accent,
      size: size,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed == null
                ? null
                : () {
                    unawaited(onPressed!.call());
                  },
            borderRadius: BorderRadius.circular(size * 0.22),
            child: Opacity(
              opacity: isEnabled ? 1 : 0.94,
              child: avatar,
            ),
          ),
        ),
        if (isEnabled)
          Positioned(
            top: -8,
            right: -10,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: EndpointPalette.panelBackgroundBattleOpaque,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: EndpointPalette.rewardAccent.withValues(alpha: 0.86),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          EndpointPalette.rewardAccent.withValues(alpha: 0.14),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: EndpointText(
                    'LVL UP',
                    style: textSmallBold.copyWith(
                      color: EndpointPalette.softForegroundWarm,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
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
    final barrierAccent = BattlerStat.barrier.accent;
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
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
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
                  label: 'Barrera',
                  value: player.barrier,
                  accent: barrierAccent,
                  foreground:
                      EndpointPalette.soften(barrierAccent, amount: 0.24),
                  textStyle: statChipTextStyle,
                ),
                EndpointValueChip(
                  label: 'LV',
                  value: player.level,
                  accent: EndpointPalette.rewardAccent,
                  foreground: EndpointPalette.softForegroundWarm,
                  textStyle: statChipTextStyle,
                ),
              ],
            ),
            if (!player.isAtMaxLevel) ...[
              const SizedBox(height: 10),
              EndpointText(
                'XP ${player.displayedExperience}/${player.experienceToNextLevel}',
                style: textSmallBold.copyWith(
                  color: EndpointPalette.rewardAccent,
                  letterSpacing: 1.1,
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              EndpointText(
                'NIVEL MAXIMO',
                style: textSmallBold.copyWith(
                  color: EndpointPalette.rewardAccent,
                  letterSpacing: 1.1,
                ),
              ),
            ],
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
    final progress = PathNodeService.progressWithinDayForStageIndex(
      currentHour.stageIndex,
    );

    return SizedBox(
      height: 20,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(87),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: EndpointPalette.primaryAccent.withAlpha(51),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
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
          PathNodeService.duskStageOffset /
              PathNodeService.dailyBossStageOffset,
        ),
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
      ..color = EndpointPalette.primaryAccent.withAlpha(18)
      ..strokeWidth = 1;
    final pathPaint = Paint()
      ..color = EndpointPalette.primaryAccent.withAlpha(36)
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
