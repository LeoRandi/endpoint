import '_imports.dart';

class PathNodeCard extends StatelessWidget {
  final PathNode node;
  final VoidCallback? onPressed;

  const PathNodeCard({
    super.key,
    required this.node,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = node.accent;
    final hasSignatureBorder = node.hasSignatureBorder;
    final topColor = Color.lerp(const Color(0xFF09100C), accent, 0.18) ??
        const Color(0xFF112016);
    final bottomColor = Color.lerp(const Color(0xFF040705), accent, 0.08) ??
        const Color(0xFF09100C);

    return HoldTooltip(
      message: node.tooltip,
      child: Material(
        color: Colors.transparent,
        child: AspectRatio(
          aspectRatio: 0.76,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    topColor,
                    bottomColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: accent.withOpacity(hasSignatureBorder ? 0.92 : 0.7),
                  width: hasSignatureBorder ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(hasSignatureBorder ? 0.2 : 0.14),
                    blurRadius: hasSignatureBorder ? 22 : 18,
                    spreadRadius: hasSignatureBorder ? 2 : 1,
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasSignatureBorder) _SignatureNodeFrame(accent: accent),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: accent.withOpacity(0.5)),
                          ),
                          child: EndpointText(
                            node.badgeLabel,
                            style: textSmallBold.copyWith(
                              color: accent,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Center(
                              child: EndpointEmojiSprite(
                                emoji: node.iconEmoji,
                                accent: accent,
                                size: 68,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        EndpointMarqueeText(
                          node.label,
                          textAlign: TextAlign.center,
                          style: textMediumBold.copyWith(
                            color: const Color(0xFFE6FFF0),
                            letterSpacing: 1.2,
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
    );
  }
}

class _SignatureNodeFrame extends StatelessWidget {
  final Color accent;

  const _SignatureNodeFrame({
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withOpacity(0.24), width: 1.2),
              ),
            ),
          ),
          _SignatureCorner(
            alignment: Alignment.topLeft,
            accent: accent,
          ),
          _SignatureCorner(
            alignment: Alignment.topRight,
            accent: accent,
            mirrorHorizontally: true,
          ),
          _SignatureCorner(
            alignment: Alignment.bottomLeft,
            accent: accent,
            mirrorVertically: true,
          ),
          _SignatureCorner(
            alignment: Alignment.bottomRight,
            accent: accent,
            mirrorHorizontally: true,
            mirrorVertically: true,
          ),
        ],
      ),
    );
  }
}

class _SignatureCorner extends StatelessWidget {
  final Alignment alignment;
  final Color accent;
  final bool mirrorHorizontally;
  final bool mirrorVertically;

  const _SignatureCorner({
    required this.alignment,
    required this.accent,
    this.mirrorHorizontally = false,
    this.mirrorVertically = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Transform.flip(
          flipX: mirrorHorizontally,
          flipY: mirrorVertically,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CustomPaint(
              painter: _SignatureCornerPainter(accent),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignatureCornerPainter extends CustomPainter {
  final Color accent;

  const _SignatureCornerPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withOpacity(0.78)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, 0)
      ..lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignatureCornerPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
