import '../_imports.dart';

part 'battle_page_view.dart';
part 'battle_page_huds.dart';
part 'battle_page_loadout.dart';

class BattlePage extends StatefulWidget {
  final Battler enemy;
  final Battler player;
  final RunRandomizer? randomizer;
  final RunHourPhase phase;
  final String showTitle;
  final int victoryMoneyFactor;
  final int enemyTier;
  final Duration enemyTurnDelay;
  final Duration combatEndDelay;
  final bool returnResultToCaller;

  const BattlePage({
    super.key,
    this.enemy = defaultEnemyBattler,
    this.player = defaultPlayerBattler,
    this.randomizer,
    this.phase = RunHourPhase.day,
    this.showTitle = 'ENCOUNTER',
    this.victoryMoneyFactor = 0,
    this.enemyTier = 1,
    this.enemyTurnDelay = const Duration(milliseconds: 900),
    this.combatEndDelay = const Duration(seconds: 2),
    this.returnResultToCaller = false,
  });

  @override
  State<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends State<BattlePage> {
  late final BattleSceneController _sceneController;
  EndpointSettingsSnapshot? _settingsSnapshot;
  bool _isPresentingDrawAttack = false;
  bool _isPresentingDrawDefense = false;
  bool _isQuickDrawAvailable = true;

  @override
  void initState() {
    super.initState();
    _sceneController = BattleSceneController(
      enemy: widget.enemy,
      player: widget.player,
      phase: widget.phase,
      enemyTier: widget.enemyTier,
      enemyTurnDelay: widget.enemyTurnDelay,
      combatEndDelay: widget.combatEndDelay,
      victoryMoneyFactor: widget.victoryMoneyFactor,
      randomizer: widget.randomizer,
    )..addListener(_handleSceneChanged);
    unawaited(_loadSettingsSnapshot());
  }

  @override
  void dispose() {
    _sceneController
      ..removeListener(_handleSceneChanged)
      ..dispose();
    super.dispose();
  }

  /// Sincroniza la navegacion real con las salidas diferidas que publica el controlador de escena.
  void _handleSceneChanged() {
    if (!mounted) return;

    final exitResult = _sceneController.consumeImmediateExitResult();
    if (exitResult != null) {
      _completeBattleExit(exitResult);
      return;
    }

    if (_sceneController.hasPendingVictoryRewards &&
        !_sceneController.isPresentingRewards) {
      _handleOpenPendingRewards();
    }
  }

  /// Abre el overlay de botin cuando la salida de victoria requiere una decision visual previa.
  Future<Battler?> _presentVictoryRewards(
    BattleSceneExitRequest request,
  ) async {
    if (!request.rewards.hasRewards) {
      return request.exitResult.player;
    }

    return showEndpointOverlay<Battler>(
      context: context,
      barrierDismissible: false,
      barrierColor: EndpointPalette.overlayScrimStrong,
      builder: (_) => BattleLootOverlay(
        player: request.exitResult.player,
        lootItem: request.rewards.lootItem,
        lootAbility: request.rewards.lootAbility,
        moneyReward: request.rewards.moneyReward,
        enemyName: _sceneController.enemy.name,
      ),
    );
  }

  void _completeBattleExit(BattleFlowResult exitResult) {
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return;

    if (widget.returnResultToCaller) {
      navigator.pop(exitResult);
      return;
    }

    navigator.popUntil((route) => route.isFirst);
  }

  Future<void> _loadSettingsSnapshot() async {
    final settings = await EndpointPreferencesService.loadSettingsSnapshot();
    if (!mounted) return;
    setState(() {
      _settingsSnapshot = settings;
    });
  }

  Future<EndpointSettingsSnapshot> _ensureSettingsSnapshot() async {
    final currentSettings = _settingsSnapshot;
    if (currentSettings != null) return currentSettings;

    final loadedSettings =
        await EndpointPreferencesService.loadSettingsSnapshot();
    if (mounted) {
      setState(() {
        _settingsSnapshot = loadedSettings;
      });
    } else {
      _settingsSnapshot = loadedSettings;
    }
    return loadedSettings;
  }

  bool get _isDrawingMode =>
      _settingsSnapshot?.gameMode == EndpointGameMode.drawing;

  void _handlePlayerAttack() {
    unawaited(_handlePlayerAttackFlow());
  }

  void _handlePlayerBlock() {
    unawaited(_handlePlayerBlockFlow());
  }

  Future<void> _handlePlayerAttackFlow() async {
    if (!_sceneController.canUseActions ||
        _sceneController.hasPendingVictoryRewards) {
      return;
    }

    final settings = await _ensureSettingsSnapshot();
    if (!mounted) return;
    if (settings.gameMode != EndpointGameMode.drawing) {
      _sceneController.handlePlayerAttack();
      return;
    }
    if (_isPresentingDrawAttack) return;

    setState(() {
      _isPresentingDrawAttack = true;
    });

    try {
      final drawResult = await showEndpointOverlay<BattleDrawOverlayResult>(
        context: context,
        barrierDismissible: false,
        barrierColor: EndpointPalette.overlayScrimStrong,
        builder: (_) => BattleDrawAttackOverlay(
          attacker: _sceneController.player,
          defender: _sceneController.enemy,
          playerInitialBarrier: _sceneController.playerInitialBarrier,
          randomizer: _sceneController.randomizer,
          isQuickDrawAvailable: _isQuickDrawAvailable,
        ),
      );
      if (!mounted || drawResult == null) return;

      _sceneController.handlePlayerAttack(
        drawingBonus: drawResult.resolution.bonus,
        drawingPenalty: drawResult.resolution.penalty,
      );
      _syncQuickDrawState(drawResult);
    } finally {
      if (mounted) {
        setState(() {
          _isPresentingDrawAttack = false;
        });
      }
    }
  }

  Future<void> _handlePlayerBlockFlow() async {
    if (!_sceneController.canUseActions ||
        _sceneController.hasPendingVictoryRewards) {
      return;
    }

    final settings = await _ensureSettingsSnapshot();
    if (!mounted) return;
    if (settings.gameMode != EndpointGameMode.drawing) {
      _sceneController.handlePlayerBlock();
      return;
    }
    if (_isPresentingDrawDefense) return;

    setState(() {
      _isPresentingDrawDefense = true;
    });

    try {
      final drawResult = await showEndpointOverlay<BattleDrawOverlayResult>(
        context: context,
        barrierDismissible: false,
        barrierColor: EndpointPalette.overlayScrimStrong,
        builder: (_) => BattleDrawDefenseOverlay(
          defender: _sceneController.player,
          attacker: _sceneController.enemy,
          playerInitialBarrier: _sceneController.playerInitialBarrier,
          randomizer: _sceneController.randomizer,
          isQuickDrawAvailable: _isQuickDrawAvailable,
        ),
      );
      if (!mounted || drawResult == null) return;

      _sceneController.handlePlayerBlock(
        drawingBonus: drawResult.resolution.bonus,
        drawingPenalty: drawResult.resolution.penalty,
      );
      _syncQuickDrawState(drawResult);
    } finally {
      if (mounted) {
        setState(() {
          _isPresentingDrawDefense = false;
        });
      }
    }
  }

  Future<void> _handleOpenPendingRewards() async {
    final request = _sceneController.pendingRewardExitRequest;
    if (request == null || _sceneController.isPresentingRewards) return;

    _sceneController.beginRewardPresentation();
    final rewardedPlayer = await _presentVictoryRewards(request);
    if (!mounted) return;

    _sceneController.completeRewardPresentation(rewardedPlayer);
    final exitResult = _sceneController.consumeImmediateExitResult();
    if (exitResult != null) {
      _completeBattleExit(exitResult);
    }
  }

  void _syncQuickDrawState(BattleDrawOverlayResult drawResult) {
    var shouldNotify = false;
    var nextValue = _isQuickDrawAvailable;
    if (drawResult.consumedQuickDraw) {
      nextValue = false;
      shouldNotify = true;
    }
    if (drawResult.achievedPerfect) {
      nextValue = true;
      shouldNotify = true;
    }

    if (!mounted || !shouldNotify || nextValue == _isQuickDrawAvailable) {
      return;
    }
    setState(() {
      _isQuickDrawAvailable = nextValue;
    });
  }

  Future<void> _handleOpenEquippedItemDetails(
    Battler battler,
    Item item,
  ) async {
    if (_sceneController.hasPendingVictoryRewards) return;

    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de objeto equipado',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return EndpointItemDetailsDialog(
          item: item,
          accent: item.rarity.accent,
          price: item.cost,
          statusText: _sceneController.statusLabelFor(battler, item),
        );
      },
    );
  }

  Future<void> _handleOpenAbilityDetails(
    BattlerAbility ability, {
    required bool canControlOwner,
  }) async {
    if (_sceneController.hasPendingVictoryRewards) return;

    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de habilidad',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return AnimatedBuilder(
          animation: _sceneController.battleController,
          builder: (context, _) {
            final currentOwner = canControlOwner
                ? _sceneController.player
                : _sceneController.enemy;
            final currentAbility =
                currentOwner.abilityById(ability.id) ?? ability;

            return EndpointAbilityDetailsDialog(
              ability: currentAbility,
              accent: currentAbility.accent,
              statusText: _sceneController.abilityStatusTextFor(
                currentAbility,
                canControlOwner: canControlOwner,
              ),
              actionLabel: _sceneController.abilityActionLabelFor(
                currentAbility,
                canControlOwner: canControlOwner,
              ),
              onPrimaryAction: _sceneController.isAbilityActionEnabled(
                currentAbility,
                canControlOwner: canControlOwner,
              )
                  ? () {
                      _sceneController.togglePlayerAbility(currentAbility);
                    }
                  : null,
              isActionEnabled: _sceneController.isAbilityActionEnabled(
                currentAbility,
                canControlOwner: canControlOwner,
              ),
              enabledActionTooltip: currentAbility.isActive
                  ? 'Desactivar habilidad manual'
                  : 'Activar habilidad manual',
              disabledActionTooltip:
                  _sceneController.disabledAbilityActionTooltipFor(
                currentAbility,
                canControlOwner: canControlOwner,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _BattleSceneView(
      showTitle: widget.showTitle,
      sceneController: _sceneController,
      isDrawingMode: _isDrawingMode,
      isPresentingDrawAttack: _isPresentingDrawAttack,
      isPresentingDrawDefense: _isPresentingDrawDefense,
      onAttack: _handlePlayerAttack,
      onBlock: _handlePlayerBlock,
      onAdvancePressed: _handleOpenPendingRewards,
      onOpenPlayerItemDetails: (item) {
        return _handleOpenEquippedItemDetails(
          _sceneController.player,
          item,
        );
      },
      onOpenEnemyItemDetails: (item) {
        return _handleOpenEquippedItemDetails(
          _sceneController.enemy,
          item,
        );
      },
      onOpenPlayerAbilityDetails: (ability) {
        return _handleOpenAbilityDetails(
          ability,
          canControlOwner: true,
        );
      },
      onOpenEnemyAbilityDetails: (ability) {
        return _handleOpenAbilityDetails(
          ability,
          canControlOwner: false,
        );
      },
    );
  }
}
