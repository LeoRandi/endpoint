import '../_imports.dart';

part 'battle_page_view.dart';
part 'battle_page_huds.dart';
part 'battle_page_loadout.dart';

const _battleAttackFlightDuration = Duration(milliseconds: 750);
const _battleAttackFollowUpStagger = Duration(milliseconds: 330);
const _battleAttackSlowLaunchDuration = Duration(milliseconds: 550);
const _battleAttackFastImpactDuration = Duration(milliseconds: 200);
const _battleImpactBarDuration = Duration(milliseconds: 250);
const _battleFloatingNumberDuration = Duration(milliseconds: 520);
const _battleStatusEffectBurstDuration = Duration(milliseconds: 500);
const _battleFragilidadBurstDuration = Duration(milliseconds: 620);
const _battleSwordAssetPath = 'assets/images/icons/icon_sword.png';
const _battleShieldAssetPath = 'assets/images/icons/icon_shield.png';
const _battleFistAssetPath = 'assets/images/icons/icon_unarmed.png';
const _battleSwordAnimationSize = 46.0;

class _BattleCombatIconMotion {
  final BattleCombatAnimationHook hook;
  final Offset start;
  final Offset end;
  final BattleCombatantSide primarySide;
  final String assetPath;
  final int effectCount;
  final Duration totalDuration;

  const _BattleCombatIconMotion({
    required this.hook,
    required this.start,
    required this.end,
    required this.primarySide,
    required this.assetPath,
    required this.effectCount,
    required this.totalDuration,
  });
}

class _BattleStatusEffectParticle {
  final Offset start;
  final double drift;
  final double travelDistance;
  final double delay;
  final double scale;

  const _BattleStatusEffectParticle({
    required this.start,
    required this.drift,
    required this.travelDistance,
    required this.delay,
    required this.scale,
  });
}

class _BattleStatusEffectBurst {
  final int id;
  final bool rises;
  final String? symbol;
  final IconData? icon;
  final Color accent;
  final List<_BattleStatusEffectParticle> particles;

  const _BattleStatusEffectBurst({
    required this.id,
    required this.rises,
    this.symbol,
    this.icon,
    required this.accent,
    required this.particles,
  }) : assert(symbol != null || icon != null);
}

class _BattleFloatingNumberParticle {
  final String label;
  final Color color;
  final Offset start;
  final double delay;

  const _BattleFloatingNumberParticle({
    required this.label,
    required this.color,
    required this.start,
    required this.delay,
  });
}

class _BattleFloatingNumberBurst {
  final int id;
  final List<_BattleFloatingNumberParticle> particles;

  const _BattleFloatingNumberBurst({
    required this.id,
    required this.particles,
  });
}

class _BattleMoneyBurst {
  final int id;
  final Rect iconRect;
  final int amount;
  final bool isGain;

  const _BattleMoneyBurst({
    required this.id,
    required this.iconRect,
    required this.amount,
    required this.isGain,
  });
}

class _BattleFragilidadBurst {
  final int id;
  final Offset center;

