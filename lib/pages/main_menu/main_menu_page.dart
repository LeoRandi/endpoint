import '_imports.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    const accent = EndpointPalette.primaryAccent;
    const surface = EndpointPalette.panelBackground;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF040A07),
              Color(0xFF0A1710),
              Color(0xFF020403),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _MenuBackdrop(),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: EndpointPanel(
                      accent: accent,
                      backgroundColor: surface.withOpacity(0.72),
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
                                  textAlign: TextAlign.center,
                                  style: textExtraLargeBold.copyWith(
                                    fontSize: 42,
                                    letterSpacing: 3.2,
                                    color: Color.lerp(
                                      const Color(0xFFD6FFE5),
                                      accent,
                                      _glow.value,
                                    ),
                                    shadows: [
                                      Shadow(
                                        color: accent.withOpacity(
                                          0.35 + (_glow.value * 0.25),
                                        ),
                                        blurRadius: 12 + (_glow.value * 18),
                                      ),
                                      Shadow(
                                        color: Colors.white.withOpacity(
                                          0.12 + (_glow.value * 0.16),
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
                          EndpointMenuButton(
                            label: EndpointStrings.start,
                            tooltip: 'Iniciar la carrera hasta el sunrise',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PathSelectionPage(),
                                ),
                              );
                            },
                          ),
                          const SeparatorFiori.half(),
                          const EndpointMenuButton(
                            label: EndpointStrings.codex,
                            tooltip: EndpointStrings.codexUnavailable,
                          ),
                          const SeparatorFiori.half(),
                          const EndpointMenuButton(
                            label: EndpointStrings.settings,
                            tooltip: EndpointStrings.settingsUnavailable,
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x225AF78E),
                  Color(0x00030807),
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x1822A36A),
                  Color(0x00030807),
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
    const scanlineColor = Color(0x0819FF8B);
    const gridColor = Color(0x105AF78E);
    const scanlineStep = 24.0;
    const gridStep = 48.0;

    final scanlinePaint = Paint()
      ..color = scanlineColor
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = gridColor
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
