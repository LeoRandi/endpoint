import '../_imports.dart';
import 'package:showcaseview/showcaseview.dart';

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
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;
  late final ShowcaseView _mainMenuShowcase;
  final GlobalKey _continueShowcaseKey = GlobalKey();
  final GlobalKey _startShowcaseKey = GlobalKey();
  final GlobalKey _codexShowcaseKey = GlobalKey();
  final GlobalKey _settingsShowcaseKey = GlobalKey();
  late EndpointSettingsSnapshot _settings;
  EndpointCurrentRunSnapshot? _currentRunSnapshot;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _currentRunSnapshot = widget.initialRunSnapshot;
    _mainMenuShowcase = ShowcaseView.register(
      disableBarrierInteraction: true,
      disableMovingAnimation: true,
      disableScaleAnimation: true,
      blurValue: 0,
      globalTooltipActionConfig: const TooltipActionConfig(
        alignment: MainAxisAlignment.end,
        actionGap: 8,
        position: TooltipActionPosition.inside,
      ),
      globalTooltipActions: [
        TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          name: 'SALIR',
          backgroundColor: EndpointPalette.closeButtonBackground,
          textStyle: textSmallBold.copyWith(
            color: EndpointPalette.softForeground,
            letterSpacing: 0.8,
          ),
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: 'SIGUIENTE',
          backgroundColor: EndpointPalette.blend(
            EndpointPalette.menuButtonBackground,
            EndpointPalette.infoAccent,
            0.16,
          ),
          textStyle: textSmallBold.copyWith(
            color: EndpointPalette.softForegroundWarm,
            letterSpacing: 0.8,
          ),
          border: Border.all(
            color: EndpointPalette.infoAccent.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
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
    _mainMenuShowcase.unregister();
    _controller.dispose();
    super.dispose();
  }

  void _startMainMenuTutorial() {
    if (_mainMenuShowcase.isShowcaseRunning) {
      _mainMenuShowcase.dismiss();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _mainMenuShowcase.startShowCase(
        [
          _continueShowcaseKey,
          _startShowcaseKey,
          _codexShowcaseKey,
          _settingsShowcaseKey,
        ],
        delay: const Duration(milliseconds: 80),
      );
    });
  }

  Future<void> _openNewRun() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PathSelectionPage(
          initialSettings: _settings,
        ),
      ),
    );
    if (!mounted) return;

    await _refreshCurrentRunSnapshot();
  }

  Future<void> _openTutorialRun() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PathSelectionPage.tutorial(
          initialSettings: _settings,
        ),
      ),
    );
    if (!mounted) return;

    await _refreshCurrentRunSnapshot();
  }

  Future<void> _handleTutorialPressed() async {
    final accepted = await showEndpointDialog<bool>(
      context: context,
      barrierLabel: 'Confirmar tutorial',
      barrierDismissible: false,
      barrierColor: EndpointPalette.overlayScrimStrong,
      builder: (context) {
        return _MainMenuTutorialPromptDialog(
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
        );
      },
    );
    if (!mounted || accepted != true) return;

    await _openTutorialRun();
  }

  Future<void> _openSavedRun() async {
    final currentRunSnapshot = _currentRunSnapshot;
    if (currentRunSnapshot == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PathSelectionPage.continueRun(
          restoredRun: currentRunSnapshot,
          initialSettings: _settings,
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

    return Scaffold(
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
                  child: EndpointActionButton(
                    label: '?',
                    tooltip: 'Mostrar tutorial del menu',
                    onPressed: _startMainMenuTutorial,
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
                          Column(
                            children: [
                              _MainMenuShowcaseStep(
                                showcaseKey: _continueShowcaseKey,
                                title: 'Continue',
                                description:
                                    'Retoma la partida por donde lo dejaste.',
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
                              _MainMenuShowcaseStep(
                                showcaseKey: _startShowcaseKey,
                                title: 'Start',
                                description:
                                    'Empezar la partida desde 0. Deberás sobrevivir hasta ver el amanecer.',
                                child: EndpointMenuButton(
                                  label: EndpointStrings.start,
                                  tooltip: 'Iniciar partida',
                                  onPressed: _openNewRun,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _MainMenuTinyButton(
                                label: 'Tutorial',
                                tooltip: 'Iniciar tutorial guiado',
                                onPressed: _handleTutorialPressed,
                              ),
                              const SeparatorFiori.half(),
                              _MainMenuShowcaseStep(
                                showcaseKey: _codexShowcaseKey,
                                title: 'Codex',
                                description:
                                    'Registro de objetos, enemigos, habilidades y eventos descubiertos.',
                                child: const EndpointMenuButton(
                                  label: EndpointStrings.codex,
                                  tooltip: EndpointStrings.codexUnavailable,
                                ),
                              ),
                              const SeparatorFiori.half(),
                              _MainMenuShowcaseStep(
                                showcaseKey: _settingsShowcaseKey,
                                title: 'Settings',
                                description:
                                    'Desde los Settings puedes configurar algunos efectos visuales o el modo de juego',
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
                                    if (!mounted || updatedSettings == null) {
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
    );
  }
}

class _MainMenuShowcaseStep extends StatelessWidget {
  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;

  const _MainMenuShowcaseStep({
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      targetBorderRadius: BorderRadius.circular(8),
      targetPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      overlayColor: EndpointPalette.overlayScrimStrong,
      overlayOpacity: 0.88,
      tooltipBackgroundColor: EndpointPalette.panelBackgroundOpaque,
      tooltipBorderRadius: BorderRadius.circular(12),
      tooltipPadding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      titleTextStyle: textMediumBold.copyWith(
        color: EndpointPalette.infoAccent,
        letterSpacing: 1.1,
      ),
      descTextStyle: textSmallBold.copyWith(
        color: EndpointPalette.softForeground,
        fontSize: 14,
        letterSpacing: 0.4,
        height: 1.25,
      ),
      textColor: EndpointPalette.softForeground,
      disableDefaultTargetGestures: true,
      disableBarrierInteraction: true,
      movingAnimationDuration: Duration.zero,
      child: child,
    );
  }
}

class _MainMenuTinyButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  const _MainMenuTinyButton({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 24,
      child: EndpointActionButton(
        label: label,
        tooltip: tooltip,
        onPressed: onPressed,
        expands: true,
        borderRadius: 8,
        borderWidth: 1.4,
        backgroundColor: EndpointPalette.blend(
          EndpointPalette.menuButtonBackground,
          EndpointPalette.infoAccent,
          0.08,
        ),
        foregroundColor: EndpointPalette.softForeground,
        accent: EndpointPalette.infoAccent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        textStyle: textSmallBold.copyWith(
          fontSize: 12,
          letterSpacing: 1.2,
        ),
        useMarquee: false,
      ),
    );
  }
}

class _MainMenuTutorialPromptDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _MainMenuTutorialPromptDialog({
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: EndpointPanel(
            accent: EndpointPalette.infoAccent,
            backgroundColor: EndpointPalette.panelBackgroundOpaque,
            borderRadius: 18,
            glowOpacity: 0.1,
            blurRadius: 24,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EndpointText(
                  'TUTORIAL',
                  style: textMediumBold.copyWith(
                    color: EndpointPalette.infoAccent,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                EndpointText(
                  '\u00BFQuieres realizar el tutorial?',
                  maxLines: null,
                  style: textMedium.copyWith(
                    color: EndpointPalette.softForeground.withValues(
                      alpha: 0.86,
                    ),
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: EndpointActionButton(
                        label: 'No',
                        onPressed: onCancel,
                        accent: EndpointPalette.primaryAccent,
                        backgroundColor: EndpointPalette.closeButtonBackground,
                        foregroundColor: EndpointPalette.softForeground,
                        height: 42,
                        useMarquee: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: EndpointActionButton(
                        label: 'Si',
                        onPressed: onConfirm,
                        accent: EndpointPalette.infoAccent,
                        backgroundColor: EndpointPalette.blend(
                          EndpointPalette.panelBackground,
                          EndpointPalette.infoAccent,
                          0.28,
                        ),
                        foregroundColor: EndpointPalette.softForegroundWarm,
                        height: 42,
                        useMarquee: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
