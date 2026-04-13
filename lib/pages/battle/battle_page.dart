import '../_imports.dart';

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

class BattlePage extends StatefulWidget {
  final Battler enemy;
  final Battler player;
  final RunRandomizer? randomizer;
  final String showTitle;
  final int victoryMoneyFactor;
  final Duration enemyTurnDelay;
  final Duration combatEndDelay;
  final bool returnResultToCaller;

  const BattlePage({
    super.key,
    this.enemy = defaultEnemyBattler,
    this.player = defaultPlayerBattler,
    this.randomizer,
    this.showTitle = 'ENCOUNTER',
    this.victoryMoneyFactor = 0,
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

  @override
  void initState() {
    super.initState();
    _sceneController = BattleSceneController(
      enemy: widget.enemy,
      player: widget.player,
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
      final resolution =
          await showEndpointOverlay<BattleDrawingBonusResolution>(
        context: context,
        barrierDismissible: false,
        barrierColor: EndpointPalette.overlayScrimStrong,
        builder: (_) => BattleDrawAttackOverlay(
          attacker: _sceneController.player,
        ),
      );
      if (!mounted || resolution == null) return;

      _sceneController.handlePlayerAttack(
        drawingBonus: resolution.bonus,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPresentingDrawAttack = false;
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

  Future<void> _handleOpenItems() async {
    if (!_sceneController.canOpenItemsOverlay()) return;

    await showEndpointOverlay<void>(
      context: context,
      builder: (_) => BattleItemsDialog(
        player: _sceneController.player,
        items: _sceneController.player.inventoryItems,
      ),
      barrierColor: EndpointPalette.overlayScrimSoft,
    );
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
    final battleController = _sceneController.battleController;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: NodeSceneWrapper(
          showTitle: widget.showTitle,
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: EndpointGradients.battle),
            child: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: battleController,
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

                      return Column(
                        children: [
                          Expanded(
                            child: _BattleSide(
                              title: 'THREAT',
                              subtitle: 'Enemy',
                              accent: enemyAccent,
                              background: enemyBackground,
                              child: SizedBox.expand(
                                child: _EnemyBattleHud(
                                  enemy: _sceneController.enemy,
                                  visibleAbilities:
                                      _sceneController.visibleAbilitiesFor(
                                          _sceneController.enemy),
                                  onOpenEquippedItemDetails: (item) =>
                                      _handleOpenEquippedItemDetails(
                                    _sceneController.enemy,
                                    item,
                                  ),
                                  onOpenAbilityDetails: (ability) =>
                                      _handleOpenAbilityDetails(
                                    ability,
                                    canControlOwner: false,
                                  ),
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
                                  player: _sceneController.player,
                                  visibleAbilities:
                                      _sceneController.visibleAbilitiesFor(
                                          _sceneController.player),
                                  isEnabled: _sceneController.canUseActions &&
                                      !_isPresentingDrawAttack,
                                  isDrawingMode: _isDrawingMode,
                                  onAttack: _handlePlayerAttack,
                                  onOpenItems: _handleOpenItems,
                                  onQuickActivateAbility:
                                      _sceneController.quickActivateAbility,
                                  canQuickActivateAbility:
                                      _sceneController.canQuickActivateAbility,
                                  onOpenEquippedItemDetails: (item) =>
                                      _handleOpenEquippedItemDetails(
                                    _sceneController.player,
                                    item,
                                  ),
                                  onOpenAbilityDetails: (ability) =>
                                      _handleOpenAbilityDetails(
                                    ability,
                                    canControlOwner: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Center(
                    child: AnimatedBuilder(
                      animation: battleController,
                      builder: (context, _) {
                        return AnimatedBuilder(
                          animation: _sceneController,
                          builder: (context, _) {
                            return _BattleCenterOverlay(
                              title: _sceneController.turnTitle,
                              description: _sceneController.turnDescription,
                              isEnemyTurn: _sceneController.turn ==
                                  BattleTurnState.enemy,
                              isCombatFinished:
                                  _sceneController.isCombatFinished,
                              onAdvancePressed:
                                  _sceneController.hasPendingVictoryRewards
                                      ? _handleOpenPendingRewards
                                      : null,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
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
  final bool isEnemyTurn;
  final bool isCombatFinished;
  final Future<void> Function()? onAdvancePressed;

  const _BattleCenterOverlay({
    required this.title,
    required this.description,
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

class _ActionPanel extends StatelessWidget {
  final bool isEnabled;
  final bool isDrawingMode;
  final VoidCallback onAttack;
  final Future<void> Function() onOpenItems;

  const _ActionPanel({
    required this.isEnabled,
    required this.isDrawingMode,
    required this.onAttack,
    required this.onOpenItems,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BattleActionButton(
          label: 'Atacar',
          icon: Icons.flash_on_rounded,
          onPressed: isEnabled ? onAttack : null,
          tooltip:
              isDrawingMode ? 'Abrir ataque dibujado' : 'Atacar al enemigo',
        ),
        const SizedBox(width: 8),
        BattleActionButton(
          label: 'Objetos',
          icon: Icons.inventory_2_outlined,
          onPressed: isEnabled ? onOpenItems : null,
          tooltip: 'Abrir inventario de combate',
        ),
      ],
    );
  }
}

class _PlayerBattleHud extends StatelessWidget {
  final Battler player;
  final List<BattlerAbility> visibleAbilities;
  final bool isEnabled;
  final bool isDrawingMode;
  final VoidCallback onAttack;
  final Future<void> Function() onOpenItems;
  final ValueChanged<BattlerAbility> onQuickActivateAbility;
  final bool Function(BattlerAbility ability) canQuickActivateAbility;
  final Future<void> Function(Item item) onOpenEquippedItemDetails;
  final Future<void> Function(BattlerAbility ability) onOpenAbilityDetails;

  const _PlayerBattleHud({
    required this.player,
    required this.visibleAbilities,
    required this.isEnabled,
    required this.isDrawingMode,
    required this.onAttack,
    required this.onOpenItems,
    required this.onQuickActivateAbility,
    required this.canQuickActivateAbility,
    required this.onOpenEquippedItemDetails,
    required this.onOpenAbilityDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        _BattleLoadoutStrip(
          battler: player,
          abilities: visibleAbilities,
          accent: EndpointPalette.primaryAccent,
          mirrorHorizontally: false,
          onItemPressed: onOpenEquippedItemDetails,
          onAbilityPressed: onOpenAbilityDetails,
          onAbilityHoldCompleted: onQuickActivateAbility,
          canHoldActivateAbility: canQuickActivateAbility,
          enableAbilityTooltipLongPress: false,
        ),
        const SizedBox(height: 8),
        _BattleStatusBar(
          battler: player,
          accent: EndpointPalette.primaryAccent,
          factionLabel: 'ALLY',
          mirrorHorizontally: false,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ActionPanel(
              isEnabled: isEnabled,
              isDrawingMode: isDrawingMode,
              onAttack: onAttack,
              onOpenItems: onOpenItems,
            ),
            const Spacer(),
            _BattleSpriteDock(
              emoji: player.iconEmoji,
              accent: EndpointPalette.primaryAccent,
              label: 'TU',
              mirror: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _EnemyBattleHud extends StatelessWidget {
  final Battler enemy;
  final List<BattlerAbility> visibleAbilities;
  final Future<void> Function(Item item) onOpenEquippedItemDetails;
  final Future<void> Function(BattlerAbility ability) onOpenAbilityDetails;

  const _EnemyBattleHud({
    required this.enemy,
    required this.visibleAbilities,
    required this.onOpenEquippedItemDetails,
    required this.onOpenAbilityDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BattleSpriteDock(
              emoji: '\u{1F47E}',
              accent: EndpointPalette.dangerAccent,
              label: 'FOE',
            ),
            Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        _BattleStatusBar(
          battler: enemy,
          accent: EndpointPalette.dangerAccent,
          factionLabel: 'HOSTILE',
          mirrorHorizontally: true,
        ),
        const SizedBox(height: 8),
        _BattleLoadoutStrip(
          battler: enemy,
          abilities: visibleAbilities,
          accent: EndpointPalette.dangerAccent,
          mirrorHorizontally: true,
          onItemPressed: onOpenEquippedItemDetails,
          onAbilityPressed: onOpenAbilityDetails,
        ),
        const Spacer(),
      ],
    );
  }
}

class _BattleStatusBar extends StatelessWidget {
  final Battler battler;
  final Color accent;
  final String factionLabel;
  final bool mirrorHorizontally;

  const _BattleStatusBar({
    required this.battler,
    required this.accent,
    required this.factionLabel,
    required this.mirrorHorizontally,
  });

  @override
  Widget build(BuildContext context) {
    final healthFactor = battler.maxHealth <= 0
        ? 0.0
        : (battler.health / battler.maxHealth).clamp(0.0, 1.0).toDouble();

    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: EndpointSectionPanel(
          preset: _buildBattlePanelPreset(accent),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: mirrorHorizontally
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (mirrorHorizontally) ...[
                    EndpointText(
                      '${battler.health} / ${battler.maxHealth}',
                      style: textSmallNumericBold.copyWith(
                        color: Colors.white.withAlpha(214),
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: EndpointText(
                      battler.name,
                      maxLines: 1,
                      textAlign:
                          mirrorHorizontally ? TextAlign.right : TextAlign.left,
                      style: textTitleSmallBold.copyWith(
                        color: EndpointPalette.softForeground,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  EndpointText(
                    factionLabel,
                    style: textSmallBold.copyWith(
                      color: accent,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (!mirrorHorizontally) ...[
                    const SizedBox(width: 8),
                    EndpointText(
                      '${battler.health} / ${battler.maxHealth}',
                      style: textSmallNumericBold.copyWith(
                        color: Colors.white.withAlpha(214),
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              EndpointHealthBarWithStatuses(
                battler: battler,
                value: healthFactor,
                accent: accent,
                height: 10,
                badgeSize: 20,
                badgeOverlap: 6,
                badgeAlignment: mirrorHorizontally
                    ? WrapAlignment.end
                    : WrapAlignment.start,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleLoadoutStrip extends StatelessWidget {
  final Battler battler;
  final List<BattlerAbility> abilities;
  final Color accent;
  final bool mirrorHorizontally;
  final ValueChanged<Item>? onItemPressed;
  final ValueChanged<BattlerAbility>? onAbilityPressed;
  final ValueChanged<BattlerAbility>? onAbilityHoldCompleted;
  final bool Function(BattlerAbility ability)? canHoldActivateAbility;
  final bool enableAbilityTooltipLongPress;

  const _BattleLoadoutStrip({
    required this.battler,
    required this.abilities,
    required this.accent,
    required this.mirrorHorizontally,
    this.onItemPressed,
    this.onAbilityPressed,
    this.onAbilityHoldCompleted,
    this.canHoldActivateAbility,
    this.enableAbilityTooltipLongPress = true,
  });

  @override
  Widget build(BuildContext context) {
    final equipmentStrip = Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Center(
                child: EndpointEquipmentSlotsStrip(
                  battler: battler,
                  layout: EndpointEquipmentLayout.standard,
                  tileExtent: 54,
                  tileHeight: 66,
                  emojiSize: 14,
                  borderColor: accent.withAlpha(87),
                  onItemPressed: onItemPressed,
                ),
              ),
            ),
          );
        },
      ),
    );
    final abilityStrip = Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Center(
                child: EndpointAbilitySlotsStrip(
                  abilities: abilities,
                  accent: accent,
                  onAbilityPressed: onAbilityPressed,
                  onAbilityHoldCompleted: onAbilityHoldCompleted,
                  canHoldActivateAbility: canHoldActivateAbility,
                  holdDuration: const Duration(milliseconds: 500),
                  enableTooltipLongPress: enableAbilityTooltipLongPress,
                ),
              ),
            ),
          );
        },
      ),
    );
    final separator = _BattleLoadoutDivider(accent: accent);
    final children = mirrorHorizontally
        ? <Widget>[
            abilityStrip,
            const SizedBox(width: 8),
            separator,
            const SizedBox(width: 8),
            equipmentStrip,
          ]
        : <Widget>[
            equipmentStrip,
            const SizedBox(width: 8),
            separator,
            const SizedBox(width: 8),
            abilityStrip,
          ];

    return SizedBox(
      height: 66,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class _BattleLoadoutDivider extends StatelessWidget {
  final Color accent;

  const _BattleLoadoutDivider({
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 54,
      child: Center(
        child: Container(
          width: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accent.withAlpha(18),
                accent.withAlpha(184),
                accent.withAlpha(18),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withAlpha(56),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleSpriteDock extends StatelessWidget {
  final String emoji;
  final Color accent;
  final String label;
  final bool mirror;

  const _BattleSpriteDock({
    required this.emoji,
    required this.accent,
    required this.label,
    this.mirror = false,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointSectionPanel(
      preset: _buildBattlePanelPreset(
        accent,
        borderRadius: 12,
        glowOpacity: 0.06,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EndpointEmojiSprite(
            emoji: emoji,
            accent: accent,
            size: 58,
            mirror: mirror,
          ),
          const SizedBox(height: 4),
          EndpointText(
            label,
            style: textSmallBold.copyWith(
              color: EndpointPalette.softForeground,
              fontSize: 12,
              letterSpacing: 0.9,
            ),
          ),
        ],
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
