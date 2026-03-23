import '_imports.dart';

class CampSitePage extends StatefulWidget {
  final Battler player;
  final CampSiteService recoveryService;

  const CampSitePage({
    super.key,
    required this.player,
    this.recoveryService = const CampSiteService(),
  });

  @override
  State<CampSitePage> createState() => _CampSitePageState();
}

class _CampSitePageState extends State<CampSitePage> {
  late final CampSiteVisitResult _visitResult;

  @override
  void initState() {
    super.initState();
    _visitResult = widget.recoveryService.recover(widget.player);
  }

  void _closeCamp() {
    Navigator.of(context).pop(_visitResult);
  }

  Future<bool> _handleWillPop() async {
    _closeCamp();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        body: NodeSceneWrapper(
          showTitle: 'Has encontrado una zona de acampada',
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF061008),
                  Color(0xFF0B1510),
                  Color(0xFF020403),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _CampBackdrop(),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: HoldTooltip(
                            message: 'Volver a la ruta',
                            child: IconButton(
                              onPressed: _closeCamp,
                              style: IconButton.styleFrom(
                                foregroundColor: const Color(0xFFE6FFF0),
                                backgroundColor: const Color(0xFF102519),
                                side: const BorderSide(color: Color(0xFF5AF78E)),
                              ),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const EndpointEmojiSprite(
                          emoji: '\u{26FA}',
                          accent: Color(0xFF5AF78E),
                          size: 144,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'ZONA DE ACAMPADA',
                          textAlign: TextAlign.center,
                          style: textLargeBold.copyWith(
                            color: const Color(0xFFD6FFE5),
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Recuperas 50% de tu vida maxima.',
                          textAlign: TextAlign.center,
                          style: textMedium.copyWith(
                            color: Colors.white.withOpacity(0.84),
                          ),
                        ),
                        const SizedBox(height: 18),
                        EndpointPanel(
                          backgroundColor: const Color(0xCC07120D),
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          child: Column(
                            children: [
                              Text(
                                '${widget.player.health} / ${widget.player.maxHealth}  ->  ${_visitResult.player.health} / ${_visitResult.player.maxHealth}',
                                textAlign: TextAlign.center,
                                style: textMediumBold.copyWith(
                                  color: const Color(0xFF5AF78E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _visitResult.healedAmount > 0
                                    ? 'Salud recuperada: +${_visitResult.healedAmount}'
                                    : 'Tu salud ya estaba al maximo.',
                                textAlign: TextAlign.center,
                                style: textMedium.copyWith(
                                  color: Colors.white.withOpacity(0.76),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CampBackdrop extends StatelessWidget {
  const _CampBackdrop();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _CampBackdropPainter(),
      ),
    );
  }
}

class _CampBackdropPainter extends CustomPainter {
  const _CampBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x115AF78E)
      ..strokeWidth = 1;
    final ringPaint = Paint()
      ..color = const Color(0x1A5AF78E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (double y = 24; y <= size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radii = [
      size.width * 0.14,
      size.width * 0.22,
      size.width * 0.3,
    ];

    for (final radius in radii) {
      canvas.drawCircle(center, radius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
