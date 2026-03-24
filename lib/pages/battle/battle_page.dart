import '_imports.dart';

class BattlePage extends StatefulWidget {
  final Battler enemy;
  final Battler player;
  final String showTitle;
  final Duration enemyTurnDelay;
  final Duration combatEndDelay;
  final bool returnResultToCaller;

  const BattlePage({
    super.key,
    this.enemy = defaultEnemyBattler,
    this.player = defaultPlayerBattler,
    this.showTitle = 'ENCOUNTER',
    this.enemyTurnDelay = const Duration(milliseconds: 900),
    this.combatEndDelay = const Duration(seconds: 2),
    this.returnResultToCaller = false,
  });

  @override
  State<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends State<BattlePage> {
  late final BattleController _controller;

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
                  child: Column(
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
                              turnTitle: _controller.turnTitle,
                              turnDescription: _controller.turnDescription,
                              isEnemyTurn:
                                  _controller.turn == BattleTurnState.enemy,
                              isCombatFinished: _controller.isCombatFinished,
                              onAttack: _handlePlayerAttack,
                              onOpenItems: _handleOpenItems,
                            ),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                    fontSize: 15,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: 2),
                EndpointText(
                  subtitle,
                  style: textSmallBold.copyWith(
                    color: Colors.white.withOpacity(0.72),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
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
      constraints: const BoxConstraints(maxWidth: 320),
      child: EndpointPanel(
        accent: accent,
        backgroundColor: const Color(0xCC05100B),
        borderRadius: 12,
        glowOpacity: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            EndpointText(
              title,
              textAlign: TextAlign.center,
              style: textSmallBold.copyWith(
                color: accent,
                fontSize: 14,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 4),
            EndpointText(
              description,
              textAlign: TextAlign.center,
              style: textSmallBold.copyWith(
                color: Colors.white.withOpacity(0.84),
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
  final String turnTitle;
  final String turnDescription;
  final bool isEnemyTurn;
  final bool isCombatFinished;
  final VoidCallback onAttack;
  final Future<void> Function() onOpenItems;

  const _PlayerBattleHud({
    required this.player,
    required this.isEnabled,
    required this.turnTitle,
    required this.turnDescription,
    required this.isEnemyTurn,
    required this.isCombatFinished,
    required this.onAttack,
    required this.onOpenItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: _TurnBanner(
            title: turnTitle,
            description: turnDescription,
            isEnemyTurn: isEnemyTurn,
            isCombatFinished: isCombatFinished,
          ),
        ),
        const Spacer(),
        _BattleLoadoutStrip(
          battler: player,
          accent: const Color(0xFF5AF78E),
          mirrorHorizontally: false,
        ),
        const SizedBox(height: 10),
        _BattleStatusBar(
          battler: player,
          accent: const Color(0xFF5AF78E),
          factionLabel: 'ALLY',
          mirrorHorizontally: false,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ActionPanel(
              isEnabled: isEnabled,
              onAttack: onAttack,
              onOpenItems: onOpenItems,
            ),
            const Spacer(),
            const _BattleSpriteDock(
              emoji: '\u{1F916}',
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

  const _EnemyBattleHud({
    required this.enemy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BattleSpriteDock(
              emoji: '\u{1F47E}',
              accent: Color(0xFFFF6B6B),
              label: 'FOE',
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 10),
        _BattleStatusBar(
          battler: enemy,
          accent: const Color(0xFFFF6B6B),
          factionLabel: 'HOSTILE',
          mirrorHorizontally: true,
        ),
        const SizedBox(height: 10),
        _BattleLoadoutStrip(
          battler: enemy,
          accent: const Color(0xFFFF6B6B),
          mirrorHorizontally: true,
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
        constraints: const BoxConstraints(maxWidth: 360),
        child: EndpointPanel(
          accent: accent,
          backgroundColor: const Color(0xCC05100B),
          borderRadius: 12,
          glowOpacity: 0,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  EndpointText(
                    factionLabel,
                    style: textSmallBold.copyWith(
                      color: accent,
                      fontSize: 14,
                      letterSpacing: 1.4,
                    ),
                  ),
                  if (!mirrorHorizontally) ...[
                    const SizedBox(width: 8),
                    EndpointText(
                      '${battler.health} / ${battler.maxHealth}',
                      style: textSmallBold.copyWith(
                        color: Colors.white.withOpacity(0.84),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              EndpointHealthBar(
                value: healthFactor,
                accent: accent,
                height: 12,
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

  const _BattleLoadoutStrip({
    required this.battler,
    required this.accent,
    required this.mirrorHorizontally,
  });

  @override
  Widget build(BuildContext context) {
    final equipmentStrip = EndpointEquipmentSlotsStrip(
      battler: battler,
      layout: EndpointEquipmentLayout.standard,
      tileExtent: 62,
      tileHeight: 74,
      emojiSize: 16,
      borderColor: accent.withOpacity(0.34),
    );
    final abilityStrip = _AbilitySlotsStrip(
      abilities: battler.abilities,
      accent: accent,
    );
    final children = mirrorHorizontally
        ? <Widget>[
            abilityStrip,
            const SizedBox(width: 18),
            equipmentStrip,
          ]
        : <Widget>[
            equipmentStrip,
            const SizedBox(width: 18),
            abilityStrip,
          ];

    return SizedBox(
      height: 76,
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
          if (index > 0) const SizedBox(width: 8),
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
        width: 56,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xCC05100B),
            border: Border.all(color: accent.withOpacity(0.5), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.08),
                blurRadius: 12,
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
                width: isReserved ? 12 : 8,
                height: isReserved ? 12 : 8,
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
      borderRadius: 14,
      glowOpacity: 0.06,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EndpointEmojiSprite(
            emoji: emoji,
            accent: accent,
            size: 84,
            mirror: mirror,
          ),
          const SizedBox(height: 4),
          EndpointText(
            label,
            style: textSmallBold.copyWith(
              color: const Color(0xFFE6FFF0),
              letterSpacing: 1.1,
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
