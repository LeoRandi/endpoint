import '_imports.dart';

enum _BattleTurn {
  player,
  enemy,
  finished,
}

class BattlePage extends StatefulWidget {
  final Battler enemy;
  final Battler player;
  final Duration enemyTurnDelay;
  final Duration combatEndDelay;
  final bool returnPlayerOnCombatEnd;

  const BattlePage({
    super.key,
    this.enemy = defaultEnemyBattler,
    this.player = defaultPlayerBattler,
    this.enemyTurnDelay = const Duration(milliseconds: 900),
    this.combatEndDelay = const Duration(seconds: 2),
    this.returnPlayerOnCombatEnd = false,
  });

  @override
  State<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends State<BattlePage> {
  late Battler _enemy;
  late Battler _player;

  _BattleTurn _turn = _BattleTurn.player;
  String? _resultText;

  int _enemyActionId = 0;
  int _returnToMenuId = 0;

  bool get _isPlayerTurn => _turn == _BattleTurn.player;
  bool get _isCombatFinished => _turn == _BattleTurn.finished;
  bool get _canUseActions => _isPlayerTurn && !_isCombatFinished;

  String get _turnTitle {
    switch (_turn) {
      case _BattleTurn.player:
        return 'TURNO DEL JUGADOR';
      case _BattleTurn.enemy:
        return 'TURNO ENEMIGO';
      case _BattleTurn.finished:
        return 'COMBATE FINALIZADO';
    }
  }

  String get _turnDescription {
    switch (_turn) {
      case _BattleTurn.player:
        return 'Selecciona una accion.';
      case _BattleTurn.enemy:
        return 'El enemigo prepara su respuesta.';
      case _BattleTurn.finished:
        return _resultText ??
            ((_player.isDefeated || !widget.returnPlayerOnCombatEnd)
                ? 'Regresando al menu principal...'
                : 'Regresando a la ruta...');
    }
  }

  @override
  void initState() {
    super.initState();
    _enemy = widget.enemy;
    _player = widget.player;
  }

  @override
  void dispose() {
    _enemyActionId++;
    _returnToMenuId++;
    super.dispose();
  }

  void _handlePlayerAttack() {
    if (!_canUseActions) return;

    final updatedEnemy = _enemy.receiveAttack(_player);

    setState(() {
      _enemy = updatedEnemy;
      if (_enemy.isDefeated) {
        _turn = _BattleTurn.finished;
        _resultText = 'Objetivo neutralizado.';
      } else {
        _turn = _BattleTurn.enemy;
      }
    });

    if (updatedEnemy.isDefeated) {
      _scheduleCombatExit();
      return;
    }

    _startEnemyTurn();
  }

  void _startEnemyTurn() {
    if (_isCombatFinished) return;
    _scheduleEnemyTurn();
  }

  void _scheduleEnemyTurn() {
    final actionId = ++_enemyActionId;

    Future.delayed(widget.enemyTurnDelay, () {
      if (!mounted) return;
      if (actionId != _enemyActionId) return;
      if (_turn != _BattleTurn.enemy) return;

      final updatedPlayer = _player.receiveAttack(_enemy);

      setState(() {
        _player = updatedPlayer;
        if (_player.isDefeated) {
          _turn = _BattleTurn.finished;
          _resultText = 'La unidad ha caido.';
        } else {
          _turn = _BattleTurn.player;
        }
      });

      if (updatedPlayer.isDefeated) {
        _scheduleCombatExit();
      }
    });
  }

  void _scheduleCombatExit() {
    final returnId = ++_returnToMenuId;

    Future.delayed(widget.combatEndDelay, () {
      if (!mounted) return;
      if (returnId != _returnToMenuId) return;
      _closeBattleAfterCombat();
    });
  }

  void _closeBattleAfterCombat() {
    _enemyActionId++;
    _returnToMenuId++;

    final navigator = Navigator.of(context);
    if (_player.isDefeated) {
      if (!navigator.canPop()) return;
      navigator.popUntil((route) => route.isFirst);
      return;
    }
    if (widget.returnPlayerOnCombatEnd) {
      if (!navigator.canPop()) return;
      navigator.pop(_player);
      return;
    }
    if (!navigator.canPop()) return;
    navigator.popUntil((route) => route.isFirst);
  }

  void _returnToMainMenu() {
    _enemyActionId++;
    _returnToMenuId++;

    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return;

    navigator.popUntil((route) => route.isFirst);
  }

  void _handleRunAway() {
    if (!_canUseActions) return;
    _returnToMainMenu();
  }

  Future<void> _handleOpenItems() async {
    if (!_canUseActions) return;

    await showEndpointOverlay<void>(
      context: context,
      builder: (_) => const BattleItemsDialog(),
    );
  }

  Future<void> _handleOpenSkills() async {
    if (!_canUseActions) return;

    final selectedSkill = await showEndpointOverlay<String>(
      context: context,
      builder: (_) => BattleSkillsDialog(skills: _player.abilities),
    );

    if (!mounted) return;
    if (selectedSkill == null) return;
    if (!_canUseActions) return;

    switch (selectedSkill) {
      case 'Defender':
        setState(() {
          _turn = _BattleTurn.enemy;
        });
        _startEnemyTurn();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
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
                        characterName: _enemy.name,
                        currentHealth: _enemy.health,
                        maxHealth: _enemy.maxHealth,
                        spriteEmoji: '👾',
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
                            characterName: _player.name,
                            currentHealth: _player.health,
                            maxHealth: _player.maxHealth,
                            spriteEmoji: '🤖',
                            accent: const Color(0xFF5AF78E),
                            mirrorSprite: true,
                            spriteAlignment: Alignment.bottomCenter,
                          ),
                          const SizedBox(height: 12),
                          _TurnBanner(
                            title: _turnTitle,
                            description: _turnDescription,
                            isEnemyTurn: _turn == _BattleTurn.enemy,
                            isCombatFinished: _isCombatFinished,
                          ),
                          const SizedBox(height: 12),
                          _ActionPanel(
                            isEnabled: _canUseActions,
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
                Text(
                  title.toUpperCase(),
                  style: textMediumBold.copyWith(
                    color: accent,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC05100B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: textMediumBold.copyWith(
                  color: accent,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                style: textMedium.copyWith(
                  color: Colors.white.withOpacity(0.84),
                ),
              ),
            ],
          ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC05100B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x665AF78E)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
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
              tooltip: 'Volver al menu principal',
            ),
            BattleActionButton(
              label: 'Objetos',
              icon: Icons.inventory_2_outlined,
              onPressed: isEnabled ? onOpenItems : null,
              tooltip: 'Abrir inventario de combate',
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
