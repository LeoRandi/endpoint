import '_imports.dart';

class CampSitePage extends StatefulWidget {
  final Battler player;
  final CampSiteService recoveryService;
  final RunRandomizer? randomizer;
  final String showTitle;
  final String sceneTitle;
  final String description;
  final String iconEmoji;
  final Color accent;

  const CampSitePage({
    super.key,
    required this.player,
    this.recoveryService = const CampSiteService(),
    this.randomizer,
    this.showTitle = 'Has encontrado una zona de descanso',
    this.sceneTitle = 'ZONA DE DESCANSO',
    this.description = 'Recuperas toda tu vida.',
    this.iconEmoji = '\u{1F6CF}',
    this.accent = EndpointPalette.primaryAccent,
  });

  @override
  State<CampSitePage> createState() => _CampSitePageState();
}

class _CampSitePageState extends State<CampSitePage> {
  late final CampSiteVisitResult _visitResult;

  @override
  void initState() {
    super.initState();
    _visitResult = widget.recoveryService.recover(
      widget.player,
      randomizer: widget.randomizer,
    );
  }

  void _closeCamp() {
    Navigator.of(context).pop(_visitResult);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _closeCamp();
      },
      child: EndpointCenterStageScene(
        showTitle: widget.showTitle,
        background: EndpointGradients.camp,
        backdrop: const _CampBackdrop(),
        onClose: _closeCamp,
        closeTooltip: EndpointStrings.backToRoute,
        accent: widget.accent,
        emoji: widget.iconEmoji,
        emojiSize: 144,
        title: widget.sceneTitle,
        titleColor: EndpointPalette.soften(widget.accent, amount: 0.24),
        content: Column(
          children: [
            EndpointText(
              widget.description,
              textAlign: TextAlign.center,
              maxLines: null,
              style: textMedium.copyWith(
                color: EndpointPalette.softForeground.withValues(alpha: 0.84),
              ),
            ),
            const SizedBox(height: 12),
            EndpointPanel(
              backgroundColor: EndpointPalette.panelBackgroundSoft,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                children: [
                  EndpointText(
                    '${widget.player.health} / ${widget.player.maxHealth}  ->  ${_visitResult.player.health} / ${_visitResult.player.maxHealth}',
                    textAlign: TextAlign.center,
                    style: textMediumNumericBold.copyWith(
                      color: EndpointPalette.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  EndpointText(
                    _visitResult.healedAmount > 0
                        ? 'Salud recuperada: +${_visitResult.healedAmount}'
                        : 'Tu salud ya estaba al maximo.',
                    textAlign: TextAlign.center,
                    maxLines: null,
                    style: textMedium.copyWith(
                      color:
                          EndpointPalette.softForeground.withValues(alpha: 0.76),
                    ),
                  ),
                  if (widget.recoveryService.removeRandomDebuff) ...[
                    const SizedBox(height: 8),
                    EndpointText(
                      _visitResult.removedDebuff != null
                          ? 'Debuff eliminado: ${_visitResult.removedDebuff!.name}'
                          : 'No habia debuffs activos que purgar.',
                      textAlign: TextAlign.center,
                      maxLines: null,
                      style: textMedium.copyWith(
                        color: EndpointPalette.softForeground
                            .withValues(alpha: 0.76),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
      ..color = EndpointPalette.primaryAccent.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    final ringPaint = Paint()
      ..color = EndpointPalette.primaryAccent.withValues(alpha: 0.1)
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
