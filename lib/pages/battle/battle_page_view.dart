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
  final bool isDrawingMode;
  final bool isPresentingDrawAttack;
  final bool isPresentingDrawDefense;
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
    required this.isDrawingMode,
    required this.isPresentingDrawAttack,
    required this.isPresentingDrawDefense,
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
                      !isPresentingDrawDefense;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: _BattleSide(
                              title: 'THREAT',
                              subtitle: 'Enemy',
                              accent: enemyAccent,
                              background: enemyBackground,
                              child: SizedBox.expand(
                                child: _EnemyBattleHud(
                                  enemy: sceneController.enemy,
                                  enemyIntent:
                                      sceneController.enemyTurnIntentPreview,
                                  visibleAbilities:
                                      sceneController.visibleAbilitiesFor(
                                    sceneController.enemy,
                                  ),
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
                              title: 'OPERATIVE',
                              subtitle: 'Player',
                              accent: playerAccent,
                              background: playerBackground,
                              child: SizedBox.expand(
                                child: _PlayerBattleHud(
                                  player: sceneController.player,
                                  visibleAbilities:
                                      sceneController.visibleAbilitiesFor(
                                    sceneController.player,
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
                              sceneController.hasPendingVictoryRewards
                                  ? onAdvancePressed
                                  : null,
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
