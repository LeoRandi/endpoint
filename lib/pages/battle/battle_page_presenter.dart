part of 'battle_page.dart';

class _BattleAnimationSnapshot {
  final _BattleCombatIconMotion? activeCombatIconMotion;
  final List<_BattleCombatIconMotion> activeCombatIconMotions;
  final _BattleStatusEffectBurst? activeStatusEffectBurst;
  final List<_BattleStatusEffectBurst> activeStatusEffectBursts;
  final _BattleFloatingNumberBurst? activeFloatingNumberBurst;
  final _BattleMoneyBurst? activeMoneyBurst;
  final _BattleFragilidadBurst? activeFragilidadBurst;
  final Battler? displayPlayerOverride;
  final Battler? displayEnemyOverride;
  final int? playerBarrierAnimationReference;
  final int? enemyBarrierAnimationReference;
  final Set<BattleCombatantSide> animatedHealthSides;
  final Set<BattleCombatantSide> animatedBarrierSides;
  final bool isPlayingBattleAnimation;
  final bool releaseDisplayOverrideOnNextSceneChange;

  const _BattleAnimationSnapshot({
    this.activeCombatIconMotion,
    this.activeCombatIconMotions = const <_BattleCombatIconMotion>[],
    this.activeStatusEffectBurst,
    this.activeStatusEffectBursts = const <_BattleStatusEffectBurst>[],
    this.activeFloatingNumberBurst,
    this.activeMoneyBurst,
    this.activeFragilidadBurst,
    this.displayPlayerOverride,
    this.displayEnemyOverride,
    this.playerBarrierAnimationReference,
    this.enemyBarrierAnimationReference,
    this.animatedHealthSides = const <BattleCombatantSide>{},
    this.animatedBarrierSides = const <BattleCombatantSide>{},
    this.isPlayingBattleAnimation = false,
    this.releaseDisplayOverrideOnNextSceneChange = false,
  });

  _BattleAnimationSnapshot copyWith({
    _BattleCombatIconMotion? activeCombatIconMotion,
    List<_BattleCombatIconMotion>? activeCombatIconMotions,
    bool clearActiveCombatIconMotion = false,
    _BattleStatusEffectBurst? activeStatusEffectBurst,
    List<_BattleStatusEffectBurst>? activeStatusEffectBursts,
    bool clearActiveStatusEffectBurst = false,
    _BattleFloatingNumberBurst? activeFloatingNumberBurst,
    bool clearActiveFloatingNumberBurst = false,
    _BattleMoneyBurst? activeMoneyBurst,
    bool clearActiveMoneyBurst = false,
    _BattleFragilidadBurst? activeFragilidadBurst,
    bool clearActiveFragilidadBurst = false,
    Battler? displayPlayerOverride,
    bool clearDisplayPlayerOverride = false,
    Battler? displayEnemyOverride,
    bool clearDisplayEnemyOverride = false,
    int? playerBarrierAnimationReference,
    bool clearPlayerBarrierAnimationReference = false,
    int? enemyBarrierAnimationReference,
    bool clearEnemyBarrierAnimationReference = false,
    Set<BattleCombatantSide>? animatedHealthSides,
    Set<BattleCombatantSide>? animatedBarrierSides,
    bool? isPlayingBattleAnimation,
    bool? releaseDisplayOverrideOnNextSceneChange,
  }) {
    return _BattleAnimationSnapshot(
      activeCombatIconMotion: clearActiveCombatIconMotion
          ? null
          : activeCombatIconMotion ?? this.activeCombatIconMotion,
      activeCombatIconMotions: clearActiveCombatIconMotion
          ? const <_BattleCombatIconMotion>[]
          : activeCombatIconMotions ?? this.activeCombatIconMotions,
      activeStatusEffectBurst: clearActiveStatusEffectBurst
          ? null
          : activeStatusEffectBurst ?? this.activeStatusEffectBurst,
      activeStatusEffectBursts: clearActiveStatusEffectBurst
          ? const <_BattleStatusEffectBurst>[]
          : activeStatusEffectBursts ?? this.activeStatusEffectBursts,
      activeFloatingNumberBurst: clearActiveFloatingNumberBurst
          ? null
          : activeFloatingNumberBurst ?? this.activeFloatingNumberBurst,
      activeMoneyBurst: clearActiveMoneyBurst
          ? null
          : activeMoneyBurst ?? this.activeMoneyBurst,
      activeFragilidadBurst: clearActiveFragilidadBurst
          ? null
          : activeFragilidadBurst ?? this.activeFragilidadBurst,
      displayPlayerOverride: clearDisplayPlayerOverride
          ? null
          : displayPlayerOverride ?? this.displayPlayerOverride,
      displayEnemyOverride: clearDisplayEnemyOverride
          ? null
          : displayEnemyOverride ?? this.displayEnemyOverride,
      playerBarrierAnimationReference: clearPlayerBarrierAnimationReference
          ? null
          : playerBarrierAnimationReference ??
              this.playerBarrierAnimationReference,
      enemyBarrierAnimationReference: clearEnemyBarrierAnimationReference
          ? null
          : enemyBarrierAnimationReference ??
              this.enemyBarrierAnimationReference,
      animatedHealthSides: animatedHealthSides ?? this.animatedHealthSides,
      animatedBarrierSides: animatedBarrierSides ?? this.animatedBarrierSides,
      isPlayingBattleAnimation:
          isPlayingBattleAnimation ?? this.isPlayingBattleAnimation,
      releaseDisplayOverrideOnNextSceneChange:
          releaseDisplayOverrideOnNextSceneChange ??
              this.releaseDisplayOverrideOnNextSceneChange,
    );
  }
}

