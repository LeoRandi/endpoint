import 'dart:ui' show PathMetric;

import '../_imports.dart';

class PathNodeCard extends StatelessWidget {
  final PathNode node;
  final VoidCallback? onPressed;
  final bool highlightAsDailyBoss;

  const PathNodeCard({
    super.key,
    required this.node,
    this.onPressed,
    this.highlightAsDailyBoss = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = node.accent;
    final tierAccent = node.rarity.accent;
    final imageAsset = node is CombatPathNode
        ? (node as CombatPathNode).enemy.imageAsset
        : null;
    final hasSignatureBorder = node.hasSignatureBorder;
    final topRightBadge = _topRightBadgeForNode(node.type);
    final topColor =
        EndpointPalette.blend(EndpointPalette.panelBackground, accent, 0.18);
    final bottomColor =
        EndpointPalette.blend(EndpointPalette.scaffoldBackground, accent, 0.08);

    final card = HoldTooltip(
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
                  color: tierAccent.withValues(
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
                  if (hasSignatureBorder)
                    _SignatureNodeFrame(accent: tierAccent),
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
                                imageAsset: imageAsset,
                                accent: accent,
                                borderAccent: tierAccent,
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

    final currentNode = node;
    if (!highlightAsDailyBoss || currentNode is! CombatPathNode) {
      return card;
    }

    return _DailyBossNodeAura(
      tier: currentNode.tier,
      child: card,
    );
  }
}

class _DailyBossNodeAura extends StatefulWidget {
  final CombatNodeTier tier;
  final Widget child;

  const _DailyBossNodeAura({
    required this.tier,
    required this.child,
  });

  @override
  State<_DailyBossNodeAura> createState() => _DailyBossNodeAuraState();
}

class _DailyBossNodeAuraState extends State<_DailyBossNodeAura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strength = _bossAuraStrengthForTier(widget.tier);
    final auraOutset = 10 + strength * 18;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              left: -auraOutset,
              top: -auraOutset,
              right: -auraOutset,
              bottom: -auraOutset,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DailyBossNodeAuraPainter(
                    progress: _controller.value,
                    strength: strength,
                    auraOutset: auraOutset,
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
    );
  }
}

class _DailyBossNodeAuraPainter extends CustomPainter {
  final double progress;
  final double strength;
  final double auraOutset;

  const _DailyBossNodeAuraPainter({
    required this.progress,
    required this.strength,
    required this.auraOutset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cardRect = Rect.fromLTWH(
      auraOutset,
      auraOutset,
      max(0.0, size.width - auraOutset * 2),
      max(0.0, size.height - auraOutset * 2),
    );
    if (cardRect.isEmpty) return;

    final cycle = progress * pi * 2;
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var layer = 0; layer < 4; layer++) {
      final wave = (sin(cycle * (1.0 + layer * 0.18) + layer * 1.4) + 1) / 2;
      final inflate = 2.5 +
          strength * 7 +
          layer * (3.8 + strength) +
          wave * (4 + strength * 4);
      final opacity = (0.24 - layer * 0.035) * (0.68 + wave * 0.32);
      final color =
          layer.isEven ? const Color(0xFFFF2B2B) : const Color(0xFFFF8A1F);

      glowPaint
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = 2 + strength * 1.4 + layer * 1.2
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          5 + layer * 3.4 + strength * 4,
        );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          cardRect.inflate(inflate),
          Radius.circular(18 + inflate),
        ),
        glowPaint,
      );
    }

    glowPaint.maskFilter = null;
    final flamePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          cardRect.inflate(2 + strength * 3),
          Radius.circular(20 + strength * 5),
        ),
      );
    final metrics = flamePath.computeMetrics().toList(growable: false);
    final perimeter = metrics.fold<double>(
      0,
      (total, metric) => total + metric.length,
    );
    if (perimeter <= 0) return;

    final flameCount = max(28, (perimeter / (14 - strength * 2)).round());
    final driftDistance = perimeter * 0.18 * progress;
    for (var index = 0; index < flameCount; index++) {
      final distance =
          ((index + 0.5) / flameCount * perimeter + driftDistance) % perimeter;
      final sample = _sampleBorderPath(
        metrics: metrics,
        distance: distance,
        totalLength: perimeter,
      );
      if (sample == null) continue;

      final normal = _outwardNormalFrom(
        sample.position,
        cardRect.center,
      );
      if (normal == Offset.zero) continue;

      final phase = cycle * 1.55 + index * 0.84;
      final wave = (sin(phase) + 1) / 2;
      final height = (5 + strength * 13) * (0.38 + wave * 0.62);
      final drift = cos(phase * 0.7) * (1.6 + strength * 3.2);
      final start = sample.position + normal * (1 + strength * 2);
      final tip = sample.position + normal * height + sample.tangent * drift;
      final control = sample.position +
          normal * (height * 0.48) -
          sample.tangent * (drift * 0.58);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          control.dx,
          control.dy,
          tip.dx,
          tip.dy,
        );

      glowPaint
        ..color = Color.lerp(
          const Color(0xFFFF2B2B),
          const Color(0xFFFFC247),
          wave,
        )!
            .withValues(alpha: 0.24 + strength * 0.16)
        ..strokeWidth = 1.3 + strength * 1.2
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          1.8 + strength * 1.4,
        );
      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DailyBossNodeAuraPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strength != strength ||
        oldDelegate.auraOutset != auraOutset;
  }
}

class _DailyBossAuraPathSample {
  final Offset position;
  final Offset tangent;

  const _DailyBossAuraPathSample({
    required this.position,
    required this.tangent,
  });
}

_DailyBossAuraPathSample? _sampleBorderPath({
  required List<PathMetric> metrics,
  required double distance,
  required double totalLength,
}) {
  if (metrics.isEmpty || totalLength <= 0) return null;

  var remaining = distance % totalLength;
  for (final metric in metrics) {
    if (remaining > metric.length) {
      remaining -= metric.length;
      continue;
    }

    final tangent = metric.getTangentForOffset(
      remaining.clamp(0.0, metric.length).toDouble(),
    );
    if (tangent == null) return null;
    return _DailyBossAuraPathSample(
      position: tangent.position,
      tangent: tangent.vector,
    );
  }

  final lastMetric = metrics.last;
  final tangent = lastMetric.getTangentForOffset(lastMetric.length);
  if (tangent == null) return null;
  return _DailyBossAuraPathSample(
    position: tangent.position,
    tangent: tangent.vector,
  );
}

Offset _outwardNormalFrom(Offset point, Offset center) {
  final delta = point - center;
  final distance = delta.distance;
  if (distance <= 0.001) return Offset.zero;

  return Offset(delta.dx / distance, delta.dy / distance);
}

double _bossAuraStrengthForTier(CombatNodeTier tier) {
  return switch (tier) {
    CombatNodeTier.gray => 0.35,
    CombatNodeTier.green => 0.5,
    CombatNodeTier.blue => 0.72,
    CombatNodeTier.purple => 0.92,
    CombatNodeTier.yellow => 1.12,
  };
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
