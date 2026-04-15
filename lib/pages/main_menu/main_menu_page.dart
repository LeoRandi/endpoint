import '../_imports.dart';

class MainMenuPage extends StatefulWidget {
  final EndpointSettingsSnapshot initialSettings;
  final EndpointCurrentRunSnapshot? initialRunSnapshot;

  const MainMenuPage({
    super.key,
    this.initialSettings = const EndpointSettingsSnapshot.defaults(),
    this.initialRunSnapshot,
  });

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage>
    with SingleTickerProviderStateMixin {
  static const String _mainMenuTutorialId = 'main_menu';
  static const int _mainMenuTutorialVersion = 1;
  static const String _menuColumnTutorialTargetId = 'main_menu.column';
  static const String _continueTutorialTargetId = 'main_menu.continue';
  static const String _startTutorialTargetId = 'main_menu.start';
  static const String _codexTutorialTargetId = 'main_menu.codex';
  static const String _settingsTutorialTargetId = 'main_menu.settings';
  static const List<String> _tutorialImagePool = <String>[
    'assets/sprites/image_1.png',
    'assets/sprites/base_dude.png',
    'assets/sprites/base_green_dude.png',
    'assets/images/tiles/path_tile.png',
    'assets/images/icons/icon_sword.png',
    'assets/images/icons/icon_shield.png',
  ];
  static const List<EndpointTutorialStepDescriptor> _mainMenuTutorialSteps =
      <EndpointTutorialStepDescriptor>[
    EndpointTutorialStepDescriptor(
      targetId: _menuColumnTutorialTargetId,
      description:
          'Esta columna es tu acceso rapido a todo el flujo principal.',
      highlightBorderRadius: BorderRadius.all(Radius.circular(12)),
      highlightPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
    ),
    EndpointTutorialStepDescriptor(
      targetId: _settingsTutorialTargetId,
      description: 'Ajustes: sonido, vibracion, velocidad y modo de juego.',
      highlightBorderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    EndpointTutorialStepDescriptor(
      targetId: _codexTutorialTargetId,
      description: 'Codex mostrara informacion de entidades y sistemas.',
      highlightBorderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    EndpointTutorialStepDescriptor(
      targetId: _startTutorialTargetId,
      description: 'Start comienza una run nueva desde cero.',
      highlightBorderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    EndpointTutorialStepDescriptor(
      targetId: _continueTutorialTargetId,
      description: 'Continue retoma una run guardada si existe.',
      highlightBorderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  ];

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;
  late EndpointSettingsSnapshot _settings;
  EndpointCurrentRunSnapshot? _currentRunSnapshot;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _currentRunSnapshot = widget.initialRunSnapshot;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glow = Tween<double>(
      begin: 0.35,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openNewRun() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PathSelectionPage(),
      ),
    );
    if (!mounted) return;

    await _refreshCurrentRunSnapshot();
  }

  Future<void> _openSavedRun() async {
    final currentRunSnapshot = _currentRunSnapshot;
    if (currentRunSnapshot == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PathSelectionPage.continueRun(
          restoredRun: currentRunSnapshot,
        ),
      ),
    );
    if (!mounted) return;

    await _refreshCurrentRunSnapshot();
  }

  Future<void> _refreshCurrentRunSnapshot() async {
    final restoredRun =
        await EndpointPreferencesService.loadCurrentRunSnapshot();
    if (!mounted) return;

    setState(() {
      _currentRunSnapshot = restoredRun;
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = EndpointPalette.primaryAccent;
    const surface = EndpointPalette.panelBackground;

    return EndpointTutorialHost(
      tutorialId: _mainMenuTutorialId,
      tutorialVersion: _mainMenuTutorialVersion,
      barrierLabel: 'Tutorial del menu principal',
      fallbackImagePool: _tutorialImagePool,
      steps: _mainMenuTutorialSteps,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: EndpointGradients.menu),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _MenuBackdrop(),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Builder(
                      builder: (tutorialContext) {
                        return EndpointActionButton(
                          label: '?',
                          tooltip: 'Mostrar tutorial del menu',
                          onPressed: () {
                            unawaited(
                              EndpointTutorialHost.startTutorial(
                                tutorialContext,
                                force: true,
                              ),
                            );
                          },
                          useMarquee: false,
                          width: 52,
                          height: 52,
                          borderRadius: 14,
                          borderWidth: 2,
                          accent: EndpointPalette.infoAccent,
                          backgroundColor: EndpointPalette.blend(
                            EndpointPalette.menuButtonBackground,
                            EndpointPalette.infoAccent,
                            0.1,
                          ),
                          textStyle: textLargeBold.copyWith(
                            fontSize: 34,
                            letterSpacing: 0,
                            color: EndpointPalette.infoAccent,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: EndpointPanel(
                        accent: accent,
                        backgroundColor: surface.withValues(alpha: 0.72),
                        borderRadius: 16,
                        glowOpacity: 0.1,
                        blurRadius: 30,
                        spreadRadius: 4,
                        padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scale.value,
                                  child: EndpointText(
                                    'DEATH AT SUNRISE',
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    style: textExtraLargeBold.copyWith(
                                      fontSize: 42,
                                      letterSpacing: 3.2,
                                      color: Color.lerp(
                                        EndpointPalette.soften(
                                          accent,
                                          amount: 0.12,
                                        ),
                                        accent,
                                        _glow.value,
                                      ),
                                      shadows: [
                                        Shadow(
                                          color: accent.withValues(
                                            alpha: 0.35 + (_glow.value * 0.25),
                                          ),
                                          blurRadius: 12 + (_glow.value * 18),
                                        ),
                                        Shadow(
                                          color: Colors.white.withValues(
                                            alpha: 0.12 + (_glow.value * 0.16),
                                          ),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SeparatorFiori.double(),
                            EndpointTutorialTarget(
                              targetId: _menuColumnTutorialTargetId,
                              child: Column(
                                children: [
                                  EndpointTutorialTarget(
                                    targetId: _continueTutorialTargetId,
                                    child: EndpointMenuButton(
                                      label: EndpointStrings.continueRun,
                                      tooltip: _currentRunSnapshot == null
                                          ? 'No hay ninguna run en curso'
                                          : 'Continuar la run guardada',
                                      onPressed: _currentRunSnapshot == null
                                          ? null
                                          : _openSavedRun,
                                    ),
                                  ),
                                  const SeparatorFiori.half(),
                                  EndpointTutorialTarget(
                                    targetId: _startTutorialTargetId,
                                    child: EndpointMenuButton(
                                      label: EndpointStrings.start,
                                      tooltip:
                                          'Iniciar la carrera hasta el sunrise',
                                      onPressed: _openNewRun,
                                    ),
                                  ),
                                  const SeparatorFiori.half(),
                                  const EndpointTutorialTarget(
                                    targetId: _codexTutorialTargetId,
                                    child: EndpointMenuButton(
                                      label: EndpointStrings.codex,
                                      tooltip: EndpointStrings.codexUnavailable,
                                    ),
                                  ),
                                  const SeparatorFiori.half(),
                                  EndpointTutorialTarget(
                                    targetId: _settingsTutorialTargetId,
                                    child: EndpointMenuButton(
                                      label: EndpointStrings.settings,
                                      tooltip: 'Abrir configuracion',
                                      onPressed: () async {
                                        final updatedSettings =
                                            await Navigator.of(context)
                                                .push<EndpointSettingsSnapshot>(
                                          buildEndpointSceneRoute(
                                            SettingsPage(
                                              initialSettings: _settings,
                                            ),
                                          ),
                                        );
                                        if (!mounted ||
                                            updatedSettings == null) {
                                          return;
                                        }

                                        setState(() {
                                          _settings = updatedSettings;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

class _MenuBackdrop extends StatelessWidget {
  const _MenuBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: const Alignment(-0.8, -0.85),
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  EndpointPalette.primaryAccent.withValues(alpha: 0.13),
                  EndpointPalette.scaffoldBackground.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0.9, 0.7),
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  EndpointPalette.blend(
                    EndpointPalette.primaryAccent,
                    EndpointPalette.panelBackground,
                    0.35,
                  ).withValues(alpha: 0.1),
                  EndpointPalette.scaffoldBackground.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        const IgnorePointer(
          child: CustomPaint(
            painter: _ScanlinePainter(),
          ),
        ),
      ],
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  const _ScanlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const scanlineStep = 24.0;
    const gridStep = 48.0;

    final scanlinePaint = Paint()
      ..color = EndpointPalette.primaryAccent.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = EndpointPalette.primaryAccent.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    for (double y = 0; y <= size.height; y += scanlineStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }

    for (double x = 0; x <= size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