class _BattleAnimationPresenter extends ChangeNotifier {
  _BattleAnimationSnapshot _snapshot = const _BattleAnimationSnapshot();

  _BattleAnimationSnapshot get snapshot => _snapshot;

  void resetReleasedDisplayState() {
    _setSnapshot(
      _snapshot.copyWith(
        clearDisplayPlayerOverride: true,
        clearDisplayEnemyOverride: true,
        clearActiveCombatIconMotion: true,
        clearActiveStatusEffectBurst: true,
        clearActiveMoneyBurst: true,
        clearActiveFragilidadBurst: true,
        clearPlayerBarrierAnimationReference: true,
        clearEnemyBarrierAnimationReference: true,
        animatedHealthSides: const <BattleCombatantSide>{},
        animatedBarrierSides: const <BattleCombatantSide>{},
        isPlayingBattleAnimation: false,
        releaseDisplayOverrideOnNextSceneChange: false,
      ),
    );
  }

  void clearInitialCombatPresentation() {
    _setSnapshot(
      _snapshot.copyWith(
        clearDisplayPlayerOverride: true,
        clearDisplayEnemyOverride: true,
        animatedHealthSides: const <BattleCombatantSide>{},
        animatedBarrierSides: const <BattleCombatantSide>{},
        clearActiveMoneyBurst: true,
        isPlayingBattleAnimation: false,
        releaseDisplayOverrideOnNextSceneChange: false,
      ),
    );
  }

  void startMotion({
    required BattleCombatAnimationCue cue,
    required _BattleCombatIconMotion motion,
  }) {
    _setSnapshot(
      _baseCueSnapshot(cue).copyWith(
        activeCombatIconMotion: motion,
      ),
    );
  }

  void startMotions({
    required BattleCombatAnimationCue cue,
    required List<_BattleCombatIconMotion> motions,
  }) {
    _setSnapshot(
      _baseCueSnapshot(cue).copyWith(
        activeCombatIconMotions:
            List<_BattleCombatIconMotion>.unmodifiable(motions),
      ),
    );
  }

  void finishMotion() {
    _setSnapshot(
      _snapshot.copyWith(
        clearActiveCombatIconMotion: true,
        isPlayingBattleAnimation: false,
      ),
    );
  }

  void startStatusEffect({
    required BattleCombatAnimationCue cue,
    required _BattleStatusEffectBurst burst,
  }) {
    _setSnapshot(
      _baseCueSnapshot(cue).copyWith(
        activeStatusEffectBurst: burst,
      ),
    );
  }

  void startStatusEffects({
    required BattleCombatAnimationCue cue,
    required List<_BattleStatusEffectBurst> bursts,
  }) {
    _setSnapshot(
      _baseCueSnapshot(cue).copyWith(
        activeStatusEffectBursts:
            List<_BattleStatusEffectBurst>.unmodifiable(bursts),
      ),
    );
  }

  void clearStatusEffectIfCurrent(_BattleStatusEffectBurst burst) {
    if (_snapshot.activeStatusEffectBurst?.id != burst.id) return;

    _setSnapshot(
      _snapshot.copyWith(
        clearActiveStatusEffectBurst: true,
        isPlayingBattleAnimation: false,
      ),
    );
  }

