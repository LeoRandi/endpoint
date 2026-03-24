import '_imports.dart';

class BattlePage extends StatefulWidget {
  final Battler enemy;
  final Battler player;
  final String showTitle;
  final Duration enemyTurnDelay;
  final Duration combatEndDelay;
  final bool returnPlayerOnCombatEnd;

  const BattlePage({
    super.key,
    this.enemy = defaultEnemyBattler,
    this.player = defaultPlayerBattler,
    this.showTitle = 'ENCOUNTER',
    this.enemyTurnDelay = const Duration(milliseconds: 900),
    this.combatEndDelay = const Duration(seconds: 2),
    this.returnPlayerOnCombatEnd = false,
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

    // TODO: Rename returnPlayerOnCombatEnd to returnResultToCaller in a future API cleanup.
    if (widget.returnPlayerOnCombatEnd) {
      navigator.pop(exitResult);
      return;
    }

    navigator.popUntil((route) => route.isFirst);
  }

  Future<bool> _handleWillPop() async {
    _controller.handleSystemBack();
    return false;
  }

  void _handlePlayerAttack() {
    _controller.handleAttack();
  }

  Future<void> _handleOpenItems() async {
    if (!_controller.canUseActions) return;

    // TODO: Allow battle items to execute real combat effects once consumables exist.
    await showEndpointOverlay<void>(
      context: context,
      builder: (_) => BattleItemsDialog(items: _controller.player.inventoryItems),
    );
  }

  Future<void> _handleOpenSkills() async {
    if (!_controller.canUseActions) return;

    final selectedSkill = await showEndpointOverlay<BattlerAbility>(
      context: context,
      builder: (_) => BattleSkillsDialog(skills: _controller.player.abilities),
    );

    if (!mounted || selectedSkill == null || !_controller.canUseActions) return;
    _controller.handleAbility(selectedSkill);
  }

  void _handleRunAway() {
    _controller.handleRunAway();
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
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: 320,
                              child: BattleCharacterPanel(
                                factionLabel: 'HOSTILE',
                                characterName: _controller.enemy.name,
                                currentHealth: _controller.enemy.health,
                                maxHealth: _controller.enemy.maxHealth,
                                spriteEmoji: '\u{1F47E}',
                                accent: const Color(0xFFFF6B6B),
                                spriteAlignment: Alignment.topCenter,
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
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              width: 420,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  BattleCharacterPanel(
                                    factionLabel: 'ALLY',
                                    characterName: _controller.player.name,
                                    currentHealth: _controller.player.health,
                                    maxHealth: _controller.player.maxHealth,
                                    spriteEmoji: '\u{1F916}',
                                    accent: const Color(0xFF5AF78E),
                                    mirrorSprite: true,
                                    spriteAlignment: Alignment.bottomCenter,
                                  ),
                                  const SizedBox(height: 12),
                                  _TurnBanner(
                                    title: _controller.turnTitle,
                                    description: _controller.turnDescription,
                                    isEnemyTurn:
                                        _controller.turn == BattleTurnState.enemy,
                                    isCombatFinished: _controller.isCombatFinished,
                                  ),
                                  const SizedBox(height: 12),
                                  _ActionPanel(
                                    isEnabled: _controller.canUseActions,
                                    onAttack: _handlePlayerAttack,
                                    onOpenSkills: _handleOpenSkills,
                                    onRunAway: _handleRunAway,
                                    onOpenItems: _handleOpenItems,
                                  ),
                                ],
                              ),
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
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
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
                  style: textMediumBold.copyWith(
                    color: accent,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                EndpointText(
                  subtitle,
                  style: textMedium.copyWith(
                    color: Colors.white.withOpacity(0.72),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(child: child),
                ),
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
      constraints: const BoxConstraints(maxWidth: 420),
      child: EndpointPanel(
        accent: accent,
        backgroundColor: const Color(0xCC05100B),
        borderRadius: 14,
        glowOpacity: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            EndpointText(
              title,
              textAlign: TextAlign.center,
              style: textMediumBold.copyWith(
                color: accent,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(height: 6),
            EndpointText(
              description,
              textAlign: TextAlign.center,
              style: textMedium.copyWith(
                color: Colors.white.withOpacity(0.84),
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
  final Future<void> Function() onOpenSkills;
  final VoidCallback onRunAway;
  final Future<void> Function() onOpenItems;

  const _ActionPanel({
    required this.isEnabled,
    required this.onAttack,
    required this.onOpenSkills,
    required this.onRunAway,
    required this.onOpenItems,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      backgroundColor: const Color(0xCC05100B),
      borderRadius: 16,
      glowOpacity: 0,
      blurRadius: 18,
      padding: const EdgeInsets.all(14),
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 56,
        ),
        children: [
          BattleActionButton(
            label: 'Atacar',
            icon: Icons.flash_on_rounded,
            onPressed: isEnabled ? onAttack : null,
            tooltip: 'Atacar al enemigo',
          ),
          BattleActionButton(
            label: 'Habilidades',
            icon: Icons.shield_outlined,
            onPressed: isEnabled ? onOpenSkills : null,
            tooltip: 'Abrir lista de habilidades',
          ),
          BattleActionButton(
            label: 'Huir',
            icon: Icons.directions_run_rounded,
            onPressed: isEnabled ? onRunAway : null,
            tooltip: 'Abandonar el combate',
          ),
          BattleActionButton(
            label: 'Objetos',
            icon: Icons.inventory_2_outlined,
            onPressed: isEnabled ? onOpenItems : null,
            tooltip: 'Abrir inventario de combate',
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

