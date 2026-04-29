part of 'battle_page.dart';

typedef _OpenBattleItemDetailsCallback = Future<void> Function(Item item);
typedef _OpenBattleAbilityDetailsCallback = Future<void> Function(
  BattlerAbility ability,
);

EndpointSectionPreset _buildBattlePanelPreset(
  Color accent, {
  double borderRadius = 10,
  double glowOpacity = 0,
  double blurRadius = 16,
  double spreadRadius = 1,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(6, 4, 6, 4),
}) {
  return EndpointSectionPreset(
    accent: accent,
    foreground: EndpointPalette.softForeground,
    mutedForeground: EndpointPalette.softForeground.withAlpha(214),
    backgroundColor: EndpointPalette.panelBackgroundBattle,
    padding: padding,
    borderRadius: borderRadius,
    glowOpacity: glowOpacity,
    blurRadius: blurRadius,
    spreadRadius: spreadRadius,
  );
}

class _BattleSceneView extends StatelessWidget {
  final String showTitle;
  final BattleSceneController sceneController;
  final Battler displayPlayer;
  final Battler displayEnemy;
  final bool isDrawingMode;
  final bool isPresentingDrawAttack;
  final bool isPresentingDrawDefense;
  final bool isPlayingBattleAnimation;
  final GlobalKey battleAnimationRootKey;
  final GlobalKey playerSideKey;
  final GlobalKey enemySideKey;
  final GlobalKey playerStatusBarKey;
  final GlobalKey enemyStatusBarKey;
  final Animation<double> attackFlightAnimation;
  final _BattleCombatIconMotion? activeCombatIconMotion;
  final _BattleStatusEffectBurst? activeStatusEffectBurst;
  final _BattleFloatingNumberBurst? activeFloatingNumberBurst;
  final int? playerBarrierAnimationReference;
  final int? enemyBarrierAnimationReference;
  final Set<BattleCombatantSide> animatedHealthSides;
  final Set<BattleCombatantSide> animatedBarrierSides;
  final VoidCallback onAttack;
  final VoidCallback onBlock;
  final Future<void> Function() onAdvancePressed;
  final _OpenBattleItemDetailsCallback onOpenPlayerItemDetails;
  final _OpenBattleItemDetailsCallback onOpenEnemyItemDetails;
  final _OpenBattleAbilityDetailsCallback onOpenPlayerAbilityDetails;
  final _OpenBattleAbilityDetailsCallback onOpenEnemyAbilityDetails;

  const _BattleSceneView({
    required this.showTitle,
    required this.sceneController,
    required this.displayPlayer,
    required this.displayEnemy,
    required this.isDrawingMode,
    required this.isPresentingDrawAttack,
    required this.isPresentingDrawDefense,
    required this.isPlayingBattleAnimation,
    required this.battleAnimationRootKey,
    required this.playerSideKey,
    required this.enemySideKey,
    required this.playerStatusBarKey,
    required this.enemyStatusBarKey,
    required this.attackFlightAnimation,
    required this.activeCombatIconMotion,
    required this.activeStatusEffectBurst,
    required this.activeFloatingNumberBurst,
    required this.playerBarrierAnimationReference,
    required this.enemyBarrierAnimationReference,
    required this.animatedHealthSides,
    required this.animatedBarrierSides,
    required this.onAttack,
    required this.onBlock,
    required this.onAdvancePressed,
    required this.onOpenPlayerItemDetails,
    required this.onOpenEnemyItemDetails,
    required this.onOpenPlayerAbilityDetails,
    required this.onOpenEnemyAbilityDetails,
  });

