import '_imports.dart';

class EndpointAugmentDetailsDialog extends StatelessWidget {
  final Augment augment;
  final Color? accent;
  final String? statusText;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onPrimaryAction;
  final bool isActionEnabled;
  final String enabledActionTooltip;
  final String disabledActionTooltip;
  final bool showPrimaryActionUpgradeIndicator;
  final Color? primaryActionUpgradeIndicatorColor;

  const EndpointAugmentDetailsDialog({
    super.key,
    required this.augment,
    this.accent,
    this.statusText,
    this.actionLabel,
    this.actionIcon = Icons.check_rounded,
    this.onPrimaryAction,
    this.isActionEnabled = false,
    this.enabledActionTooltip = '',
    this.disabledActionTooltip = '',
    this.showPrimaryActionUpgradeIndicator = false,
    this.primaryActionUpgradeIndicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accent ?? augment.accent;
    final foreground = EndpointPalette.soften(resolvedAccent);

    return EndpointDetailsDialogScaffold(
      accent: resolvedAccent,
      backgroundColor: EndpointPalette.panelBackgroundGold,
      foregroundColor: foreground,
      closeBackgroundColor: EndpointPalette.blend(
        EndpointPalette.panelBackgroundGold,
        resolvedAccent,
        0.08,
      ),
      maxWidth: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AugmentHeader(
            augment: augment,
            accent: resolvedAccent,
            foreground: foreground,
          ),
          const SizedBox(height: 14),
          EndpointHighlightedValueText(
            augment.displayDescription,
            tags: augment.tags,
            maxLines: null,
            style: textMedium.copyWith(
              color: EndpointPalette.softForeground.withValues(alpha: 0.84),
              fontSize: 13,
              height: 1.32,
            ),
          ),
          const SizedBox(height: 14),
          _AugmentTierEffectList(
            augment: augment,
            accent: resolvedAccent,
          ),
          if (statusText != null && statusText!.isNotEmpty) ...[
            const SizedBox(height: 14),
            EndpointHighlightedValueText(
              statusText!,
              tags: augment.tags,
              maxLines: null,
              style: textSmallBold.copyWith(
                color: resolvedAccent,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: EndpointActionButton(
                label: actionLabel!,
                icon: actionIcon,
                onPressed: isActionEnabled ? onPrimaryAction : null,
                tooltip: isActionEnabled
                    ? enabledActionTooltip
                    : disabledActionTooltip,
                accent: resolvedAccent,
                backgroundColor: EndpointPalette.blend(
                  EndpointPalette.panelBackgroundGold,
                  resolvedAccent,
                  0.16,
                ),
                foregroundColor: foreground,
                borderWidth: 1.3,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                textStyle: textMediumBold.copyWith(letterSpacing: 1.2),
                showUpgradeIndicator: showPrimaryActionUpgradeIndicator,
                upgradeIndicatorColor: primaryActionUpgradeIndicatorColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AugmentHeader extends StatelessWidget {
  final Augment augment;
  final Color accent;
  final Color foreground;

  const _AugmentHeader({
    required this.augment,
    required this.accent,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EndpointEmojiSprite(
          emoji: '',
          imageAsset: augment.assetPath,
          accent: accent,
          size: 92,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EndpointText(
                augment.displayName,
                maxLines: null,
                style: textLargeBold.copyWith(
                  color: foreground,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withValues(alpha: 0.8),
                            accent.withValues(alpha: 0.12),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AugmentAffinityBadge(affinity: augment.affinity),
                ],
              ),
              const SizedBox(height: 8),
              if (augment.hasTags)
                SizedBox(
                  width: double.infinity,
                  child: EndpointTagPillMarquee(
                    tags: augment.tags,
                    accent: accent,
                  ),
                )
              else
                EndpointText(
                  'SIN TAGS',
                  style: textSmallBold.copyWith(
                    color: EndpointPalette.softForeground.withValues(
                      alpha: 0.38,
                    ),
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AugmentAffinityBadge extends StatelessWidget {
  final AugmentAffinity affinity;

  const _AugmentAffinityBadge({
    required this.affinity,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: affinity.label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: EndpointPalette.blend(
            EndpointPalette.panelBackgroundGold,
            affinity.accent,
            0.18,
          ),
          border: Border.all(
            color: affinity.accent.withValues(alpha: 0.72),
          ),
        ),
        child: SizedBox.square(
          dimension: 30,
          child: Icon(
            affinity.icon,
            color: EndpointPalette.soften(affinity.accent),
            size: 17,
          ),
        ),
      ),
    );
  }
}

class _AugmentTierEffectList extends StatelessWidget {
  final Augment augment;
  final Color accent;

  const _AugmentTierEffectList({
    required this.augment,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final entries = augment.effects.patternEffects.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          _AugmentTierEffectGroup(
            tier: RarityTier.values[index],
            tags: augment.tags,
            points: entries[index].key,
            effect: entries[index].value,
            accent: accent,
            initiallyExpanded: index == augment.rarity.index,
          ),
        ],
      ],
    );
  }
}

class _AugmentTierEffectGroup extends StatefulWidget {
  final RarityTier tier;
  final Iterable<EntityTag> tags;
  final List<OperativePatternPoint> points;
  final AugmentEffect effect;
  final Color accent;
  final bool initiallyExpanded;

  const _AugmentTierEffectGroup({
    required this.tier,
    required this.tags,
    required this.points,
    required this.effect,
    required this.accent,
    required this.initiallyExpanded,
  });

  @override
  State<_AugmentTierEffectGroup> createState() =>
      _AugmentTierEffectGroupState();
}

class _AugmentTierEffectGroupState extends State<_AugmentTierEffectGroup> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final tierAccent = widget.tier.accent;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: EndpointPalette.blend(
            EndpointPalette.panelBackgroundGold,
            tierAccent,
            0.07,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tierAccent.withValues(alpha: 0.38),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: tierAccent, size: 17),
                    const SizedBox(width: 7),
                    Expanded(
                      child: EndpointText(
                        widget.tier.label,
                        style: textSmallBold.copyWith(
                          color: tierAccent,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    EndpointText(
                      '${widget.points.length} PUNTOS',
                      style: textSmallNumericBold.copyWith(
                        color: tierAccent,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: tierAccent,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(11, 2, 11, 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _AugmentPatternMatrix(
                      points: widget.points,
                      accent: tierAccent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EndpointHighlightedValueText(
                        widget.effect.description,
                        tags: widget.tags,
                        maxLines: null,
                        style: textMediumBold.copyWith(
                          color: tierAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

class _AugmentPatternMatrix extends StatefulWidget {
  final List<OperativePatternPoint> points;
  final Color accent;

  const _AugmentPatternMatrix({
    required this.points,
    required this.accent,
  });

  @override
  State<_AugmentPatternMatrix> createState() => _AugmentPatternMatrixState();
}

class _AugmentPatternMatrixState extends State<_AugmentPatternMatrix> {
  static const _pointStepDuration = Duration(milliseconds: 260);
  static const _completedHoldDuration = Duration(seconds: 2);
  static const _clearedHoldDuration = Duration(milliseconds: 180);

  Timer? _timer;
  int _visiblePointCount = 0;

  @override
  void initState() {
    super.initState();
    _scheduleNextStep(_clearedHoldDuration);
  }

  @override
  void didUpdateWidget(covariant _AugmentPatternMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points == widget.points &&
        oldWidget.accent == widget.accent) {
      return;
    }

    _timer?.cancel();
    _visiblePointCount = 0;
    _scheduleNextStep(_clearedHoldDuration);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNextStep(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _advanceAnimation);
  }

  void _advanceAnimation() {
    if (!mounted) return;

    if (widget.points.isEmpty) return;
    if (_visiblePointCount >= widget.points.length) {
      setState(() {
        _visiblePointCount = 0;
      });
      _scheduleNextStep(_clearedHoldDuration);
      return;
    }

    setState(() {
      _visiblePointCount++;
    });
    _scheduleNextStep(
      _visiblePointCount >= widget.points.length
          ? _completedHoldDuration
          : _pointStepDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AugmentPatternMiniMatrix(
      visiblePath: widget.points.take(_visiblePointCount).toList(
            growable: false,
          ),
      fullPath: widget.points,
      accent: widget.accent,
    );
  }
}

class _AugmentPatternMiniMatrix extends StatelessWidget {
  final List<OperativePatternPoint> visiblePath;
  final List<OperativePatternPoint> fullPath;
  final Color accent;

  const _AugmentPatternMiniMatrix({
    required this.visiblePath,
    required this.fullPath,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    const matrixSize = 100.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.panelBackgroundOpaque.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withValues(alpha: 0.34),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
        child: SizedBox(
          width: matrixSize,
          height: matrixSize,
          child: Center(
            child: Transform.rotate(
              angle: pi / 4,
              child: SizedBox.square(
                dimension: matrixSize / sqrt2,
                child: CustomPaint(
                  painter: _AugmentPatternMiniMatrixPainter(
                    visiblePath: visiblePath,
                    fullPath: fullPath,
                    accent: accent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AugmentPatternMiniMatrixPainter extends CustomPainter {
  final List<OperativePatternPoint> visiblePath;
  final List<OperativePatternPoint> fullPath;
  final Color accent;

  const _AugmentPatternMiniMatrixPainter({
    required this.visiblePath,
    required this.fullPath,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullKeys = fullPath.map((point) => point.key).toSet();
    final visibleKeys = visiblePath.map((point) => point.key).toSet();
    final lineOffsets = visiblePath.map((point) {
      return _centerFor(point, size);
    }).toList(growable: false);
    _drawPath(canvas, lineOffsets);

    for (final point in operativePatternPoints) {
      final center = _centerFor(point, size);
      final isInPattern = fullKeys.contains(point.key);
      final isVisible = visibleKeys.contains(point.key);
      final ringPaint = Paint()
        ..color = isVisible
            ? accent.withValues(alpha: 0.9)
            : isInPattern
                ? accent.withValues(alpha: 0.32)
                : EndpointPalette.softForeground.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isVisible
            ? 1.8
            : isInPattern
                ? 1.35
                : 1.1;
      final fillPaint = Paint()
        ..color = isVisible
            ? accent.withValues(alpha: 0.26)
            : isInPattern
                ? accent.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, isVisible ? 6.2 : 5.8, fillPaint);
      canvas.drawCircle(center, isVisible ? 6.2 : 5.8, ringPaint);
      if (isVisible) {
        canvas.drawCircle(
          center,
          2.2,
          Paint()
            ..color = EndpointPalette.softForeground.withValues(alpha: 0.82),
        );
      }
    }
  }

  void _drawPath(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final corePaint = Paint()
      ..color = EndpointPalette.softForeground.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, corePaint);
  }

  Offset _centerFor(OperativePatternPoint point, Size size) {
    final usableWidth = max(1.0, size.width - 16);
    final usableHeight = max(1.0, size.height - 16);
    final column = point.x + 1;
    final row = 1 - point.y;
    final x = 8 + (column / 2) * usableWidth;
    final y = 8 + (row / 2) * usableHeight;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(
    covariant _AugmentPatternMiniMatrixPainter oldDelegate,
  ) {
    return oldDelegate.visiblePath != visiblePath ||
        oldDelegate.fullPath != fullPath ||
        oldDelegate.accent != accent;
  }
}