  void clearStatusEffects() {
    _setSnapshot(
      _snapshot.copyWith(
        clearActiveStatusEffectBurst: true,
        isPlayingBattleAnimation: false,
      ),
    );
  }

  void clearFloatingNumberIfCurrent(_BattleFloatingNumberBurst burst) {
    if (_snapshot.activeFloatingNumberBurst?.id != burst.id) return;

    _setSnapshot(_snapshot.copyWith(clearActiveFloatingNumberBurst: true));
  }

  void startMoney({
    required BattleCombatAnimationCue cue,
    required _BattleMoneyBurst burst,
  }) {
    _setSnapshot(
      _baseCueSnapshot(cue).copyWith(
        activeMoneyBurst: burst,
      ),
    );
  }

  void revealCueAfter(BattleCombatAnimationCue cue) {
    _setSnapshot(
      _snapshot.copyWith(
        displayPlayerOverride: cue.playerAfter,
        displayEnemyOverride: cue.enemyAfter,
      ),
    );
  }

  void finishMoneyIfCurrent(_BattleMoneyBurst burst) {
    _setSnapshot(
      _snapshot.copyWith(
        clearActiveMoneyBurst: _snapshot.activeMoneyBurst?.id == burst.id,
        isPlayingBattleAnimation: false,
        releaseDisplayOverrideOnNextSceneChange: true,
      ),
    );
  }

  void startStatChange({
    required BattleCombatAnimationCue cue,
    required _BattleFloatingNumberBurst? floatingNumberBurst,
    required int? playerBarrierReference,
    required int? enemyBarrierReference,
  }) {
    _setSnapshot(
      _baseCueSnapshot(cue).copyWith(
        playerBarrierAnimationReference: playerBarrierReference,
        enemyBarrierAnimationReference: enemyBarrierReference,
        activeFloatingNumberBurst: floatingNumberBurst,
      ),
    );
  }

  void revealStatChange({
    required BattleCombatAnimationCue cue,
    required Set<BattleCombatantSide> healthSides,
    required Set<BattleCombatantSide> barrierSides,
  }) {
    _setSnapshot(
      _snapshot.copyWith(
        displayPlayerOverride: cue.playerAfter,
        displayEnemyOverride: cue.enemyAfter,
        animatedHealthSides: healthSides,
        animatedBarrierSides: barrierSides,
      ),
    );
  }

  void deferReleaseAfterStatChange() {
    _setSnapshot(
      _snapshot.copyWith(releaseDisplayOverrideOnNextSceneChange: true),
    );
  }

  void startFragilidad({
    required BattleCombatAnimationCue cue,
    required _BattleFloatingNumberBurst? floatingNumberBurst,
    required _BattleFragilidadBurst fragilidadBurst,
    required int? playerBarrierReference,
    required int? enemyBarrierReference,
  }) {
    _setSnapshot(
      _baseCueSnapshot(cue).copyWith(
        playerBarrierAnimationReference: playerBarrierReference,
        enemyBarrierAnimationReference: enemyBarrierReference,
        activeFloatingNumberBurst: floatingNumberBurst,
        activeFragilidadBurst: fragilidadBurst,
      ),
    );
  }

  void clearFragilidadIfCurrent(_BattleFragilidadBurst burst) {
    if (_snapshot.activeFragilidadBurst?.id != burst.id) return;

    _setSnapshot(_snapshot.copyWith(clearActiveFragilidadBurst: true));
  }

  _BattleAnimationSnapshot _baseCueSnapshot(BattleCombatAnimationCue cue) {
    return _snapshot.copyWith(
      isPlayingBattleAnimation: true,
      releaseDisplayOverrideOnNextSceneChange: false,
      displayPlayerOverride: cue.playerBefore,
      displayEnemyOverride: cue.enemyBefore,
      animatedHealthSides: const <BattleCombatantSide>{},
      animatedBarrierSides: const <BattleCombatantSide>{},
      clearActiveCombatIconMotion: true,
      clearActiveStatusEffectBurst: true,
      clearActiveFloatingNumberBurst: true,
      clearActiveMoneyBurst: true,
      clearActiveFragilidadBurst: true,
    );
  }

  void _setSnapshot(_BattleAnimationSnapshot snapshot) {
    _snapshot = snapshot;
    notifyListeners();
  }
}