  @override
  Widget build(BuildContext context) {
    final battleController = sceneController.battleController;
    final sceneListenable = Listenable.merge([
      battleController,
      sceneController,
    ]);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: NodeSceneWrapper(
          showTitle: showTitle,
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: EndpointGradients.battle),
            child: SafeArea(
              child: AnimatedBuilder(
                animation: sceneListenable,
                builder: (context, _) {
                  const enemyAccent = EndpointPalette.dangerAccent;
                  const playerAccent = EndpointPalette.primaryAccent;
                  final enemyBackground = [
                    EndpointPalette.blend(
                      EndpointPalette.panelBackgroundBattle,
                      enemyAccent,
                      0.42,
                    ),
                    EndpointPalette.blend(
                      EndpointPalette.scaffoldBackground,
                      enemyAccent,
                      0.12,
                    ),
                  ];
                  final playerBackground = [
                    EndpointPalette.blend(
                      EndpointPalette.panelBackground,
                      playerAccent,
                      0.1,
                    ),
                    EndpointPalette.blend(
                      EndpointPalette.scaffoldBackground,
                      playerAccent,
                      0.04,
                    ),
                  ];
                  final playerActionsEnabled = sceneController.canUseActions &&
                      !isPresentingDrawAttack &&
                      !isPresentingDrawDefense &&
                      !isPlayingBattleAnimation;
                  final playerHealthAnimationDuration =
                      animatedHealthSides.contains(BattleCombatantSide.player)
                          ? _battleImpactBarDuration
                          : Duration.zero;
                  final enemyHealthAnimationDuration =
                      animatedHealthSides.contains(BattleCombatantSide.enemy)
                          ? _battleImpactBarDuration
                          : Duration.zero;
                  final playerBarrierAnimationDuration =
                      animatedBarrierSides.contains(BattleCombatantSide.player)
                          ? _battleImpactBarDuration
                          : Duration.zero;
                  final enemyBarrierAnimationDuration =
                      animatedBarrierSides.contains(BattleCombatantSide.enemy)
                          ? _battleImpactBarDuration
                          : Duration.zero;

                  return Stack(
                    key: battleAnimationRootKey,
                    fit: StackFit.expand,
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: _BattleSide(
                              key: enemySideKey,
                              title: 'THREAT',
                              subtitle: 'Enemy',
                              accent: enemyAccent,
                              background: enemyBackground,
                              child: SizedBox.expand(
                                child: _EnemyBattleHud(
                                  enemy: displayEnemy,
                                  enemyIntent:
                                      sceneController.enemyTurnIntentPreview,
                                  visibleAbilities:
                                      sceneController.visibleAbilitiesFor(
                                    displayEnemy,
                                  ),
                                  statusBarKey: enemyStatusBarKey,
                                  healthAnimationDuration:
                                      enemyHealthAnimationDuration,
                                  barrierAnimationDuration:
                                      enemyBarrierAnimationDuration,
                                  barrierAnimationReference:
                                      enemyBarrierAnimationReference,
                                  onOpenEquippedItemDetails:
                                      onOpenEnemyItemDetails,
                                  onOpenAbilityDetails:
                                      onOpenEnemyAbilityDetails,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            height: 2,
                            color: playerAccent.withAlpha(51),
                          ),
                          Expanded(
                            child: _BattleSide(
                              key: playerSideKey,
                              title: 'OPERATIVE',
                              subtitle: 'Player',
                              accent: playerAccent,
                              background: playerBackground,
                              child: SizedBox.expand(
                                child: _PlayerBattleHud(
                                  player: displayPlayer,
                                  visibleAbilities:
                                      sceneController.visibleAbilitiesFor(
                                    displayPlayer,
                                  ),
                                  isEnabled: playerActionsEnabled,
                                  isDrawingMode: isDrawingMode,
                                  onAttack: onAttack,
                                  onBlock: onBlock,
                                  blockBarrierGain:
                                      sceneController.playerBlockBarrierGain,
                                  onQuickActivateAbility:
                                      sceneController.quickActivateAbility,
                                  canQuickActivateAbility:
                                      sceneController.canQuickActivateAbility,
                                  onOpenEquippedItemDetails:
                                      onOpenPlayerItemDetails,
                                  onOpenAbilityDetails:
                                      onOpenPlayerAbilityDetails,
                                  statusBarKey: playerStatusBarKey,
                                  healthAnimationDuration:
                                      playerHealthAnimationDuration,
                                  barrierAnimationDuration:
                                      playerBarrierAnimationDuration,
                                  barrierAnimationReference:
                                      playerBarrierAnimationReference,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: _BattleCenterOverlay(
                          title: sceneController.turnTitle,
                          description: sceneController.turnDescription,
                          round: sceneController.currentRound,
                          isEnemyTurn:
                              sceneController.turn == BattleTurnState.enemy,
                          isCombatFinished: sceneController.isCombatFinished,
                          onAdvancePressed:
                              sceneController.hasPendingVictoryRewards &&
                                      !isPlayingBattleAnimation
                                  ? onAdvancePressed
                                  : null,
                        ),
                      ),
                      if (activeCombatIconMotion != null)
                        Positioned.fill(
                          child: _BattleCombatIconAnimationLayer(
                            animation: attackFlightAnimation,
                            motion: activeCombatIconMotion!,
                          ),
                        ),
                      if (activeStatusEffectBurst != null)
                        Positioned.fill(
                          child: _BattleStatusEffectAnimationLayer(
                            burst: activeStatusEffectBurst!,
                          ),
                        ),
                      if (activeFloatingNumberBurst != null)
                        Positioned.fill(
                          child: _BattleFloatingNumberAnimationLayer(
                            burst: activeFloatingNumberBurst!,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleSide extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final List<Color> background;
  final Widget child;

  const _BattleSide({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.background,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: background,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: CustomPaint(
                painter: _BattleSideGridPainter(accent),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EndpointSceneHeader(
                  title: title.toUpperCase(),
                  description: subtitle,
                  foreground: accent,
                  descriptionColor:
                      EndpointPalette.softForeground.withAlpha(184),
                  titleStyle: textTitleSmallBold.copyWith(
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                  descriptionStyle: textSmallBold.copyWith(
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                  spacing: 2,
                ),
                const SizedBox(height: 4),
                Expanded(child: child),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleFloatingNumberAnimationLayer extends StatelessWidget {
  final _BattleFloatingNumberBurst burst;

  const _BattleFloatingNumberAnimationLayer({
    required this.burst,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(burst.id),
      tween: Tween<double>(begin: 0, end: 1),
      duration: _battleFloatingNumberDuration,
      curve: Curves.linear,
      builder: (context, progress, _) {
        return IgnorePointer(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final particle in burst.particles)
                _BattleFloatingNumberParticleView(
                  particle: particle,
                  progress: progress,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BattleFloatingNumberParticleView extends StatelessWidget {
  final _BattleFloatingNumberParticle particle;
  final double progress;

  const _BattleFloatingNumberParticleView({
    required this.particle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final localProgress = ((progress - particle.delay) / (1 - particle.delay))
        .clamp(0.0, 1.0)
        .toDouble();
    if (localProgress <= 0) {
      return const SizedBox.shrink();
    }

    final rise = Curves.easeOutCubic.transform(localProgress) * -18;
    final popScale = 0.82 + 0.24 * Curves.easeOutBack.transform(localProgress);
    final opacity = _opacityForFloatingNumberProgress(localProgress);

    return Positioned(
      left: particle.start.dx - 36,
      top: particle.start.dy - 16,
      width: 72,
      height: 32,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, rise),
          child: Transform.scale(
            scale: popScale,
            child: _BattleOutlinedFloatingNumberText(
              label: particle.label,
              color: particle.color,
            ),
          ),
        ),
      ),
    );
  }

  double _opacityForFloatingNumberProgress(double progress) {
    if (progress < 0.12) {
      return (progress / 0.12).clamp(0.0, 1.0).toDouble();
    }
    if (progress > 0.72) {
      return ((1 - progress) / 0.28).clamp(0.0, 1.0).toDouble();
    }

    return 1;
  }
}

class _BattleOutlinedFloatingNumberText extends StatelessWidget {
  final String label;
  final Color color;

  const _BattleOutlinedFloatingNumberText({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = textTitleSmallBold.copyWith(
      fontSize: 18,
      letterSpacing: 0.8,
      height: 1,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.2
              ..color = Colors.black.withAlpha(230),
            shadows: [
              Shadow(
                color: Colors.black.withAlpha(204),
                blurRadius: 5,
              ),
            ],
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: baseStyle.copyWith(
            color: color,
            shadows: [
              Shadow(
                color: color.withAlpha(112),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BattleStatusEffectAnimationLayer extends StatelessWidget {
  final _BattleStatusEffectBurst burst;

  const _BattleStatusEffectAnimationLayer({
    required this.burst,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(burst.id),
      tween: Tween<double>(begin: 0, end: 1),
      duration: _battleStatusEffectBurstDuration,
      curve: Curves.linear,
      builder: (context, progress, _) {
        return IgnorePointer(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final particle in burst.particles)
                _BattleStatusEffectParticleView(
                  burst: burst,
                  particle: particle,
                  progress: progress,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BattleStatusEffectParticleView extends StatelessWidget {
  final _BattleStatusEffectBurst burst;
  final _BattleStatusEffectParticle particle;
  final double progress;

  const _BattleStatusEffectParticleView({
    required this.burst,
    required this.particle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final localProgress = ((progress - particle.delay) / (1 - particle.delay))
        .clamp(0.0, 1.0)
        .toDouble();
    if (localProgress <= 0) {
      return const SizedBox.shrink();
    }

    final travelProgress = Curves.easeOutCubic.transform(
      ((localProgress - 0.22) / 0.78).clamp(0.0, 1.0).toDouble(),
    );
    final floatProgress = Curves.easeInOutSine.transform(
      (localProgress / 0.32).clamp(0.0, 1.0).toDouble(),
    );
    final direction = burst.rises ? -1.0 : 1.0;
    final offset = Offset(
      particle.drift * Curves.easeInOutCubic.transform(localProgress),
      direction * particle.travelDistance * travelProgress +
          sin(floatProgress * pi * 2) * 5 * (1 - travelProgress),
    );
    final opacity = _opacityForStatusEffectProgress(localProgress);
    final size = _battleSwordAnimationSize * 0.62 * particle.scale;

    return Positioned(
      left: particle.start.dx - size / 2,
      top: particle.start.dy - size / 2,
      width: size,
      height: size,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: offset,
          child: Transform.scale(
            scale: 0.88 + 0.16 * Curves.easeOutBack.transform(localProgress),
            child: _BattleStatusEffectGlyph(
              burst: burst,
              size: size,
            ),
          ),
        ),
      ),
    );
  }

  double _opacityForStatusEffectProgress(double progress) {
    if (progress < 0.14) {
      return (progress / 0.14).clamp(0.0, 1.0).toDouble();
    }
    if (progress > 0.68) {
      return ((1 - progress) / 0.32).clamp(0.0, 1.0).toDouble();
    }

    return 1;
  }
}

class _BattleStatusEffectGlyph extends StatelessWidget {
  final _BattleStatusEffectBurst burst;
  final double size;

  const _BattleStatusEffectGlyph({
    required this.burst,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = burst.symbol;
    if (symbol != null) {
      return Text(
        symbol,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size,
          height: 1,
          shadows: [
            Shadow(
              color: burst.accent.withAlpha(179),
              blurRadius: 10,
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: EndpointPalette.panelBackgroundBattleOpaque.withAlpha(210),
        boxShadow: [
          BoxShadow(
            color: burst.accent.withAlpha(112),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        burst.icon,
        color: burst.accent,
        size: size * 0.72,
      ),
    );
  }
}

class _BattleCombatIconAnimationLayer extends StatelessWidget {
  static final Animatable<double> _attackProgress = TweenSequence<double>(
    [
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 0.42).chain(
          CurveTween(curve: Curves.easeInOutCubic),
        ),
        weight: _battleAttackSlowLaunchDuration.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.42, end: 1).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: _battleAttackFastImpactDuration.inMilliseconds.toDouble(),
      ),
    ],
  );
  static final Animatable<double> _blockProgress = TweenSequence<double>(
    [
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: Curves.easeInOutCubic),
        ),
        weight: _battleAttackSlowLaunchDuration.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: _battleAttackFastImpactDuration.inMilliseconds.toDouble(),
      ),
    ],
  );

  final Animation<double> animation;
  final _BattleCombatIconMotion motion;

  const _BattleCombatIconAnimationLayer({
    required this.animation,
    required this.motion,
  });

  @override
  Widget build(BuildContext context) {
    final accent = motion.primarySide == BattleCombatantSide.player
        ? EndpointPalette.primaryAccent
        : EndpointPalette.dangerAccent;
    final delta = motion.end - motion.start;
    final angle = motion.hook == BattleCombatAnimationHook.blockMotion
        ? 0.0
        : atan2(delta.dy, delta.dx) + pi / 4;
    const swordSize = _battleSwordAnimationSize;
    final progressTween = motion.hook == BattleCombatAnimationHook.blockMotion
        ? _blockProgress
        : _attackProgress;
    final totalMs = max(1, motion.totalDuration.inMilliseconds);
    final flightMs = max(1, _battleAttackFlightDuration.inMilliseconds);
    final staggerMs = _battleAttackFollowUpStagger.inMilliseconds;
    final effectCount = max(1, motion.effectCount);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return IgnorePointer(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < effectCount; index++)
                Builder(
                  builder: (context) {
                    final elapsedMs = animation.value * totalMs;
                    final localElapsedMs = elapsedMs - index * staggerMs;
                    if (localElapsedMs < 0 || localElapsedMs > flightMs) {
                      return const SizedBox.shrink();
                    }

                    final localProgress =
                        (localElapsedMs / flightMs).clamp(0.0, 1.0).toDouble();
                    final progress = progressTween.transform(localProgress);
                    final position =
                        Offset.lerp(motion.start, motion.end, progress)!;
                    final impactGlow = Curves.easeIn.transform(progress);

                    return Positioned(
                      left: position.dx - swordSize / 2,
                      top: position.dy - swordSize / 2,
                      width: swordSize,
                      height: swordSize,
                      child: Transform.rotate(
                        angle: angle,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withAlpha(
                                  (64 + 64 * impactGlow).round(),
                                ),
                                blurRadius: 10 + 8 * impactGlow,
                                spreadRadius: 0.5 + 1.5 * impactGlow,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            motion.assetPath,
                            width: swordSize,
                            height: swordSize,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TurnBanner extends StatelessWidget {
  final String title;
  final String description;
  final bool isEnemyTurn;
  final bool isCombatFinished;

  const _TurnBanner({
    required this.title,
    required this.description,
    required this.isEnemyTurn,
    required this.isCombatFinished,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isCombatFinished
        ? EndpointPalette.rewardAccent
        : isEnemyTurn
            ? EndpointPalette.dangerAccent
            : EndpointPalette.primaryAccent;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: EndpointSectionPanel(
        preset: _buildBattlePanelPreset(
          accent,
          glowOpacity: 0.04,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        ),
        child: EndpointSceneHeader(
          title: title,
          description: description,
          foreground: accent,
          descriptionColor: EndpointPalette.softForeground.withAlpha(214),
          titleStyle: textTitleSmallBold.copyWith(
            fontSize: 12,
            letterSpacing: 1.5,
          ),
          descriptionStyle: textSmallBold.copyWith(
            fontSize: 11,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BattleCenterOverlay extends StatelessWidget {
  final String title;
  final String description;
  final int round;
  final bool isEnemyTurn;
  final bool isCombatFinished;
  final Future<void> Function()? onAdvancePressed;

  const _BattleCenterOverlay({
    required this.title,
    required this.description,
    required this.round,
    required this.isEnemyTurn,
    required this.isCombatFinished,
    this.onAdvancePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _TurnBanner(
          title: title,
          description: description,
          isEnemyTurn: isEnemyTurn,
          isCombatFinished: isCombatFinished,
        ),
        const SizedBox(width: 6),
        _RoundCounterBadge(round: round),
        if (onAdvancePressed != null) ...[
          const SizedBox(width: 6),
          EndpointActionButton(
            label: '-->',
            onPressed: onAdvancePressed,
            tooltip: 'Abrir botin del combate',
            accent: EndpointPalette.rewardAccent,
            backgroundColor: EndpointPalette.panelBackgroundBattle,
            foregroundColor: EndpointPalette.softForegroundWarm,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            textStyle: textMediumBold.copyWith(
              fontSize: 13,
              letterSpacing: 1.1,
            ),
            useMarquee: false,
          ),
        ],
      ],
    );
  }
}

class _RoundCounterBadge extends StatelessWidget {
  final int round;

  const _RoundCounterBadge({
    required this.round,
  });

  @override
  Widget build(BuildContext context) {
    final dangerBlend = ((round - 5) / 5).clamp(0.0, 1.0).toDouble();
    final roundColor = EndpointPalette.blend(
      EndpointPalette.softForeground,
      EndpointPalette.dangerAccent,
      dangerBlend,
    );

    return SizedBox(
      width: 62,
      child: EndpointSectionPanel(
        preset: _buildBattlePanelPreset(
          roundColor,
          glowOpacity: 0.04,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EndpointText(
              'ROUND',
              style: textSmallBold.copyWith(
                color: EndpointPalette.softForeground.withAlpha(194),
                fontSize: 9,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            EndpointText(
              '$round',
              style: textTitleSmallBold.copyWith(
                color: roundColor,
                fontSize: 16,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleSideGridPainter extends CustomPainter {
  final Color accent;

  const _BattleSideGridPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = accent.withAlpha(20)
      ..strokeWidth = 1;

    for (double y = 16; y <= size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    for (double x = 12; x <= size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BattleSideGridPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
