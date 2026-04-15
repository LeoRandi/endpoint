import '../_imports.dart';

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
    final topRightBadge = _topRightBadgeForNode(node.type);
    final topColor =
        EndpointPalette.blend(EndpointPalette.panelBackground, accent, 0.18);
    final bottomColor =
        EndpointPalette.blend(EndpointPalette.scaffoldBackground, accent, 0.08);

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
                  color: accent.withValues(
                    alpha: hasSignatureBorder ? 0.92 : 0.7,
                  ),
                  width: hasSignatureBorder ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(
                      alpha: hasSignatureBorder ? 0.2 : 0.14,
                    ),
                    blurRadius: hasSignatureBorder ? 22 : 18,
                    spreadRadius: hasSignatureBorder ? 2 : 1,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  if (hasSignatureBorder) _SignatureNodeFrame(accent: accent),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
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
                          style: textTitleMediumBold.copyWith(
                            color: EndpointPalette.softForeground,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (topRightBadge != null)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: topRightBadge,
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

Widget? _topRightBadgeForNode(PathNodeType type) {
  switch (type) {
    case PathNodeType.encounter:
      return const _PathNodeCornerBadge(
        symbol: '\u2694',
        accent: EndpointPalette.dangerAccent,
      );
    case PathNodeType.shop:
      return const _PathNodeCornerBadge(
        icon: Icons.monetization_on_rounded,
        accent: EndpointPalette.warningAccent,
      );
    case PathNodeType.event:
      return const _PathNodeCornerBadge(
        icon: Icons.question_mark_rounded,
        accent: EndpointPalette.infoAccent,
      );
    case PathNodeType.archetype:
    case PathNodeType.campSite:
      return null;
  }
}

class _PathNodeCornerBadge extends StatelessWidget {
  final IconData? icon;
  final String? symbol;
  final Color accent;

  const _PathNodeCornerBadge({
    this.icon,
    this.symbol,
    required this.accent,
  }) : assert(icon != null || symbol != null);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EndpointPalette.panelBackgroundBattleOpaque,
          shape: BoxShape.circle,
          border: Border.all(
            color: accent.withValues(alpha: 0.92),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.24),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: SizedBox.square(
          dimension: 24,
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    size: 14,
                    color: accent,
                  )
                : EndpointText(
                    symbol!,
                    style: textSmallBold.copyWith(
                      color: accent,
                      fontSize: 12,
                      height: 1,
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
            padding: const EdgeInsets.all(6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accent.withValues(alpha: 0.24),
                  width: 1.2,
                ),
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
      ..color = accent.withValues(alpha: 0.78)
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
