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
const _battleSwordAssetPath = 'assets/images/icons/icon_sword.png';
const _battleShieldAssetPath = 'assets/images/icons/icon_shield.png';
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
  int _statusEffectBurstSequence = 0;
  int _floatingNumberBurstSequence = 0;

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
        _activeStatusEffectBurst = null;
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
    final start = _centerForSide(cue.primarySide);
    final end = _motionEndForCue(cue);
    if (end == null) return;

    final effectCount = max(1, cue.effectCount);
    final totalDuration = cue.hook == BattleCombatAnimationHook.attackMotion
        ? _battleAttackFlightDuration +
            _battleAttackFollowUpStagger * (effectCount - 1)
        : _battleAttackFlightDuration;
    final assetPath = cue.hook == BattleCombatAnimationHook.blockMotion
        ? _battleShieldAssetPath
        : _battleSwordAssetPath;
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
      _activeStatusEffectBurst = burst;
    });

    await Future<void>.delayed(_battleStatusEffectBurstDuration);
    if (!mounted) return;

    setState(() {
      if (_activeStatusEffectBurst?.id == burst.id) {
        _activeStatusEffectBurst = null;
      }
      _isPlayingBattleAnimation = false;
    });
  }

  Future<void> _clearFloatingNumberBurstAfterDelay(
    _BattleFloatingNumberBurst burst,
  ) async {
    await Future<void>.delayed(_battleFloatingNumberDuration);
    if (!mounted || _activeFloatingNumberBurst?.id != burst.id) return;

    setState(() {
      _activeFloatingNumberBurst = null;
    });
  }

  _BattleStatusEffectBurst _buildStatusEffectBurst(
    BattleCombatAnimationCue cue,
  ) {
    final sideRect = _rectForSide(cue.primarySide);
    final isBurn = cue.hook == BattleCombatAnimationHook.burnDamage;
    final poisonStatus = const IntoxicacionStatus();
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
      _activeFloatingNumberBurst = floatingNumberBurst;
    });
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

    await Future<void>.delayed(_battleImpactBarDuration);
    if (!mounted) return;
    _releaseDisplayOverrideOnNextSceneChange = true;
  }

  _BattleFloatingNumberBurst? _buildFloatingNumberBurst(
    BattleCombatAnimationCue cue,
  ) {
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
      BattleCombatFloatingNumberTone.poisonDamage =>
        '',
    };

    return '$prefix${floatingNumber.amount}';
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

  Rect _rectForStatusBar(BattleCombatantSide side) {
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
    final key =
        side == BattleCombatantSide.player ? _playerSideKey : _enemySideKey;
    return _rectOfKey(key) ?? _fallbackRectForSide(side);
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
      activeStatusEffectBurst: _activeStatusEffectBurst,
      activeFloatingNumberBurst: _activeFloatingNumberBurst,
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