  const _BattleFragilidadBurst({
    required this.id,
    required this.center,
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
  late final ValueNotifier<Widget?> _patternCombatAnimationOverlay;
  late final ValueNotifier<BattlePatternVisualBattlers> _patternVisualBattlers;
  final Random _statusEffectVisualRandom = Random();
  final GlobalKey _battleAnimationRootKey = GlobalKey();
  final GlobalKey _playerSideKey = GlobalKey();
  final GlobalKey _enemySideKey = GlobalKey();
  final GlobalKey _playerStatusBarKey = GlobalKey();
  final GlobalKey _enemyStatusBarKey = GlobalKey();
  EndpointSettingsSnapshot? _settingsSnapshot;
  _BattleCombatIconMotion? _activeCombatIconMotion;
  _BattleStatusEffectBurst? _activeStatusEffectBurst;
  _BattleFloatingNumberBurst? _activeFloatingNumberBurst;
  _BattleMoneyBurst? _activeMoneyBurst;
  _BattleFragilidadBurst? _activeFragilidadBurst;
  BattlePatternAnimationTargets? _patternAnimationTargets;
  Battler? _displayPlayerOverride;
  Battler? _displayEnemyOverride;
  BattleFlowResult? _deferredPatternExitResult;
  int? _playerBarrierAnimationReference;
  int? _enemyBarrierAnimationReference;
  Set<BattleCombatantSide> _animatedHealthSides = const {};
  Set<BattleCombatantSide> _animatedBarrierSides = const {};
  bool _isPlayingBattleAnimation = false;
  bool _releaseDisplayOverrideOnNextSceneChange = false;
  bool _isPresentingPatternMatch = false;
  Map<String, int> _patternItemPointUseCounts = const <String, int>{};
  BattlePatternBlockMode? _previousYellowPatternBlockMode;
  int _statusEffectBurstSequence = 0;
  int _floatingNumberBurstSequence = 0;
  int _moneyBurstSequence = 0;
  int _fragilidadBurstSequence = 0;

  @override
  void initState() {
    super.initState();
    _attackFlightController = AnimationController(
      vsync: this,
      duration: _battleAttackFlightDuration,
    );
    _patternCombatAnimationOverlay = ValueNotifier<Widget?>(null);
    _patternVisualBattlers = ValueNotifier<BattlePatternVisualBattlers>(
      BattlePatternVisualBattlers(
        player: widget.player.prepareForCombat(phase: widget.phase),
        enemy: widget.enemy.prepareForCombat(phase: widget.phase),
      ),
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
    _patternCombatAnimationOverlay.dispose();
    _patternVisualBattlers.dispose();
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
        _activeStatusEffectBurst = null;
        _activeMoneyBurst = null;
        _activeFragilidadBurst = null;
        _playerBarrierAnimationReference = null;
        _enemyBarrierAnimationReference = null;
        _animatedHealthSides = const {};
        _animatedBarrierSides = const {};
        _isPlayingBattleAnimation = false;
      });
      _refreshPatternCombatAnimationOverlay();
    }

    final exitResult = _sceneController.consumeImmediateExitResult();
    if (exitResult != null) {
      if (_isPresentingPatternMatch) {
        _deferredPatternExitResult = exitResult;
        return;
      }
      _completeBattleExit(exitResult);
      return;
    }

    if (_sceneController.hasPendingVictoryRewards &&
        !_sceneController.isPresentingRewards &&
        !_isPresentingPatternMatch) {
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

    final settings = await _ensureSettingsSnapshot();
    if (!mounted) return request.exitResult.player;

    return showEndpointOverlay<Battler>(
      context: context,
      barrierDismissible: false,
      barrierColor: EndpointPalette.overlayScrimStrong,
      builder: (_) => BattleLootOverlay(
        player: request.exitResult.player,
        lootItem: request.rewards.lootItem,
        itemRewards: request.rewards.itemRewards,
        lootAbility: request.rewards.lootAbility,
        moneyReward: request.rewards.moneyReward,
        enemyName: _sceneController.enemy.name,
        gameMode: settings.gameMode,
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

  bool get _isPatternMode =>
      _settingsSnapshot?.gameMode == EndpointGameMode.pattern;

  bool get _canOpenPreviewOperatives {
    return _sceneController.currentRound == 1 &&
        _sceneController.turn == BattleTurnState.player &&
        _sceneController.canUseActions &&
        !_sceneController.hasPendingVictoryRewards &&
        !_isPlayingBattleAnimation &&
        !_isPresentingPatternMatch;
  }

  Future<void> _handleOpenPreviewOperatives() async {
    if (!_canOpenPreviewOperatives) return;

    final settings = await _ensureSettingsSnapshot();
    if (!mounted || !_canOpenPreviewOperatives) return;

    await showEndpointOverlay<void>(
      context: context,
      barrierColor: EndpointPalette.overlayScrimStrong,
      builder: (_) => OperativesOverlay(
        player: _sceneController.player,
        gameMode: settings.gameMode,
        onPlayerChanged: _sceneController.replacePlayer,
      ),
    );
  }

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
    if (settings.gameMode == EndpointGameMode.pattern) {
      await _handlePlayerPatternMatchFlow();
      return;
    }
    await _sceneController.handlePlayerAttack();
  }

  Future<void> _handlePlayerPatternMatchFlow() async {
    if (_isPresentingPatternMatch) return;

    setState(() {
      _isPresentingPatternMatch = true;
    });

    try {
      while (mounted &&
          _isPatternMode &&
          _sceneController.canUseActions &&
          !_sceneController.hasPendingVictoryRewards &&
          !_sceneController.isCombatFinished) {
        final didResolvePlayerTurn = await _presentPlayerPatternTurn();
        if (!mounted || !didResolvePlayerTurn) return;

        if (!_sceneController.canResolveEnemyPattern ||
            _sceneController.hasPendingVictoryRewards ||
            _sceneController.isCombatFinished) {
          return;
        }

        final didResolveEnemyTurn = await _handleEnemyPatternMatchFlow();
        if (!mounted || !didResolveEnemyTurn) return;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPresentingPatternMatch = false;
        });
        _refreshPatternCombatAnimationOverlay();
        _completeDeferredPatternExitIfNeeded();
        if (_sceneController.hasPendingVictoryRewards &&
            !_sceneController.isPresentingRewards) {
          unawaited(_handleOpenPendingRewards());
        }
      }
    }
  }

  void _completeDeferredPatternExitIfNeeded() {
    final exitResult = _deferredPatternExitResult;
    if (exitResult == null) return;

    _deferredPatternExitResult = null;
    _completeBattleExit(exitResult);
  }

  void _refreshPatternCombatAnimationOverlay() {
    _refreshPatternVisualBattlers();
    if (!_isPresentingPatternMatch) {
      _patternCombatAnimationOverlay.value = null;
      return;
    }

    final layers = <Widget>[
      if (_activeCombatIconMotion != null)
        Positioned.fill(
          child: _BattleCombatIconAnimationLayer(
            animation: _attackFlightController,
            motion: _activeCombatIconMotion!,
          ),
        ),
      if (_activeStatusEffectBurst != null)
        Positioned.fill(
          child: _BattleStatusEffectAnimationLayer(
            burst: _activeStatusEffectBurst!,
          ),
        ),
      if (_activeFloatingNumberBurst != null)
        Positioned.fill(
          child: _BattleFloatingNumberAnimationLayer(
            burst: _activeFloatingNumberBurst!,
          ),
        ),
      if (_activeMoneyBurst != null)
        Positioned.fill(
          child: _BattleMoneyAnimationLayer(
            burst: _activeMoneyBurst!,
          ),
        ),
      if (_activeFragilidadBurst != null)
        Positioned.fill(
          child: _BattleFragilidadBurstAnimationLayer(
            burst: _activeFragilidadBurst!,
          ),
        ),
    ];

    _patternCombatAnimationOverlay.value = layers.isEmpty
        ? null
        : IgnorePointer(
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: layers,
            ),
          );
  }

  void _refreshPatternVisualBattlers() {
    final next = BattlePatternVisualBattlers(
      player: _displayPlayerOverride ?? _sceneController.player,
      enemy: _displayEnemyOverride ?? _sceneController.enemy,
    );
    final current = _patternVisualBattlers.value;
    if (identical(current.player, next.player) &&
        identical(current.enemy, next.enemy)) {
      return;
    }

    _patternVisualBattlers.value = next;
  }

