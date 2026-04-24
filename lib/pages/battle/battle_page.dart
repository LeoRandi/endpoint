import '../_imports.dart';

part 'battle_page_view.dart';
part 'battle_page_huds.dart';
part 'battle_page_loadout.dart';

const _battleAttackFlightDuration = Duration(milliseconds: 750);
const _battleAttackSlowLaunchDuration = Duration(milliseconds: 550);
const _battleAttackFastImpactDuration = Duration(milliseconds: 200);
const _battleImpactBarDuration = Duration(milliseconds: 250);
const _battleSwordAssetPath = 'assets/images/icons/icon_sword.png';
const _battleShieldAssetPath = 'assets/images/icons/icon_shield.png';
const _battleSwordAnimationSize = 46.0;

class _BattleCombatIconMotion {
  final BattleCombatAnimationHook hook;
  final Offset start;
  final Offset end;
  final BattleCombatantSide primarySide;
  final String assetPath;

  const _BattleCombatIconMotion({
    required this.hook,
    required this.start,
    required this.end,
    required this.primarySide,
    required this.assetPath,
  });
}

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

class _BattlePageState extends State<BattlePage> with TickerProviderStateMixin {
  late final BattleSceneController _sceneController;
  late final AnimationController _attackFlightController;
  final GlobalKey _battleAnimationRootKey = GlobalKey();
  final GlobalKey _playerSideKey = GlobalKey();
  final GlobalKey _enemySideKey = GlobalKey();
  final GlobalKey _playerStatusBarKey = GlobalKey();
  final GlobalKey _enemyStatusBarKey = GlobalKey();
  EndpointSettingsSnapshot? _settingsSnapshot;
  _BattleCombatIconMotion? _activeCombatIconMotion;
  Battler? _displayPlayerOverride;
  Battler? _displayEnemyOverride;
  int? _playerBarrierAnimationReference;
  int? _enemyBarrierAnimationReference;
  Set<BattleCombatantSide> _animatedHealthSides = const {};
  Set<BattleCombatantSide> _animatedBarrierSides = const {};
  bool _isPlayingBattleAnimation = false;
  bool _releaseDisplayOverrideOnNextSceneChange = false;
  bool _isPresentingDrawAttack = false;
  bool _isPresentingDrawDefense = false;
  bool _isQuickDrawAvailable = true;
  int _quickDrawUseCount = 0;
  int _quickDrawPerfectsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _attackFlightController = AnimationController(
      vsync: this,
      duration: _battleAttackFlightDuration,
    );
    _sceneController = BattleSceneController(
      enemy: widget.enemy,
      player: widget.player,
      phase: widget.phase,
      enemyTier: widget.enemyTier,
      enemyTurnDelay: widget.enemyTurnDelay,
      combatEndDelay: widget.combatEndDelay,
      victoryMoneyFactor: widget.victoryMoneyFactor,
      randomizer: widget.randomizer,
      onCombatAnimation: _playCombatAnimationCue,
    )..addListener(_handleSceneChanged);
    unawaited(_loadSettingsSnapshot());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_playInitialCombatHealthAnimations());
    });
  }

  @override
  void dispose() {
    _sceneController
      ..removeListener(_handleSceneChanged)
      ..dispose();
    _attackFlightController.dispose();
    super.dispose();
  }

  /// Sincroniza la navegacion real con las salidas diferidas que publica el controlador de escena.
  void _handleSceneChanged() {
    if (!mounted) return;

    if (_releaseDisplayOverrideOnNextSceneChange) {
      setState(() {
        _releaseDisplayOverrideOnNextSceneChange = false;
        _displayPlayerOverride = null;
        _displayEnemyOverride = null;
        _activeCombatIconMotion = null;
        _playerBarrierAnimationReference = null;
        _enemyBarrierAnimationReference = null;
        _animatedHealthSides = const {};
        _animatedBarrierSides = const {};
        _isPlayingBattleAnimation = false;
      });
    }

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
  Battler get _displayPlayer =>
      _displayPlayerOverride ?? _sceneController.player;
  Battler get _displayEnemy => _displayEnemyOverride ?? _sceneController.enemy;

  void _handlePlayerAttack() {
    unawaited(_handlePlayerAttackFlow());
  }

  void _handlePlayerBlock() {
    unawaited(_handlePlayerBlockFlow());
  }

  Future<void> _handlePlayerAttackFlow() async {
    if (!_sceneController.canUseActions ||
        _sceneController.hasPendingVictoryRewards ||
        _isPlayingBattleAnimation) {
      return;
    }

    final settings = await _ensureSettingsSnapshot();
    if (!mounted) return;
    if (settings.gameMode != EndpointGameMode.drawing) {
      await _sceneController.handlePlayerAttack();
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
          quickDrawPerfectsRemaining: _quickDrawPerfectsRemaining,
          nextQuickDrawPerfectCost: _quickDrawUseCount + 1,
        ),
      );
      if (!mounted || drawResult == null) return;

      await _sceneController.handlePlayerAttack(
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
        _sceneController.hasPendingVictoryRewards ||
        _isPlayingBattleAnimation) {
      return;
    }

    final settings = await _ensureSettingsSnapshot();
    if (!mounted) return;
    if (settings.gameMode != EndpointGameMode.drawing) {
      await _sceneController.handlePlayerBlock();
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
          quickDrawPerfectsRemaining: _quickDrawPerfectsRemaining,
          nextQuickDrawPerfectCost: _quickDrawUseCount + 1,
        ),
      );
      if (!mounted || drawResult == null) return;

      await _sceneController.handlePlayerBlock(
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

  Future<void> _playCombatAnimationCue(BattleCombatAnimationCue cue) async {
    if (!mounted) return;

    switch (cue.hook) {
      case BattleCombatAnimationHook.attackMotion:
      case BattleCombatAnimationHook.blockMotion:
        await _playCombatMotionCue(cue);
        break;
      case BattleCombatAnimationHook.damageTaken:
      case BattleCombatAnimationHook.healthLoss:
      case BattleCombatAnimationHook.healthGain:
      case BattleCombatAnimationHook.barrierGain:
      case BattleCombatAnimationHook.barrierLoss:
        await _playCombatStatCue(cue);
        break;
    }
  }

  Future<void> _playInitialCombatHealthAnimations() async {
    if (!mounted || _sceneController.isCombatFinished) return;

    final playerBefore = widget.player.prepareForCombat(phase: widget.phase);
    final enemyBefore = widget.enemy.prepareForCombat(phase: widget.phase);
    final playerAfter = _sceneController.player;
    final enemyAfter = _sceneController.enemy;
    if (playerAfter.health > playerBefore.health) {
      await _playCombatAnimationCue(
        BattleCombatAnimationCue(
          hook: BattleCombatAnimationHook.healthGain,
          primarySide: BattleCombatantSide.player,
          playerBefore: playerBefore,
          enemyBefore: enemyBefore,
          playerAfter: playerAfter,
          enemyAfter: enemyBefore,
        ),
      );
    }
    if (!mounted) return;
    if (enemyAfter.health > enemyBefore.health) {
      await _playCombatAnimationCue(
        BattleCombatAnimationCue(
          hook: BattleCombatAnimationHook.healthGain,
          primarySide: BattleCombatantSide.enemy,
          playerBefore: playerAfter,
          enemyBefore: enemyBefore,
          playerAfter: playerAfter,
          enemyAfter: enemyAfter,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _releaseDisplayOverrideOnNextSceneChange = false;
      _displayPlayerOverride = null;
      _displayEnemyOverride = null;
      _animatedHealthSides = const {};
      _animatedBarrierSides = const {};
      _isPlayingBattleAnimation = false;
    });
  }

  Future<void> _playCombatMotionCue(BattleCombatAnimationCue cue) async {
    final secondarySide = cue.secondarySide;
    if (secondarySide == null) return;

    final start = _centerForSide(cue.primarySide);
    final end = cue.hook == BattleCombatAnimationHook.blockMotion
        ? _centerForSide(secondarySide)
        : _centerForStatusBar(secondarySide);
    final assetPath = cue.hook == BattleCombatAnimationHook.blockMotion
        ? _battleShieldAssetPath
        : _battleSwordAssetPath;
    setState(() {
      _isPlayingBattleAnimation = true;
      _releaseDisplayOverrideOnNextSceneChange = false;
      _displayPlayerOverride = cue.playerBefore;
      _displayEnemyOverride = cue.enemyBefore;
      _animatedHealthSides = const {};
      _animatedBarrierSides = const {};
      _activeCombatIconMotion = _BattleCombatIconMotion(
        hook: cue.hook,
        start: start,
        end: end,
        primarySide: cue.primarySide,
        assetPath: assetPath,
      );
    });

    try {
      await _attackFlightController.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;

    setState(() {
      _activeCombatIconMotion = null;
      _isPlayingBattleAnimation = false;
    });
  }

  Future<void> _playCombatStatCue(BattleCombatAnimationCue cue) async {
    final animatedSide = cue.primarySide;
    final animatesHealth = cue.hook == BattleCombatAnimationHook.damageTaken ||
        cue.hook == BattleCombatAnimationHook.healthLoss ||
        cue.hook == BattleCombatAnimationHook.healthGain;
    final animatesBarrier = cue.hook == BattleCombatAnimationHook.damageTaken ||
        cue.hook == BattleCombatAnimationHook.barrierLoss ||
        cue.hook == BattleCombatAnimationHook.barrierGain;

    setState(() {
      _isPlayingBattleAnimation = true;
      _releaseDisplayOverrideOnNextSceneChange = false;
      _displayPlayerOverride = cue.playerBefore;
      _displayEnemyOverride = cue.enemyBefore;
      _playerBarrierAnimationReference = _barrierAnimationReferenceFor(
        cue.playerBefore,
        cue.playerAfter,
      );
      _enemyBarrierAnimationReference = _barrierAnimationReferenceFor(
        cue.enemyBefore,
        cue.enemyAfter,
      );
      _animatedHealthSides = const {};
      _animatedBarrierSides = const {};
      _activeCombatIconMotion = null;
    });

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    setState(() {
      _displayPlayerOverride = cue.playerAfter;
      _displayEnemyOverride = cue.enemyAfter;
      _animatedHealthSides = animatesHealth
          ? <BattleCombatantSide>{animatedSide}
          : const <BattleCombatantSide>{};
      _animatedBarrierSides = animatesBarrier
          ? <BattleCombatantSide>{animatedSide}
          : const <BattleCombatantSide>{};
    });

    await Future<void>.delayed(_battleImpactBarDuration);
    if (!mounted) return;
    _releaseDisplayOverrideOnNextSceneChange = true;
  }

  int? _barrierAnimationReferenceFor(Battler before, Battler after) {
    final reference = max(
      max(before.currentBarrier, before.maxBarrier),
      max(after.currentBarrier, after.maxBarrier),
    );
    return reference > 0 ? reference : null;
  }

  Offset _centerForSide(BattleCombatantSide side) {
    final key =
        side == BattleCombatantSide.player ? _playerSideKey : _enemySideKey;
    return _centerOfKey(key) ?? _fallbackCenterForSide(side);
  }

  Offset _centerForStatusBar(BattleCombatantSide side) {
    final key = side == BattleCombatantSide.player
        ? _playerStatusBarKey
        : _enemyStatusBarKey;
    return _centerOfKey(key) ?? _fallbackCenterForSide(side);
  }

  Offset? _centerOfKey(GlobalKey key) {
    final rootBox = _battleAnimationRootKey.currentContext?.findRenderObject();
    final targetBox = key.currentContext?.findRenderObject();
    if (rootBox is! RenderBox ||
        targetBox is! RenderBox ||
        !rootBox.hasSize ||
        !targetBox.hasSize) {
      return null;
    }

    final targetCenter = targetBox.localToGlobal(
      targetBox.size.center(Offset.zero),
    );
    return rootBox.globalToLocal(targetCenter);
  }

  Offset _fallbackCenterForSide(BattleCombatantSide side) {
    final rootBox = _battleAnimationRootKey.currentContext?.findRenderObject();
    final size = rootBox is RenderBox && rootBox.hasSize
        ? rootBox.size
        : MediaQuery.sizeOf(context);
    final verticalFactor = side == BattleCombatantSide.enemy ? 0.25 : 0.75;
    return Offset(size.width * 0.5, size.height * verticalFactor);
  }

  void _syncQuickDrawState(BattleDrawOverlayResult drawResult) {
    var nextAvailability = _isQuickDrawAvailable;
    var nextUseCount = _quickDrawUseCount;
    var nextPerfectsRemaining = _quickDrawPerfectsRemaining;

    if (drawResult.consumedQuickDraw) {
      nextUseCount += 1;
      nextPerfectsRemaining = nextUseCount;
      nextAvailability = false;
    }

    if (drawResult.achievedPerfect && !nextAvailability) {
      nextPerfectsRemaining = max(0, nextPerfectsRemaining - 1);
      nextAvailability = nextPerfectsRemaining <= 0;
    }

    if (!mounted ||
        (nextAvailability == _isQuickDrawAvailable &&
            nextUseCount == _quickDrawUseCount &&
            nextPerfectsRemaining == _quickDrawPerfectsRemaining)) {
      return;
    }
    setState(() {
      _isQuickDrawAvailable = nextAvailability;
      _quickDrawUseCount = nextUseCount;
      _quickDrawPerfectsRemaining =
          nextAvailability ? 0 : nextPerfectsRemaining;
    });
  }

  Future<void> _handleOpenEquippedItemDetails(
    Battler battler,
    Item item,
  ) async {
    if (_sceneController.hasPendingVictoryRewards ||
        _isPlayingBattleAnimation) {
      return;
    }

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
    if (_sceneController.hasPendingVictoryRewards ||
        _isPlayingBattleAnimation) {
      return;
    }

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
                      unawaited(
                        _sceneController.togglePlayerAbility(currentAbility),
                      );
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
      displayPlayer: _displayPlayer,
      displayEnemy: _displayEnemy,
      isDrawingMode: _isDrawingMode,
      isPresentingDrawAttack: _isPresentingDrawAttack,
      isPresentingDrawDefense: _isPresentingDrawDefense,
      isPlayingBattleAnimation: _isPlayingBattleAnimation,
      battleAnimationRootKey: _battleAnimationRootKey,
      playerSideKey: _playerSideKey,
      enemySideKey: _enemySideKey,
      playerStatusBarKey: _playerStatusBarKey,
      enemyStatusBarKey: _enemyStatusBarKey,
      attackFlightAnimation: _attackFlightController,
      activeCombatIconMotion: _activeCombatIconMotion,
      playerBarrierAnimationReference: _playerBarrierAnimationReference,
      enemyBarrierAnimationReference: _enemyBarrierAnimationReference,
      animatedHealthSides: _animatedHealthSides,
      animatedBarrierSides: _animatedBarrierSides,
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
