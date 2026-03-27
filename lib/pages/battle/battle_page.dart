import '../_imports.dart';

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
  final BattleRewardService _rewardService = const BattleRewardService();
  late final BattleController _controller;
  late final RunRandomizer _randomizer;
  bool _isPresentingVictoryRewards = false;
  BattleFlowResult? _pendingVictoryExitResult;
  Item? _pendingVictoryLootItem;
  int _pendingVictoryMoneyReward = 0;

  @override
  void initState() {
    super.initState();
    _randomizer = widget.randomizer ?? RunRandomizer();
    _controller = BattleController(
      enemy: widget.enemy,
      player: widget.player,
      randomizer: _randomizer,
      enemyTurnDelay: widget.enemyTurnDelay,
      combatEndDelay: widget.combatEndDelay,
    )..addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final exitResult = _controller.consumePendingExitResult();
    if (exitResult == null || !mounted) return;

    _handleBattleExit(exitResult);
  }

  Future<void> _handleBattleExit(BattleFlowResult exitResult) async {
    if (exitResult.type != BattleFlowResultType.victory) {
      _completeBattleExit(exitResult);
      return;
    }

    final rewards = _rewardService.buildVictoryRewards(
      enemy: _controller.enemy,
      player: exitResult.player,
      victoryMoneyFactor: widget.victoryMoneyFactor,
      randomizer: _randomizer,
    );
    if (!rewards.hasRewards) {
      _completeBattleExit(exitResult);
      return;
    }

    setState(() {
      _pendingVictoryExitResult = exitResult;
      _pendingVictoryLootItem = rewards.lootItem;
      _pendingVictoryMoneyReward = rewards.moneyReward;
    });
  }

  Future<BattleFlowResult> _presentVictoryRewards(
    BattleFlowResult exitResult, {
    BattleRewardBundle? rewards,
  }) async {
    final resolvedRewards = rewards ??
        _rewardService.buildVictoryRewards(
          enemy: _controller.enemy,
          player: exitResult.player,
          victoryMoneyFactor: widget.victoryMoneyFactor,
          randomizer: _randomizer,
        );
    if (!resolvedRewards.hasRewards) {
      return exitResult;
    }

    final rewardedPlayer = await showEndpointOverlay<Battler>(
      context: context,
      barrierDismissible: false,
      barrierColor: EndpointPalette.overlayScrimStrong,
      builder: (_) => BattleLootOverlay(
        player: exitResult.player,
        lootItem: resolvedRewards.lootItem,
        moneyReward: resolvedRewards.moneyReward,
        enemyName: _controller.enemy.name,
      ),
    );

    return BattleFlowResult(
      type: exitResult.type,
      player: rewardedPlayer ?? exitResult.player,
    );
  }

  void _completeBattleExit(BattleFlowResult exitResult) {
    final resolvedResult = _rewardService.sanitizeExitResult(exitResult);
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return;

    if (widget.returnResultToCaller) {
      navigator.pop(resolvedResult);
      return;
    }

    navigator.popUntil((route) => route.isFirst);
  }

  void _handlePlayerAttack() {
    _controller.handleAttack();
  }

  /// Devuelve solo las habilidades que tienen sentido dentro de la interfaz de combate.
  List<BattlerAbility> _battleVisibleAbilities(Battler battler) {
    return battler.abilities
        .where(
          (ability) =>
              ability.appearsInContext(BattlerAbilityActivationContext.battle),
        )
        .toList(growable: false);
  }

  /// Indica si una habilidad puede activarse ahora mismo desde una pulsacion mantenida.
  bool _canQuickActivateAbility(BattlerAbility ability) {
    return !ability.isActive &&
        _isAbilityActionEnabled(ability, canControlOwner: true);
  }

  /// Activa una habilidad manual de combate sin abrir antes su dialogo de detalle.
  void _handleQuickActivateAbility(BattlerAbility ability) {
    if (!_canQuickActivateAbility(ability)) return;

    _controller.togglePlayerAbility(ability);
  }

  Future<void> _handleOpenPendingRewards() async {
    final exitResult = _pendingVictoryExitResult;
    if (exitResult == null || _isPresentingVictoryRewards) return;

    setState(() {
      _isPresentingVictoryRewards = true;
    });

    final rewardedResult = await _presentVictoryRewards(
      exitResult,
      rewards: BattleRewardBundle(
        lootItem: _pendingVictoryLootItem,
        moneyReward: _pendingVictoryMoneyReward,
      ),
    );
    if (!mounted) return;

    _completeBattleExit(rewardedResult);
  }

  Future<void> _handleOpenItems() async {
    if (!_controller.canUseActions || _pendingVictoryExitResult != null) return;

    await showEndpointOverlay<void>(
      context: context,
      builder: (_) => BattleItemsDialog(
        player: _controller.player,
        items: _controller.player.inventoryItems,
      ),
      barrierColor: EndpointPalette.overlayScrimSoft,
    );
  }

  Future<void> _handleOpenEquippedItemDetails(
    Battler battler,
    Item item,
  ) async {
    if (_pendingVictoryExitResult != null) return;

    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de objeto equipado',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return EndpointItemDetailsDialog(
          item: item,
          accent: item.rarity.accent,
          price: item.cost,
          statusText: _statusLabelFor(battler, item),
        );
      },
    );
  }

  String _statusLabelFor(Battler battler, Item item) {
    if (battler.equippedItems.contains(item)) {
      return 'Estado actual: equipado';
    }
    if (battler.inventoryItems.contains(item)) {
      return 'Estado actual: en inventario';
    }
    return 'Estado actual: no disponible';
  }

  Future<void> _handleOpenAbilityDetails(
    Battler battler,
    BattlerAbility ability, {
    required Color accent,
    required bool canControlOwner,
  }) async {
    if (_pendingVictoryExitResult != null) return;

    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de habilidad',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentOwner =
                canControlOwner ? _controller.player : _controller.enemy;
            final currentAbility =
                currentOwner.abilityById(ability.id) ?? ability;

            return EndpointAbilityDetailsDialog(
              ability: currentAbility,
              accent: accent,
              statusText: _abilityStatusTextFor(
                currentAbility,
                canControlOwner: canControlOwner,
              ),
              actionLabel: _abilityActionLabelFor(
                currentAbility,
                canControlOwner: canControlOwner,
              ),
              onPrimaryAction: _isAbilityActionEnabled(
                currentAbility,
                canControlOwner: canControlOwner,
              )
                  ? () {
                      _controller.togglePlayerAbility(currentAbility);
                      setDialogState(() {});
                    }
                  : null,
              isActionEnabled: _isAbilityActionEnabled(
                currentAbility,
                canControlOwner: canControlOwner,
              ),
              enabledActionTooltip: currentAbility.isActive
                  ? 'Desactivar habilidad manual'
                  : 'Activar habilidad manual',
              disabledActionTooltip: _disabledAbilityActionTooltipFor(
                currentAbility,
                canControlOwner: canControlOwner,
              ),
            );
          },
        );
      },
    );
  }

  String _abilityStatusTextFor(
    BattlerAbility ability, {
    required bool canControlOwner,
  }) {
    final stateText = ability.isActive
        ? 'Estado actual: activa.'
        : ability.isOnCooldown
            ? 'Estado actual: en cooldown (${ability.remainingCooldownLabel}).'
            : 'Estado actual: lista.';
    final ownershipText =
        canControlOwner ? 'Pertenece al jugador.' : 'Pertenece al enemigo.';
    final activationText = ability.manualActivationContext == null
        ? 'Se aplica sin activacion manual.'
        : 'Se puede activar manualmente en ${ability.manualActivationContext!.label}.';

    return '$stateText $ownershipText $activationText';
  }

  String? _abilityActionLabelFor(
    BattlerAbility ability, {
    required bool canControlOwner,
  }) {
    if (!canControlOwner ||
        !ability.canToggleOn(BattlerAbilityActivationContext.battle)) {
      return null;
    }

    return ability.isActive ? 'Desactivar' : 'Activar';
  }

  bool _isAbilityActionEnabled(
    BattlerAbility ability, {
    required bool canControlOwner,
  }) {
    if (!canControlOwner ||
        !ability.canToggleOn(BattlerAbilityActivationContext.battle) ||
        !_controller.canUseActions) {
      return false;
    }
    if (ability.isActive) return true;
    if (!_controller.player.canActivateManualAbilities(
      BattlerAbilityActivationContext.battle,
    )) {
      return false;
    }

    return !ability.isOnCooldown && ability.isImplemented;
  }

  String _disabledAbilityActionTooltipFor(
    BattlerAbility ability, {
    required bool canControlOwner,
  }) {
    if (!canControlOwner) return 'Solo puedes gestionar habilidades propias';
    if (!_controller.canUseActions) {
      return 'Solo puedes gestionar habilidades en tu turno';
    }
    final blockReason = _controller.player.manualAbilityActivationBlockReason(
      BattlerAbilityActivationContext.battle,
    );
    if (blockReason != null && !ability.isActive) {
      return blockReason;
    }
    if (!ability.isImplemented) return 'La habilidad aun no esta implementada';
    if (ability.isOnCooldown) {
      return 'Recarga restante: ${ability.remainingCooldownLabel}';
    }
    return 'No se puede activar desde esta pantalla';
  }

  @override
  Widget build(BuildContext context) {
    final hasPendingVictoryRewards = _pendingVictoryExitResult != null;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: NodeSceneWrapper(
          showTitle: widget.showTitle,
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: EndpointGradients.battle),
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
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
                                  enemy: _controller.enemy,
                                  visibleAbilities: _battleVisibleAbilities(
                                    _controller.enemy,
                                  ),
                                  onOpenEquippedItemDetails: (item) =>
                                      _handleOpenEquippedItemDetails(
                                    _controller.enemy,
                                    item,
                                  ),
                                  onOpenAbilityDetails: (ability) =>
                                      _handleOpenAbilityDetails(
                                    _controller.enemy,
                                    ability,
                                    accent: enemyAccent,
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
                                  player: _controller.player,
                                  visibleAbilities: _battleVisibleAbilities(
                                    _controller.player,
                                  ),
                                  isEnabled: _controller.canUseActions,
                                  onAttack: _handlePlayerAttack,
                                  onOpenItems: _handleOpenItems,
                                  onQuickActivateAbility:
                                      _handleQuickActivateAbility,
                                  canQuickActivateAbility:
                                      _canQuickActivateAbility,
                                  onOpenEquippedItemDetails: (item) =>
                                      _handleOpenEquippedItemDetails(
                                    _controller.player,
                                    item,
                                  ),
                                  onOpenAbilityDetails: (ability) =>
                                      _handleOpenAbilityDetails(
                                    _controller.player,
                                    ability,
                                    accent: playerAccent,
                                    canControlOwner: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: _BattleCenterOverlay(
                          title: _controller.turnTitle,
                          description: _controller.turnDescription,
                          isEnemyTurn:
                              _controller.turn == BattleTurnState.enemy,
                          isCombatFinished: _controller.isCombatFinished,
                          onAdvancePressed: hasPendingVictoryRewards
                              ? _handleOpenPendingRewards
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
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                EndpointText(
                  title.toUpperCase(),
                  style: textTitleSmallBold.copyWith(
                    color: accent,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                EndpointText(
                  subtitle,
                  style: textSmallBold.copyWith(
                    color: EndpointPalette.softForeground.withAlpha(184),
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
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
      child: EndpointPanel(
        accent: accent,
        backgroundColor: EndpointPalette.panelBackgroundBattle,
        borderRadius: 10,
        glowOpacity: 0.04,
        blurRadius: 16,
        spreadRadius: 1,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EndpointText(
              title,
              textAlign: TextAlign.center,
              style: textTitleSmallBold.copyWith(
                color: accent,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 3),
            EndpointText(
              description,
              textAlign: TextAlign.center,
              style: textSmallBold.copyWith(
                color: EndpointPalette.softForeground.withAlpha(214),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
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
          const SizedBox(width: 10),
          EndpointActionButton(
            label: '-->',
            onPressed: onAdvancePressed,
            tooltip: 'Abrir botin del combate',
            accent: EndpointPalette.rewardAccent,
            backgroundColor: EndpointPalette.panelBackgroundBattle,
            foregroundColor: EndpointPalette.softForegroundWarm,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
  final VoidCallback onAttack;
  final Future<void> Function() onOpenItems;

  const _ActionPanel({
    required this.isEnabled,
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
          tooltip: 'Atacar al enemigo',
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
        child: EndpointPanel(
          accent: accent,
          backgroundColor: EndpointPalette.panelBackgroundBattle,
          borderRadius: 10,
          glowOpacity: 0,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                  const SizedBox(width: 10),
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
    final equipmentStrip = EndpointEquipmentSlotsStrip(
      battler: battler,
      layout: EndpointEquipmentLayout.standard,
      tileExtent: 54,
      tileHeight: 66,
      emojiSize: 14,
      borderColor: accent.withAlpha(87),
      onItemPressed: onItemPressed,
    );
    final abilityStrip = EndpointAbilitySlotsStrip(
      abilities: abilities,
      accent: accent,
      onAbilityPressed: onAbilityPressed,
      onAbilityHoldCompleted: onAbilityHoldCompleted,
      canHoldActivateAbility: canHoldActivateAbility,
      enableTooltipLongPress: enableAbilityTooltipLongPress,
    );
    final children = mirrorHorizontally
        ? <Widget>[
            abilityStrip,
            const SizedBox(width: 12),
            equipmentStrip,
          ]
        : <Widget>[
            equipmentStrip,
            const SizedBox(width: 12),
            abilityStrip,
          ];

    return SizedBox(
      height: 66,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: children,
                ),
              ),
            ),
          );
        },
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
    return EndpointPanel(
      accent: accent,
      backgroundColor: EndpointPalette.panelBackgroundBattle,
      borderRadius: 12,
      glowOpacity: 0.06,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EndpointEmojiSprite(
            emoji: emoji,
            accent: accent,
            size: 58,
            mirror: mirror,
          ),
          const SizedBox(height: 3),
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
