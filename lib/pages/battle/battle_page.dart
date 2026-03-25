import '_imports.dart';

class BattlePage extends StatefulWidget {
  final Battler enemy;
  final Battler player;
  final String showTitle;
  final int victoryMoneyFactor;
  final Duration enemyTurnDelay;
  final Duration combatEndDelay;
  final bool returnResultToCaller;

  const BattlePage({
    super.key,
    this.enemy = defaultEnemyBattler,
    this.player = defaultPlayerBattler,
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
  late final BattleController _controller;
  final Random _lootRandom = Random();
  bool _isPresentingVictoryRewards = false;

  @override
  void initState() {
    super.initState();
    _controller = BattleController(
      enemy: widget.enemy,
      player: widget.player,
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
    if (_isPresentingVictoryRewards) return;

    _isPresentingVictoryRewards = true;
    final rewardedResult = await _presentVictoryRewards(exitResult);
    if (!mounted) return;

    _completeBattleExit(rewardedResult);
  }

  Future<BattleFlowResult> _presentVictoryRewards(
    BattleFlowResult exitResult,
  ) async {
    final lootItem = _selectVictoryLoot(
      enemy: _controller.enemy,
      player: exitResult.player,
    );
    final moneyReward = _buildVictoryMoneyReward(exitResult.player);
    if (lootItem == null && moneyReward <= 0) {
      return exitResult;
    }

    final rewardedPlayer = await showEndpointOverlay<Battler>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.74),
      builder: (_) => BattleLootOverlay(
        player: exitResult.player,
        lootItem: lootItem,
        moneyReward: moneyReward,
        enemyName: _controller.enemy.name,
      ),
    );

    return BattleFlowResult(
      type: exitResult.type,
      player: rewardedPlayer ?? exitResult.player,
    );
  }

  int _buildVictoryMoneyReward(Battler player) {
    return max(0, player.income * widget.victoryMoneyFactor);
  }

  Item? _selectVictoryLoot({
    required Battler enemy,
    required Battler player,
  }) {
    final lootPool = <Item>{
      ...enemy.equippedItems,
      ...enemy.inventoryItems,
    }.toList(growable: false);
    if (lootPool.isEmpty) return null;

    final preferredPool = lootPool
        .where((item) => !player.ownsItem(item))
        .toList(growable: false);
    final resolvedPool = preferredPool.isNotEmpty ? preferredPool : lootPool;

    return resolvedPool[_lootRandom.nextInt(resolvedPool.length)];
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

  Future<bool> _handleWillPop() async {
    return false;
  }

  void _handlePlayerAttack() {
    _controller.handleAttack();
  }

  Future<void> _handleOpenItems() async {
    if (!_controller.canUseActions) return;

    await showEndpointOverlay<void>(
      context: context,
      builder: (_) => BattleItemsDialog(
        player: _controller.player,
        items: _controller.player.inventoryItems,
      ),
      barrierColor: Colors.black.withOpacity(0.12),
    );
  }

  Future<void> _handleOpenEquippedItemDetails(
    Battler battler,
    Item item,
  ) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Detalle de objeto equipado',
      barrierColor: Colors.black.withOpacity(0.62),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return EndpointItemDetailsDialog(
          item: item,
          accent: item.rarity.accent,
          price: item.cost,
          statusText: _statusLabelFor(battler, item),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Scaffold(
            body: NodeSceneWrapper(
              showTitle: widget.showTitle,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF090406),
                      Color(0xFF050907),
                      Color(0xFF020403),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: _BattleSide(
                              title: 'THREAT',
                              subtitle: 'Enemy',
                              accent: const Color(0xFFFF6B6B),
                              background: const [
                                Color(0xFF230C11),
                                Color(0xFF12060A),
                              ],
                              child: SizedBox.expand(
                                child: _EnemyBattleHud(
                                  enemy: _controller.enemy,
                                  onOpenEquippedItemDetails: (item) =>
                                      _handleOpenEquippedItemDetails(
                                    _controller.enemy,
                                    item,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            height: 2,
                            color: const Color(0x335AF78E),
                          ),
                          Expanded(
                            child: _BattleSide(
                              title: 'OPERATIVE',
                              subtitle: 'Player',
                              accent: const Color(0xFF5AF78E),
                              background: const [
                                Color(0xFF07110D),
                                Color(0xFF030806),
                              ],
                              child: SizedBox.expand(
                                child: _PlayerBattleHud(
                                  player: _controller.player,
                                  isEnabled: _controller.canUseActions,
                                  onAttack: _handlePlayerAttack,
                                  onOpenItems: _handleOpenItems,
                                  onOpenEquippedItemDetails: (item) =>
                                      _handleOpenEquippedItemDetails(
                                    _controller.player,
                                    item,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      IgnorePointer(
                        child: Center(
                          child: _TurnBanner(
                            title: _controller.turnTitle,
                            description: _controller.turnDescription,
                            isEnemyTurn:
                                _controller.turn == BattleTurnState.enemy,
                            isCombatFinished: _controller.isCombatFinished,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
                  style: textSmallBold.copyWith(
                    color: accent,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                EndpointText(
                  subtitle,
                  style: textSmallBold.copyWith(
                    color: Colors.white.withOpacity(0.72),
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
        ? const Color(0xFFEBCB5A)
        : isEnemyTurn
            ? const Color(0xFFFF6B6B)
            : const Color(0xFF5AF78E);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: EndpointPanel(
        accent: accent,
        backgroundColor: const Color(0xCC05100B),
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
              style: textSmallBold.copyWith(
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
                color: Colors.white.withOpacity(0.84),
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
  final bool isEnabled;
  final VoidCallback onAttack;
  final Future<void> Function() onOpenItems;
  final Future<void> Function(Item item) onOpenEquippedItemDetails;

  const _PlayerBattleHud({
    required this.player,
    required this.isEnabled,
    required this.onAttack,
    required this.onOpenItems,
    required this.onOpenEquippedItemDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        _BattleLoadoutStrip(
          battler: player,
          accent: const Color(0xFF5AF78E),
          mirrorHorizontally: false,
          onItemPressed: onOpenEquippedItemDetails,
        ),
        const SizedBox(height: 8),
        _BattleStatusBar(
          battler: player,
          accent: const Color(0xFF5AF78E),
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
              accent: Color(0xFF5AF78E),
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
  final Future<void> Function(Item item) onOpenEquippedItemDetails;

  const _EnemyBattleHud({
    required this.enemy,
    required this.onOpenEquippedItemDetails,
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
              accent: Color(0xFFFF6B6B),
              label: 'FOE',
            ),
            Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        _BattleStatusBar(
          battler: enemy,
          accent: const Color(0xFFFF6B6B),
          factionLabel: 'HOSTILE',
          mirrorHorizontally: true,
        ),
        const SizedBox(height: 8),
        _BattleLoadoutStrip(
          battler: enemy,
          accent: const Color(0xFFFF6B6B),
          mirrorHorizontally: true,
          onItemPressed: onOpenEquippedItemDetails,
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
          backgroundColor: const Color(0xCC05100B),
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
                      style: textSmallBold.copyWith(
                        color: Colors.white.withOpacity(0.84),
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
                      style: textSmallBold.copyWith(
                        color: const Color(0xFFE6FFF0),
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
                      style: textSmallBold.copyWith(
                        color: Colors.white.withOpacity(0.84),
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              EndpointHealthBar(
                value: healthFactor,
                accent: accent,
                height: 10,
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
  final Color accent;
  final bool mirrorHorizontally;
  final ValueChanged<Item>? onItemPressed;

  const _BattleLoadoutStrip({
    required this.battler,
    required this.accent,
    required this.mirrorHorizontally,
    this.onItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    final equipmentStrip = EndpointEquipmentSlotsStrip(
      battler: battler,
      layout: EndpointEquipmentLayout.standard,
      tileExtent: 54,
      tileHeight: 66,
      emojiSize: 14,
      borderColor: accent.withOpacity(0.34),
      onItemPressed: onItemPressed,
    );
    final abilityStrip = _AbilitySlotsStrip(
      abilities: battler.abilities,
      accent: accent,
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

class _AbilitySlotsStrip extends StatelessWidget {
  final List<BattlerAbility> abilities;
  final Color accent;

  const _AbilitySlotsStrip({
    required this.abilities,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final slotCount = max(3, abilities.length);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int index = 0; index < slotCount; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          _AbilitySlotTile(
            accent: accent,
            isReserved: index < abilities.length,
            tooltip: index < abilities.length
                ? abilities[index].label
                : 'Slot de habilidad',
          ),
        ],
      ],
    );
  }
}

class _AbilitySlotTile extends StatelessWidget {
  final Color accent;
  final bool isReserved;
  final String tooltip;

  const _AbilitySlotTile({
    required this.accent,
    required this.isReserved,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return HoldTooltip(
      message: tooltip,
      child: SizedBox(
        width: 46,
        height: 46,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xCC05100B),
            border: Border.all(color: accent.withOpacity(0.5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.08),
                blurRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(isReserved ? 0.72 : 0.24),
              ),
              child: SizedBox(
                width: isReserved ? 10 : 6,
                height: isReserved ? 10 : 6,
              ),
            ),
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
    return EndpointPanel(
      accent: accent,
      backgroundColor: const Color(0xCC05100B),
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
              color: const Color(0xFFE6FFF0),
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
      ..color = accent.withOpacity(0.08)
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
