import '_imports.dart';

class EndpointHealthBarWithStatuses extends StatelessWidget {
  final Battler battler;
  final double value;
  final Color accent;
  final double height;
  final double badgeSize;
  final double badgeOverlap;
  final WrapAlignment badgeAlignment;
  final Duration healthAnimationDuration;
  final Duration barrierAnimationDuration;
  final int? barrierReferenceValue;

  const EndpointHealthBarWithStatuses({
    super.key,
    required this.battler,
    required this.value,
    required this.accent,
    this.height = 12,
    this.badgeSize = 28,
    this.badgeOverlap = 6,
    this.badgeAlignment = WrapAlignment.start,
    this.healthAnimationDuration = Duration.zero,
    this.barrierAnimationDuration = Duration.zero,
    this.barrierReferenceValue,
  });

  @override
  Widget build(BuildContext context) {
    final hasStatuses = battler.statuses.isNotEmpty;
    final animatedBarrierIsVisible = (barrierReferenceValue ?? 0) > 0;
    final showsBarrier = battler.hasCombatFlag(Battler.combatActiveFlag) &&
        (battler.currentBarrier > 0 || animatedBarrierIsVisible);
    final barrierReference = max(
      1,
      barrierReferenceValue ?? max(battler.maxBarrier, battler.currentBarrier),
    );
    final barrierValue =
        (battler.currentBarrier / barrierReference).clamp(0.0, 1.0).toDouble();
    final barrierHeight = max(5.0, height + 4);
    final barSpacing = showsBarrier ? 4.0 : 0.0;
    final barsHeight =
        height + (showsBarrier ? barrierHeight + barSpacing : 0.0);
    final showBarrierValue = showsBarrier;

    final bars = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showsBarrier) ...[
          SizedBox(
            height: barrierHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: _EndpointShieldBarrierBar(
                    height: barrierHeight,
                    accent: BattlerStat.barrier.accent,
                    value: barrierValue,
                    animationDuration: barrierAnimationDuration,
                  ),
                ),
                if (showBarrierValue)
                  TweenAnimationBuilder<int>(
                    tween: IntTween(end: max(0, battler.currentBarrier)),
                    duration: barrierAnimationDuration,
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedBarrier, _) {
                      return IgnorePointer(
                        child: EndpointText(
                          '$animatedBarrier',
                          style: textSmallNumericBold.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            letterSpacing: 0.6,
                            shadows: [
                              Shadow(
                                color: Colors.black.withAlpha(128),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          SizedBox(height: barSpacing),
        ],
        EndpointHealthBar(
          value: value,
          accent: accent,
          height: height,
          animationDuration: healthAnimationDuration,
        ),
      ],
    );

    if (!hasStatuses) {
      return bars;
    }

    return SizedBox(
      height: barsHeight + badgeSize - badgeOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: bars,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: barsHeight - badgeOverlap,
            child: EndpointStatusBadges(
              battler: battler,
              alignment: badgeAlignment,
              badgeSize: badgeSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _EndpointShieldBarrierBar extends StatelessWidget {
  final double height;
  final Color accent;
  final double value;
  final Duration animationDuration;

  const _EndpointShieldBarrierBar({
    required this.height,
    required this.accent,
    required this.value,
    required this.animationDuration,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(
            clipper: const _EndpointShieldBarClipper(),
            child: ColoredBox(
              color: Colors.black.withAlpha(56),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(1.2),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: value.clamp(0.0, 1.0).toDouble()),
              duration: animationDuration,
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return ClipPath(
                  clipper: const _EndpointShieldBarClipper(),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: animatedValue,
                      child: SizedBox.expand(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                accent.withAlpha(117),
                                accent.withAlpha(245),
                                accent.withAlpha(117),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 3),
            child: ClipPath(
              clipper: const _EndpointShieldBarClipper(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withAlpha(64),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _EndpointShieldBarStrokePainter(accent: accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndpointShieldBarClipper extends CustomClipper<Path> {
  const _EndpointShieldBarClipper();

  @override
  Path getClip(Size size) {
    return _buildShieldBarPath(size);
  }

  @override
  bool shouldReclip(covariant _EndpointShieldBarClipper oldClipper) {
    return false;
  }
}

class _EndpointShieldBarStrokePainter extends CustomPainter {
  final Color accent;

  const _EndpointShieldBarStrokePainter({
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = accent.withAlpha(179);

    canvas.drawPath(_buildShieldBarPath(size), strokePaint);
  }

  @override
  bool shouldRepaint(covariant _EndpointShieldBarStrokePainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

Path _buildShieldBarPath(Size size) {
  final width = max(0.0, size.width);
  final height = max(0.0, size.height);
  if (width <= 0 || height <= 0) {
    return Path();
  }

  final path = Path()
    ..moveTo(0, height * 0.5)
    ..quadraticBezierTo(width * 0.16, 0, width * 0.5, height * 0.08)
    ..quadraticBezierTo(width * 0.84, 0, width, height * 0.5)
    ..quadraticBezierTo(width * 0.84, height, width * 0.5, height * 0.92)
    ..quadraticBezierTo(width * 0.16, height, 0, height * 0.5)
    ..close();

  return path;
}

class EndpointStatusBadges extends StatelessWidget {
  final Battler battler;
  final WrapAlignment alignment;
  final double badgeSize;
  final double spacing;

  const EndpointStatusBadges({
    super.key,
    required this.battler,
    this.alignment = WrapAlignment.start,
    this.badgeSize = 28,
    this.spacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (battler.statuses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: alignment,
      children: [
        for (final status in battler.statuses)
          _EndpointStatusBadge(
            battler: battler,
            status: status,
            size: badgeSize,
          ),
      ],
    );
  }
}

class _EndpointStatusBadge extends StatelessWidget {
  final Battler battler;
  final BattlerStatus status;
  final double size;

  const _EndpointStatusBadge({
    required this.battler,
    required this.status,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final accent = status.hasTag(EntityTag.desafio)
        ? EntityTag.desafio.accent
        : status.type.accent;
    final foreground = status.hasTag(EntityTag.desafio)
        ? EndpointPalette.soften(accent)
        : status.type.foreground;
    final badgeLabel = status.badgeLabelFor(battler);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showStatusDetails(context),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EndpointPalette.panelBackground,
                    border: Border.all(
                      color: accent.withAlpha(224),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withAlpha(41),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      status.icon,
                      size: size * 0.56,
                      color: foreground,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: EndpointPalette.scaffoldBackground),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: EndpointText(
                      badgeLabel,
                      style: textSmallBold.copyWith(
                        color: EndpointPalette.scaffoldBackground,
                        fontSize: 8,
                        letterSpacing: 0.2,
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

  Future<void> _showStatusDetails(BuildContext context) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de estado',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return _EndpointStatusDetailsDialog(
          battler: battler,
          status: status,
        );
      },
    );
  }
}

class _EndpointStatusDetailsDialog extends StatelessWidget {
  final Battler battler;
  final BattlerStatus status;

  const _EndpointStatusDetailsDialog({
    required this.battler,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final accent = status.hasTag(EntityTag.desafio)
        ? EntityTag.desafio.accent
        : status.type.accent;
    final foreground = status.hasTag(EntityTag.desafio)
        ? EndpointPalette.soften(accent)
        : status.type.foreground;
    final screenSize = MediaQuery.sizeOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: min(380, screenSize.width - 48),
            maxHeight: screenSize.height * 0.72,
          ),
          child: EndpointPanel(
            accent: accent,
            backgroundColor: EndpointPalette.panelBackgroundOpaque,
            borderRadius: 18,
            glowOpacity: 0.05,
            padding: EdgeInsets.zero,
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withAlpha(41),
                        border: Border.all(color: accent.withAlpha(179)),
                      ),
                      child: Icon(
                        status.icon,
                        size: 28,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    EndpointText(
                      status.name,
                      textAlign: TextAlign.center,
                      maxLines: null,
                      style: textTitleMediumBold.copyWith(
                        color: EndpointPalette.softForeground,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    EndpointText(
                      status.type.label.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: null,
                      style: textSmallBold.copyWith(
                        color: accent,
                        fontSize: 12,
                        letterSpacing: 1.4,
                      ),
                    ),
                    if (status.hasTags) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: EndpointTagPillMarquee(
                          tags: status.tags,
                          accent: accent,
                          idleAlignment: Alignment.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    EndpointHighlightedValueText(
                      status.descriptionFor(battler),
                      tags: status.tags,
                      textAlign: TextAlign.center,
                      maxLines: null,
                      style: textMedium.copyWith(
                        color: EndpointPalette.softForeground.withAlpha(219),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    EndpointText(
                      'Duracion restante: ${status.remainingTurnsLabel}',
                      textAlign: TextAlign.center,
                      maxLines: null,
                      style: textSmallBold.copyWith(
                        color: accent,
                        fontSize: 12,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