  Future<bool> _presentPlayerPatternTurn() async {
    final patternLayout = OperativePatternLayoutService.resolveForPlayer(
      player: _sceneController.player,
    );
    if (!identical(patternLayout.player, _sceneController.player)) {
      _sceneController.replacePlayer(patternLayout.player);
    }
    final pendingEnemyBlockAction = _planEnemyBlockActionForPlayerBoard();
    final availableBlockingPoints =
        OperativePatternCombatRules.maxBlockingPointsFor(
      _sceneController.player,
    );
    final availableEnemyBlockingPoints = max(
      0,
      OperativePatternCombatRules.maxBlockingPointsFor(
            _sceneController.enemy,
          ) -
          _sceneController.player.removedWallBlockingPointDebt,
    );
    var didResolveTurn = false;
    final matchResult = await showEndpointOverlay<BattlePatternMatchResult>(
      context: context,
      barrierDismissible: false,
      barrierColor: EndpointPalette.overlayScrimStrong,
      transitionDuration: Duration.zero,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: BattlePatternMatchOverlay(
          player: _sceneController.player,
          enemy: _sceneController.enemy,
          equippedItemsByPointKey: patternLayout.itemsByPointKey,
          wallSegments: _sceneController.player.combatWallSegments,
          blockedPointKeys: _sceneController.player.combatBlockedPointKeys,
          pendingEnemyBlockAction: pendingEnemyBlockAction,
          enemyTier: widget.enemyTier,
          combatRound: _sceneController.currentRound,
          availableBlockingPoints: availableBlockingPoints,
          enemyBlockingPoints: availableEnemyBlockingPoints,
          enemyBanksBlockingPoints: false,
          actionEffects:
              _sceneController.playerActionIntentPreview.attackEffects,
          itemPointUseCounts: _patternItemPointUseCounts,
          previousYellowBlockMode: _previousYellowPatternBlockMode,
          randomNextInt: _sceneController.randomizer.nextInt,
          combatAnimationOverlay: _patternCombatAnimationOverlay,
          visualBattlers: _patternVisualBattlers,
          onAnimationTargetsChanged: _handlePatternAnimationTargetsChanged,
          onPlayerAbilityPressed: (ability) => _handleOpenAbilityDetails(
            ability,
            canControlOwner: true,
          ),
          onEnemyAbilityPressed: (ability) => _handleOpenAbilityDetails(
            ability,
            canControlOwner: false,
          ),
          onResolve: (matchResult) async {
            if (didResolveTurn) return;
            didResolveTurn = true;
            _sceneController.replacePlayer(
              _sceneController.player.copyWith(
                combatWallSegments: matchResult.playerWallSegments,
                combatBlockedPointKeys: matchResult.playerBlockedPointKeys,
              ),
            );
            _recordPatternMatchResult(matchResult);
            await _sceneController.handlePlayerPatternMatch(
              actionBonus: BattleActionBonus(
                attackBonus: matchResult.attackBonus,
                healAmount: matchResult.healthBonus,
                immediateBarrierAmount: matchResult.barrierBonus,
              ),
              patternContext: matchResult.patternContext,
              scheduleEnemyTurn: false,
            );
          },
        ),
      ),
    );
    return mounted && (didResolveTurn || matchResult != null);
  }

  void _recordPatternMatchResult(BattlePatternMatchResult result) {
    _previousYellowPatternBlockMode = result.blockMode;
    if (result.activatedItemPointKeys.isEmpty) return;

    final updatedUseCounts = Map<String, int>.from(_patternItemPointUseCounts);
    for (final pointKey in result.activatedItemPointKeys) {
      updatedUseCounts[pointKey] = (updatedUseCounts[pointKey] ?? 0) + 1;
    }
    _patternItemPointUseCounts = Map<String, int>.unmodifiable(
      updatedUseCounts,
    );
  }

  Future<bool> _handleEnemyPatternMatchFlow() async {
    final patternLayout = OperativePatternLayoutService.resolveForPlayer(
      player: _sceneController.enemy,
    );
    if (!identical(patternLayout.player, _sceneController.enemy)) {
      _sceneController.replaceEnemy(patternLayout.player);
    }
    final playerWallCapacity = max(
      0,
      OperativePatternCombatRules.maxBlockingPointsFor(
            _sceneController.player,
          ) -
          _sceneController.enemy.removedWallBlockingPointDebt,
    );
    final enemyOverchargesPattern =
        playerWallCapacity > 0 && _sceneController.randomizer.nextInt(2) == 0;
    var didResolveTurn = false;
    final matchResult =
        await showEndpointOverlay<EnemyBattlePatternMatchResult>(
      context: context,
      barrierDismissible: false,
      barrierColor: EndpointPalette.overlayScrimStrong,
      transitionDuration: Duration.zero,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: EnemyBattlePatternMatchOverlay(
          player: _sceneController.player,
          enemy: _sceneController.enemy,
          equippedItemsByPointKey: patternLayout.itemsByPointKey,
          wallSegments: _sceneController.enemy.combatWallSegments,
          blockedPointKeys: _sceneController.enemy.combatBlockedPointKeys,
          maxBlockingPoints: playerWallCapacity,
          maxWallActions:
              OperativePatternCombatRules.wallActionsPerBlockingTurnFor(
            _sceneController.player,
          ),
          enemyOverchargesPattern: enemyOverchargesPattern,
          combatRound: _sceneController.currentRound,
          randomNextInt: _sceneController.randomizer.nextInt,
          combatAnimationOverlay: _patternCombatAnimationOverlay,
          visualBattlers: _patternVisualBattlers,
          onAnimationTargetsChanged: _handlePatternAnimationTargetsChanged,
          onPlayerAbilityPressed: (ability) => _handleOpenAbilityDetails(
            ability,
            canControlOwner: true,
          ),
          onEnemyAbilityPressed: (ability) => _handleOpenAbilityDetails(
            ability,
            canControlOwner: false,
          ),
          onResolve: (matchResult) async {
            if (didResolveTurn) return;
            didResolveTurn = true;
            _sceneController.replaceEnemy(
              _sceneController.enemy.copyWith(
                combatWallSegments: matchResult.wallSegments,
                combatBlockedPointKeys: matchResult.blockedPointKeys,
              ),
            );
            await _sceneController.handleEnemyPatternMatch(
              actionBonus: BattleActionBonus(
                attackBonus: matchResult.attackBonus,
                healAmount: matchResult.healthBonus,
                immediateBarrierAmount: matchResult.barrierBonus,
              ),
              patternContext: matchResult.patternContext,
            );
          },
        ),
      ),
    );
    return mounted && (didResolveTurn || matchResult != null);
  }

  BattlePatternEnemyBlockAction? _planEnemyBlockActionForPlayerBoard() {
    final capacity = max(
      0,
      OperativePatternCombatRules.maxBlockingPointsFor(
            _sceneController.enemy,
          ) -
          _sceneController.player.removedWallBlockingPointDebt,
    );
    if (capacity <= 0) return null;

    final currentWalls = _sceneController.player.combatWallSegments;
    final currentBlockedPointKeys =
        _sceneController.player.combatBlockedPointKeys;
    final usedBlockingPoints =
        (currentWalls.length *
                OperativePatternCombatRules.wallBlockingPointCost) +
            (currentBlockedPointKeys.length *
                OperativePatternCombatRules.pointBlockingPointCost);
    final remainingBlockingPoints = capacity - usedBlockingPoints;
    if (remainingBlockingPoints <= 0) return null;

    if (remainingBlockingPoints >=
        OperativePatternCombatRules.wallBlockingPointCost) {
      final wall = _randomWallCandidate(currentWalls: currentWalls);
      if (wall != null) {
        return BattlePatternEnemyBlockAction.wall(wall);
      }
    }

    if (remainingBlockingPoints >=
        OperativePatternCombatRules.pointBlockingPointCost) {
      final point = _randomPointBlockCandidate(
        currentBlockedPointKeys: currentBlockedPointKeys,
      );
      if (point != null) {
        return BattlePatternEnemyBlockAction.point(point);
      }
    }

    return null;
  }

  OperativePatternWallSegment? _randomWallCandidate({
    required List<OperativePatternWallSegment> currentWalls,
  }) {
    final candidates = _allPatternWallCandidates();
    if (candidates.isEmpty) return null;

    final currentKeys = currentWalls.map((wall) => wall.key).toSet();
    final available = candidates
        .where((wall) => !currentKeys.contains(wall.key))
        .toList(growable: false);
    if (available.isEmpty) return null;

    return available[_sceneController.randomizer.nextInt(
      available.length,
    )];
  }

  OperativePatternPoint? _randomPointBlockCandidate({
    required Set<String> currentBlockedPointKeys,
  }) {
    final available = operativePatternPoints
        .where((point) => !currentBlockedPointKeys.contains(point.key))
        .toList(growable: false);
    if (available.isEmpty) return null;

    return available[_sceneController.randomizer.nextInt(
      available.length,
    )];
  }

  List<OperativePatternWallSegment> _allPatternWallCandidates() {
    final candidates = <OperativePatternWallSegment>[];
    for (final point in operativePatternPoints) {
      for (final delta in const [
        (x: 1, y: 0),
        (x: 0, y: 1),
      ]) {
        final neighbor = operativePatternPointAt(
          x: point.x + delta.x,
          y: point.y + delta.y,
        );
        if (neighbor == null) continue;
        candidates.add(OperativePatternWallSegment(a: point, b: neighbor));
      }
    }
    return List<OperativePatternWallSegment>.unmodifiable(candidates);
  }

  void _handlePatternAnimationTargetsChanged(
    BattlePatternAnimationTargets? targets,
  ) {
    _patternAnimationTargets = targets;
  }

  Future<void> _handlePlayerBlockFlow() async {
    if (!_sceneController.canUseActions ||
        _sceneController.hasPendingVictoryRewards ||
        _isPlayingBattleAnimation) {
      return;
    }

    await _sceneController.handlePlayerBlock();
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
      case BattleCombatAnimationHook.burnDamage:
      case BattleCombatAnimationHook.poisonDamage:
        await _playStatusEffectCue(cue);
        break;
      case BattleCombatAnimationHook.damageTaken:
      case BattleCombatAnimationHook.healthLoss:
      case BattleCombatAnimationHook.healthGain:
      case BattleCombatAnimationHook.barrierGain:
      case BattleCombatAnimationHook.barrierLoss:
        await _playCombatStatCue(cue);
        break;
      case BattleCombatAnimationHook.moneyChange:
        await _playMoneyCue(cue);
        break;
      case BattleCombatAnimationHook.purgeDamage:
        await _playPurgeDamageCue(cue);
        break;
      case BattleCombatAnimationHook.fragilidadBurst:
        await _playFragilidadBurstCue(cue);
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
      _activeMoneyBurst = null;
      _isPlayingBattleAnimation = false;
    });
    _refreshPatternCombatAnimationOverlay();
  }

  Future<void> _playCombatMotionCue(BattleCombatAnimationCue cue) async {
    final start = _centerForSide(cue.primarySide);
    final end = _motionEndForCue(cue);
    if (end == null) return;

    final effectCount = max(1, cue.effectCount);
    final totalDuration = cue.hook == BattleCombatAnimationHook.attackMotion
        ? _battleAttackFlightDuration +
            _battleAttackFollowUpStagger * (effectCount - 1)
        : _battleAttackFlightDuration;
    final assetPath = _assetPathForMotionCue(cue);
    _attackFlightController.duration = totalDuration;
    setState(() {
      _isPlayingBattleAnimation = true;
      _releaseDisplayOverrideOnNextSceneChange = false;
      _displayPlayerOverride = cue.playerBefore;
      _displayEnemyOverride = cue.enemyBefore;
      _animatedHealthSides = const {};
      _animatedBarrierSides = const {};
      _activeStatusEffectBurst = null;
      _activeFloatingNumberBurst = null;
      _activeMoneyBurst = null;
      _activeFragilidadBurst = null;
      _activeCombatIconMotion = _BattleCombatIconMotion(
        hook: cue.hook,
        start: start,
        end: end,
        primarySide: cue.primarySide,
        assetPath: assetPath,
        effectCount: effectCount,
        totalDuration: totalDuration,
      );
    });
    _refreshPatternCombatAnimationOverlay();

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
    _refreshPatternCombatAnimationOverlay();
  }

  String _assetPathForMotionCue(BattleCombatAnimationCue cue) {
    if (cue.hook == BattleCombatAnimationHook.blockMotion) {
      return _battleShieldAssetPath;
    }

    switch (cue.motionAsset) {
      case BattleCombatMotionAsset.fist:
        return _battleFistAssetPath;
      case BattleCombatMotionAsset.shield:
        return _battleShieldAssetPath;
      case BattleCombatMotionAsset.sword:
        return _battleSwordAssetPath;
    }
  }

  Future<void> _playStatusEffectCue(BattleCombatAnimationCue cue) async {
    if (cue.effectCount <= 0) return;

    final burst = _buildStatusEffectBurst(cue);
    setState(() {
      _isPlayingBattleAnimation = true;
      _releaseDisplayOverrideOnNextSceneChange = false;
      _displayPlayerOverride = cue.playerBefore;
      _displayEnemyOverride = cue.enemyBefore;
      _animatedHealthSides = const {};
      _animatedBarrierSides = const {};
      _activeCombatIconMotion = null;
      _activeFloatingNumberBurst = null;
      _activeMoneyBurst = null;
      _activeFragilidadBurst = null;
      _activeStatusEffectBurst = burst;
    });
    _refreshPatternCombatAnimationOverlay();

    await Future<void>.delayed(_battleStatusEffectBurstDuration);
    if (!mounted) return;

    setState(() {
      if (_activeStatusEffectBurst?.id == burst.id) {
        _activeStatusEffectBurst = null;
      }
      _isPlayingBattleAnimation = false;
    });
    _refreshPatternCombatAnimationOverlay();
  }

  Future<void> _clearFloatingNumberBurstAfterDelay(
    _BattleFloatingNumberBurst burst,
  ) async {
    await Future<void>.delayed(_battleFloatingNumberDuration);
    if (!mounted || _activeFloatingNumberBurst?.id != burst.id) return;

    setState(() {
      _activeFloatingNumberBurst = null;
    });
    _refreshPatternCombatAnimationOverlay();
  }

  _BattleStatusEffectBurst _buildStatusEffectBurst(
    BattleCombatAnimationCue cue,
  ) {
    final sideRect = _rectForSide(cue.primarySide);
    final isBurn = cue.hook == BattleCombatAnimationHook.burnDamage;
    const poisonStatus = IntoxicacionStatus();
    final count = max(1, cue.effectCount);
    final particles = List<_BattleStatusEffectParticle>.generate(
      count,
      (_) => _buildStatusEffectParticle(sideRect),
      growable: false,
    );

    return _BattleStatusEffectBurst(
      id: ++_statusEffectBurstSequence,
      rises: isBurn,
      symbol: isBurn ? '\u{1F525}' : null,
      icon: isBurn ? null : poisonStatus.icon,
      accent: isBurn ? const Color(0xFFFF9B3D) : poisonStatus.type.foreground,
      particles: List<_BattleStatusEffectParticle>.unmodifiable(particles),
    );
  }

  _BattleStatusEffectParticle _buildStatusEffectParticle(Rect sideRect) {
    final random = _statusEffectVisualRandom;
    final horizontalInset = min(44.0, sideRect.width * 0.18);
    final verticalInset = min(36.0, sideRect.height * 0.18);
    final usableWidth = max(1.0, sideRect.width - horizontalInset * 2);
    final usableHeight = max(1.0, sideRect.height - verticalInset * 2);

    return _BattleStatusEffectParticle(
      start: Offset(
        sideRect.left + horizontalInset + random.nextDouble() * usableWidth,
        sideRect.top + verticalInset + random.nextDouble() * usableHeight,
      ),
      drift: (random.nextDouble() * 2 - 1) * 26,
      travelDistance: 34 + random.nextDouble() * 22,
      delay: random.nextDouble() * 0.16,
      scale: 0.82 + random.nextDouble() * 0.36,
    );
  }

  Future<void> _playMoneyCue(BattleCombatAnimationCue cue) async {
    final moneyBurst = _buildMoneyBurst(cue);
    if (moneyBurst == null) return;

    setState(() {
      _isPlayingBattleAnimation = true;
      _releaseDisplayOverrideOnNextSceneChange = false;
      _displayPlayerOverride = cue.playerBefore;
      _displayEnemyOverride = cue.enemyBefore;
      _animatedHealthSides = const {};
      _animatedBarrierSides = const {};
      _activeStatusEffectBurst = null;
      _activeCombatIconMotion = null;
      _activeFloatingNumberBurst = null;
      _activeFragilidadBurst = null;
      _activeMoneyBurst = moneyBurst;
    });
    _refreshPatternCombatAnimationOverlay();

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    setState(() {
      _displayPlayerOverride = cue.playerAfter;
      _displayEnemyOverride = cue.enemyAfter;
    });
    _refreshPatternCombatAnimationOverlay();

    await Future<void>.delayed(_battleFloatingNumberDuration);
    if (!mounted) return;

    setState(() {
      if (_activeMoneyBurst?.id == moneyBurst.id) {
        _activeMoneyBurst = null;
      }
      _isPlayingBattleAnimation = false;
    });
    _releaseDisplayOverrideOnNextSceneChange = true;
    _refreshPatternCombatAnimationOverlay();
  }

  _BattleMoneyBurst? _buildMoneyBurst(BattleCombatAnimationCue cue) {
    final before = cue.primarySide == BattleCombatantSide.player
        ? cue.playerBefore
        : cue.enemyBefore;
    final after = cue.primarySide == BattleCombatantSide.player
        ? cue.playerAfter
        : cue.enemyAfter;
    final delta = after.money - before.money;
    BattleCombatFloatingNumberCue? moneyCue;
    for (final floatingNumber in cue.floatingNumbers) {
      if (floatingNumber.tone == BattleCombatFloatingNumberTone.moneyGain ||
          floatingNumber.tone == BattleCombatFloatingNumberTone.moneyLoss) {
        moneyCue = floatingNumber;
        break;
      }
    }
    final amount = moneyCue?.amount ?? delta.abs();
    if (amount <= 0) return null;

    return _BattleMoneyBurst(
      id: ++_moneyBurstSequence,
      iconRect: _rectForBattlerIcon(cue.primarySide),
      amount: amount,
      isGain: moneyCue?.tone == BattleCombatFloatingNumberTone.moneyGain ||
          (moneyCue == null && delta > 0),
    );
  }

  Offset? _motionEndForCue(BattleCombatAnimationCue cue) {
    if (cue.hook == BattleCombatAnimationHook.blockMotion) {
      return _centerOfBattleArea();
    }

    final secondarySide = cue.secondarySide;
    if (secondarySide == null) return null;

    return _centerForStatusBar(secondarySide);
  }

  Future<void> _playCombatStatCue(BattleCombatAnimationCue cue) async {
    final animatedSide = cue.primarySide;
    final animatesHealth = cue.hook == BattleCombatAnimationHook.damageTaken ||
        cue.hook == BattleCombatAnimationHook.healthLoss ||
        cue.hook == BattleCombatAnimationHook.healthGain;
    final animatesBarrier = cue.hook == BattleCombatAnimationHook.damageTaken ||
        cue.hook == BattleCombatAnimationHook.barrierLoss ||
        cue.hook == BattleCombatAnimationHook.barrierGain;
    final floatingNumberBurst = _buildFloatingNumberBurst(cue);

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
      _activeStatusEffectBurst = null;
      _activeCombatIconMotion = null;
      _activeMoneyBurst = null;
      _activeFragilidadBurst = null;
      _activeFloatingNumberBurst = floatingNumberBurst;
    });
    _refreshPatternCombatAnimationOverlay();
    if (floatingNumberBurst != null) {
      unawaited(_clearFloatingNumberBurstAfterDelay(floatingNumberBurst));
    }

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
    _refreshPatternCombatAnimationOverlay();

    await Future<void>.delayed(_battleImpactBarDuration);
    if (!mounted) return;
    _releaseDisplayOverrideOnNextSceneChange = true;
    _refreshPatternCombatAnimationOverlay();
  }

  Future<void> _playPurgeDamageCue(BattleCombatAnimationCue cue) async {
    final floatingNumberBurst = _buildFloatingNumberBurst(cue);
    final healthSides = <BattleCombatantSide>{
      if (cue.playerAfter.health < cue.playerBefore.health)
        BattleCombatantSide.player,
      if (cue.enemyAfter.health < cue.enemyBefore.health)
        BattleCombatantSide.enemy,
    };
    final barrierSides = <BattleCombatantSide>{
      if (cue.playerAfter.currentBarrier < cue.playerBefore.currentBarrier)
        BattleCombatantSide.player,
      if (cue.enemyAfter.currentBarrier < cue.enemyBefore.currentBarrier)
        BattleCombatantSide.enemy,
    };

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
      _activeStatusEffectBurst = null;
      _activeCombatIconMotion = null;
      _activeMoneyBurst = null;
      _activeFragilidadBurst = null;
      _activeFloatingNumberBurst = floatingNumberBurst;
    });
    _refreshPatternCombatAnimationOverlay();
    if (floatingNumberBurst != null) {
      unawaited(_clearFloatingNumberBurstAfterDelay(floatingNumberBurst));
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    setState(() {
      _displayPlayerOverride = cue.playerAfter;
      _displayEnemyOverride = cue.enemyAfter;
      _animatedHealthSides = healthSides;
      _animatedBarrierSides = barrierSides;
    });
    _refreshPatternCombatAnimationOverlay();

    await Future<void>.delayed(_battleImpactBarDuration);
    if (!mounted) return;
    _releaseDisplayOverrideOnNextSceneChange = true;
    _refreshPatternCombatAnimationOverlay();
  }

  Future<void> _playFragilidadBurstCue(BattleCombatAnimationCue cue) async {
    final floatingNumberBurst = _buildFloatingNumberBurst(cue);
    final fragilidadBurst = _BattleFragilidadBurst(
      id: ++_fragilidadBurstSequence,
      center: _centerForSide(cue.primarySide),
    );

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
      _activeStatusEffectBurst = null;
      _activeCombatIconMotion = null;
      _activeMoneyBurst = null;
      _activeFloatingNumberBurst = floatingNumberBurst;
      _activeFragilidadBurst = fragilidadBurst;
    });
    _refreshPatternCombatAnimationOverlay();
    if (floatingNumberBurst != null) {
      unawaited(_clearFloatingNumberBurstAfterDelay(floatingNumberBurst));
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    setState(() {
      _displayPlayerOverride = cue.playerAfter;
      _displayEnemyOverride = cue.enemyAfter;
      _animatedHealthSides = <BattleCombatantSide>{cue.primarySide};
      _animatedBarrierSides = const <BattleCombatantSide>{};
    });
    _refreshPatternCombatAnimationOverlay();

    await Future<void>.delayed(_battleFragilidadBurstDuration);
    if (!mounted) return;
    setState(() {
      if (_activeFragilidadBurst?.id == fragilidadBurst.id) {
        _activeFragilidadBurst = null;
      }
    });
    _releaseDisplayOverrideOnNextSceneChange = true;
    _refreshPatternCombatAnimationOverlay();
  }

  _BattleFloatingNumberBurst? _buildFloatingNumberBurst(
    BattleCombatAnimationCue cue,
  ) {
    if (cue.floatingNumbersBySide.isNotEmpty) {
      return _buildFloatingNumberBurstBySide(cue);
    }

    final floatingNumbers = cue.floatingNumbers.isNotEmpty
        ? cue.floatingNumbers
        : _fallbackFloatingNumbersForCue(cue);
    if (floatingNumbers.isEmpty) return null;

    final statusBarRect = _rectForStatusBar(cue.primarySide);
    final center = statusBarRect.center;
    const spacing = 50.0;
    final particles = <_BattleFloatingNumberParticle>[];

    for (var index = 0; index < floatingNumbers.length; index++) {
      final floatingNumber = floatingNumbers[index];
      final centeredIndex = index - (floatingNumbers.length - 1) / 2;
      particles.add(
        _BattleFloatingNumberParticle(
          label: _floatingNumberLabelFor(floatingNumber),
          color: _floatingNumberColorFor(floatingNumber.tone),
          start: Offset(
            center.dx + centeredIndex * spacing,
            center.dy + statusBarRect.height * 0.08,
          ),
          delay: index * 0.04,
        ),
      );
    }

    return _BattleFloatingNumberBurst(
      id: ++_floatingNumberBurstSequence,
      particles: List<_BattleFloatingNumberParticle>.unmodifiable(particles),
    );
  }

  _BattleFloatingNumberBurst? _buildFloatingNumberBurstBySide(
    BattleCombatAnimationCue cue,
  ) {
    const spacing = 50.0;
    final particles = <_BattleFloatingNumberParticle>[];

    for (final entry in cue.floatingNumbersBySide.entries) {
      final floatingNumbers = entry.value;
      if (floatingNumbers.isEmpty) continue;
      final statusBarRect = _rectForStatusBar(entry.key);
      final center = statusBarRect.center;
      for (var index = 0; index < floatingNumbers.length; index++) {
        final floatingNumber = floatingNumbers[index];
        final centeredIndex = index - (floatingNumbers.length - 1) / 2;
        particles.add(
          _BattleFloatingNumberParticle(
            label: _floatingNumberLabelFor(floatingNumber),
            color: _floatingNumberColorFor(floatingNumber.tone),
            start: Offset(
              center.dx + centeredIndex * spacing,
              center.dy + statusBarRect.height * 0.08,
            ),
            delay: index * 0.04,
          ),
        );
      }
    }

    if (particles.isEmpty) return null;
    return _BattleFloatingNumberBurst(
      id: ++_floatingNumberBurstSequence,
      particles: List<_BattleFloatingNumberParticle>.unmodifiable(particles),
    );
  }

  List<BattleCombatFloatingNumberCue> _fallbackFloatingNumbersForCue(
    BattleCombatAnimationCue cue,
  ) {
    final before = cue.primarySide == BattleCombatantSide.player
        ? cue.playerBefore
        : cue.enemyBefore;
    final after = cue.primarySide == BattleCombatantSide.player
        ? cue.playerAfter
        : cue.enemyAfter;
    final healthLoss = max(0, before.health - after.health);
    final barrierLoss = max(0, before.currentBarrier - after.currentBarrier);
    final healthGain = max(0, after.health - before.health);
    final barrierGain = max(0, after.currentBarrier - before.currentBarrier);

    return List<BattleCombatFloatingNumberCue>.unmodifiable([
      if (healthLoss > 0)
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.healthDamage,
          amount: healthLoss,
        ),
      if (barrierLoss > 0)
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.barrierDamage,
          amount: barrierLoss,
        ),
      if (healthGain > 0)
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.healing,
          amount: healthGain,
        ),
      if (barrierGain > 0)
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.barrierGain,
          amount: barrierGain,
        ),
    ]);
  }

  String _floatingNumberLabelFor(BattleCombatFloatingNumberCue floatingNumber) {
    final prefix = switch (floatingNumber.tone) {
      BattleCombatFloatingNumberTone.healing ||
      BattleCombatFloatingNumberTone.barrierGain =>
        '+',
      BattleCombatFloatingNumberTone.healthDamage ||
      BattleCombatFloatingNumberTone.barrierDamage ||
      BattleCombatFloatingNumberTone.burnDamage ||
      BattleCombatFloatingNumberTone.poisonDamage ||
      BattleCombatFloatingNumberTone.fragilidadDamage ||
      BattleCombatFloatingNumberTone.moneyLoss ||
      BattleCombatFloatingNumberTone.purgeDamage =>
        '',
      BattleCombatFloatingNumberTone.moneyGain => '+',
    };

    final suffix = switch (floatingNumber.tone) {
      BattleCombatFloatingNumberTone.moneyGain ||
      BattleCombatFloatingNumberTone.moneyLoss =>
        'C',
      _ => '',
    };

    return '$prefix${floatingNumber.amount}$suffix';
  }

  Color _floatingNumberColorFor(BattleCombatFloatingNumberTone tone) {
    return switch (tone) {
      BattleCombatFloatingNumberTone.healthDamage =>
        EndpointPalette.dangerAccent,
      BattleCombatFloatingNumberTone.barrierDamage ||
      BattleCombatFloatingNumberTone.barrierGain =>
        BattlerStat.barrier.accent,
      BattleCombatFloatingNumberTone.burnDamage => const Color(0xFFFF9B3D),
      BattleCombatFloatingNumberTone.poisonDamage => const Color(0xFFC084FC),
      BattleCombatFloatingNumberTone.fragilidadDamage =>
        const FragilidadStatus().type.accent,
      BattleCombatFloatingNumberTone.moneyGain => const Color(0xFFFFD76A),
      BattleCombatFloatingNumberTone.moneyLoss => EndpointPalette.dangerAccent,
      BattleCombatFloatingNumberTone.purgeDamage => const Color(0xFFFFEA70),
      BattleCombatFloatingNumberTone.healing => const Color(0xFF8DFFB2),
    };
  }

  int? _barrierAnimationReferenceFor(Battler before, Battler after) {
    final reference = max(
      max(before.currentBarrier, before.maxBarrier),
      max(after.currentBarrier, after.maxBarrier),
    );
    return reference > 0 ? reference : null;
  }

  Offset _centerForSide(BattleCombatantSide side) {
    final patternTargets = _patternAnimationTargets;
    if (_isPresentingPatternMatch && patternTargets != null) {
      return switch (side) {
        BattleCombatantSide.player => patternTargets.playerSpriteRect.center,
        BattleCombatantSide.enemy => patternTargets.enemySpriteRect.center,
      };
    }

    final key =
        side == BattleCombatantSide.player ? _playerSideKey : _enemySideKey;
    return _centerOfKey(key) ?? _fallbackCenterForSide(side);
  }

  Offset _centerForStatusBar(BattleCombatantSide side) {
    final patternTargets = _patternAnimationTargets;
    if (_isPresentingPatternMatch && patternTargets != null) {
      return switch (side) {
        BattleCombatantSide.player => patternTargets.playerStatusRect.center,
        BattleCombatantSide.enemy => patternTargets.enemyStatusRect.center,
      };
    }

    final key = side == BattleCombatantSide.player
        ? _playerStatusBarKey
        : _enemyStatusBarKey;
    return _centerOfKey(key) ?? _fallbackCenterForSide(side);
  }

  Rect _rectForStatusBar(BattleCombatantSide side) {
    final patternTargets = _patternAnimationTargets;
    if (_isPresentingPatternMatch && patternTargets != null) {
      return switch (side) {
        BattleCombatantSide.player => patternTargets.playerStatusRect,
        BattleCombatantSide.enemy => patternTargets.enemyStatusRect,
      };
    }

    final key = side == BattleCombatantSide.player
        ? _playerStatusBarKey
        : _enemyStatusBarKey;
    return _rectOfKey(key) ??
        Rect.fromCenter(
          center: _fallbackCenterForSide(side),
          width: 300,
          height: 48,
        );
  }

  Rect _rectForSide(BattleCombatantSide side) {
    final patternTargets = _patternAnimationTargets;
    if (_isPresentingPatternMatch && patternTargets != null) {
      final spriteRect = switch (side) {
        BattleCombatantSide.player => patternTargets.playerSpriteRect,
        BattleCombatantSide.enemy => patternTargets.enemySpriteRect,
      };
      return spriteRect.inflate(14);
    }

    final key =
        side == BattleCombatantSide.player ? _playerSideKey : _enemySideKey;
    return _rectOfKey(key) ?? _fallbackRectForSide(side);
  }

  Rect _rectForBattlerIcon(BattleCombatantSide side) {
    final patternTargets = _patternAnimationTargets;
    if (_isPresentingPatternMatch && patternTargets != null) {
      return switch (side) {
        BattleCombatantSide.player => patternTargets.playerSpriteRect,
        BattleCombatantSide.enemy => patternTargets.enemySpriteRect,
      };
    }

    final sideRect = _rectForSide(side);
    final size = min(112.0, min(sideRect.width * 0.36, sideRect.height * 0.72));
    final center = Offset(
      sideRect.center.dx,
      sideRect.center.dy + (side == BattleCombatantSide.player ? -8 : 8),
    );
    return Rect.fromCenter(
      center: center,
      width: max(72.0, size),
      height: max(72.0, size),
    );
  }

  Offset _centerOfBattleArea() {
    final rootBox = _battleAnimationRootKey.currentContext?.findRenderObject();
    final size = rootBox is RenderBox && rootBox.hasSize
        ? rootBox.size
        : MediaQuery.sizeOf(context);

    return size.center(Offset.zero);
  }

  Rect? _rectOfKey(GlobalKey key) {
    final rootBox = _battleAnimationRootKey.currentContext?.findRenderObject();
    final targetBox = key.currentContext?.findRenderObject();
    if (rootBox is! RenderBox ||
        targetBox is! RenderBox ||
        !rootBox.hasSize ||
        !targetBox.hasSize) {
      return null;
    }

    final targetTopLeft = targetBox.localToGlobal(Offset.zero);
    return rootBox.globalToLocal(targetTopLeft) & targetBox.size;
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

  Rect _fallbackRectForSide(BattleCombatantSide side) {
    final rootBox = _battleAnimationRootKey.currentContext?.findRenderObject();
    final size = rootBox is RenderBox && rootBox.hasSize
        ? rootBox.size
        : MediaQuery.sizeOf(context);
    final halfHeight = size.height * 0.5;
    final top = side == BattleCombatantSide.enemy ? 0.0 : halfHeight;

    return Rect.fromLTWH(0, top, size.width, halfHeight);
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
          price: item.sellValue,
          priceLabel: 'VENTA',
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
      barrierLabel: 'Detalle de aumento',
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
                  ? 'Desactivar aumento manual'
                  : 'Activar aumento manual',
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
      displayPlayerOverride: _displayPlayerOverride,
      displayEnemyOverride: _displayEnemyOverride,
      isPatternMode: _isPatternMode,
      isPresentingPatternMatch: _isPresentingPatternMatch,
      isPlayingBattleAnimation: _isPlayingBattleAnimation,
      battleAnimationRootKey: _battleAnimationRootKey,
      playerSideKey: _playerSideKey,
      enemySideKey: _enemySideKey,
      playerStatusBarKey: _playerStatusBarKey,
      enemyStatusBarKey: _enemyStatusBarKey,
      attackFlightAnimation: _attackFlightController,
      activeCombatIconMotion: _activeCombatIconMotion,
      activeStatusEffectBurst: _activeStatusEffectBurst,
      activeFloatingNumberBurst: _activeFloatingNumberBurst,
      activeMoneyBurst: _activeMoneyBurst,
      activeFragilidadBurst: _activeFragilidadBurst,
      playerBarrierAnimationReference: _playerBarrierAnimationReference,
      enemyBarrierAnimationReference: _enemyBarrierAnimationReference,
      animatedHealthSides: _animatedHealthSides,
      animatedBarrierSides: _animatedBarrierSides,
      onAttack: _handlePlayerAttack,
      onBlock: _handlePlayerBlock,
      canOpenPreviewOperatives: _canOpenPreviewOperatives,
      onOpenPreviewOperatives: _handleOpenPreviewOperatives,
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
