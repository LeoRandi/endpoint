import '../_imports.dart';
import '../../services/_exports.dart';

const _itemBonusSketchCanvasBorderRadius = 18.0;
const _itemBonusSketchNoiseSeed = 2174;

class EndpointItemDetailsDialog extends StatefulWidget {
  final Item item;
  final Color accent;
  final int price;
  final String priceLabel;
  final String statusText;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onPrimaryAction;
  final bool isActionEnabled;
  final String enabledActionTooltip;
  final String disabledActionTooltip;
  final bool showPrimaryActionUpgradeIndicator;
  final Color? primaryActionUpgradeIndicatorColor;
  final String? secondaryActionLabel;
  final IconData secondaryActionIcon;
  final VoidCallback? onSecondaryAction;
  final bool isSecondaryActionEnabled;
  final String enabledSecondaryActionTooltip;
  final String disabledSecondaryActionTooltip;

  const EndpointItemDetailsDialog({
    super.key,
    required this.item,
    required this.accent,
    required this.price,
    this.priceLabel = 'PRECIO',
    required this.statusText,
    this.actionLabel,
    this.actionIcon = Icons.shopping_bag_outlined,
    this.onPrimaryAction,
    this.isActionEnabled = false,
    this.enabledActionTooltip = '',
    this.disabledActionTooltip = '',
    this.showPrimaryActionUpgradeIndicator = false,
    this.primaryActionUpgradeIndicatorColor,
    this.secondaryActionLabel,
    this.secondaryActionIcon = Icons.swap_vert_rounded,
    this.onSecondaryAction,
    this.isSecondaryActionEnabled = false,
    this.enabledSecondaryActionTooltip = '',
    this.disabledSecondaryActionTooltip = '',
  });

  @override
  State<EndpointItemDetailsDialog> createState() =>
      _EndpointItemDetailsDialogState();
}

class _EndpointItemDetailsDialogState extends State<EndpointItemDetailsDialog> {
  late final List<_ItemBonusSketchNoiseDot> _noiseDots =
      _buildItemBonusSketchNoiseDots();
  EndpointGameMode _gameMode = EndpointGameMode.classic;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final settings = await EndpointPreferencesService.loadSettingsSnapshot();
    if (!mounted) return;

    setState(() {
      _gameMode = settings.gameMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final foreground = EndpointPalette.soften(widget.accent);
    final statusSurface = EndpointPalette.blend(
      EndpointPalette.panelBackgroundGold,
      widget.accent,
      0.16,
    );
    final secondaryActionSurface = EndpointPalette.blend(
      EndpointPalette.panelBackground,
      widget.accent,
      0.08,
    );
    final shouldShowBonusSketch =
        _gameMode == EndpointGameMode.drawing && widget.item.hasDrawingBonus;

    return EndpointDetailsDialogScaffold(
      accent: widget.accent,
      backgroundColor: EndpointPalette.panelBackgroundGold,
      foregroundColor: foreground,
      closeBackgroundColor: EndpointPalette.blend(
        EndpointPalette.panelBackgroundGold,
        widget.accent,
        0.08,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EndpointEmojiSprite(
                emoji: widget.item.iconEmoji,
                accent: widget.accent,
                size: 72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EndpointText(
                      widget.item.displayName,
                      maxLines: null,
                      style: textLargeBold.copyWith(
                        color: foreground,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        EndpointText(
                          '${widget.item.rarity.label}  |  TAMAÑO ${widget.item.equipmentCost}',
                          maxLines: null,
                          style: textSmallBold.copyWith(
                            fontSize: 10,
                            color: widget.accent,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        EndpointText(
                          widget.priceLabel,
                          style: textSmallBold.copyWith(
                            fontSize: 10,
                            color: EndpointPalette.warningAccent,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const Spacer(),
                        EndpointCurrencyInline(
                          value: widget.price,
                          iconColor: EndpointPalette.warningAccent,
                          textColor: EndpointPalette.softForegroundWarm,
                          iconSize: 13,
                          spacing: 3,
                          textStyle: textSmallNumericBold.copyWith(
                            fontSize: 11,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    if (widget.item.hasTags) ...[
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: EndpointTagPillMarquee(
                          tags: widget.item.tags,
                          accent: widget.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EndpointHighlightedValueText(
            widget.item.displayDescription,
            tags: widget.item.tags,
            maxLines: null,
            style: textMedium.copyWith(
              fontSize: 14,
              color: EndpointPalette.softForeground.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: 12),
          EndpointText(
            _buildModifiersText(widget.item),
            maxLines: null,
            style: textSmallNumericBold.copyWith(
              fontSize: 10,
              color: widget.accent,
              letterSpacing: 1,
            ),
          ),
          if (shouldShowBonusSketch) ...[
            const SizedBox(height: 12),
            _ItemBonusSketchSection(
              item: widget.item,
              noiseDots: _noiseDots,
            ),
          ],
          if (widget.actionLabel != null ||
              widget.secondaryActionLabel != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (widget.secondaryActionLabel != null)
                    EndpointActionButton(
                      label: widget.secondaryActionLabel!,
                      icon: widget.secondaryActionIcon,
                      onPressed: widget.isSecondaryActionEnabled
                          ? widget.onSecondaryAction
                          : null,
                      tooltip: widget.isSecondaryActionEnabled
                          ? widget.enabledSecondaryActionTooltip
                          : widget.disabledSecondaryActionTooltip,
                      accent: widget.accent,
                      backgroundColor: secondaryActionSurface,
                      foregroundColor: foreground,
                      borderWidth: 1.2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      textStyle: textSmallBold.copyWith(letterSpacing: 1.1),
                      iconSize: 18,
                      useMarquee: false,
                      width: widget.actionLabel != null ? 118 : null,
                    ),
                  if (widget.actionLabel != null)
                    EndpointActionButton(
                      label: widget.actionLabel!,
                      icon: widget.actionIcon,
                      onPressed: widget.isActionEnabled
                          ? widget.onPrimaryAction
                          : null,
                      tooltip: widget.isActionEnabled
                          ? widget.enabledActionTooltip
                          : widget.disabledActionTooltip,
                      accent: widget.accent,
                      backgroundColor: statusSurface,
                      foregroundColor: foreground,
                      borderWidth: 1.3,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      textStyle: textMediumBold.copyWith(letterSpacing: 1.2),
                      showUpgradeIndicator:
                          widget.showPrimaryActionUpgradeIndicator,
                      upgradeIndicatorColor:
                          widget.primaryActionUpgradeIndicatorColor,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildModifiersText(Item item) {
    final entries = <String>[
      ...item.statModifiers.entries.map((entry) {
        final value = entry.value;
        final sign = value >= 0 ? '+' : '';
        return '$sign$value ${_modifierLabel(entry.key)}';
      }),
    ];

    if (item.incomeModifier != 0) {
      final sign = item.incomeModifier >= 0 ? '+' : '';
      entries.add('$sign${item.incomeModifier} INCOME');
    }

    if (item.maxHealthPercentModifier != 0) {
      final sign = item.maxHealthPercentModifier >= 0 ? '+' : '';
      entries.add('$sign${item.maxHealthPercentModifier}% HP MAX');
    }

    if (entries.isEmpty) return 'Sin modificadores directos.';

    return entries.join('   ');
  }

  String _modifierLabel(BattlerStat stat) {
    if (stat == BattlerStat.barrier) {
      return stat.label;
    }

    return stat.shortLabel;
  }
}

class _ItemBonusSketchSection extends StatelessWidget {
  final Item item;
  final List<_ItemBonusSketchNoiseDot> noiseDots;

  const _ItemBonusSketchSection({
    required this.item,
    required this.noiseDots,
  });

  @override
  Widget build(BuildContext context) {
    final shape = item.drawingBonusShape;
    if (shape == null) {
      return const SizedBox.shrink();
    }
    final shapeAccent = _shapeAccent(shape);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            EndpointText(
              'TRAZO BONUS',
              style: textSmallBold.copyWith(
                color: EndpointPalette.infoAccent.withValues(alpha: 0.92),
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            EndpointText(
              shape.label.toUpperCase(),
              style: textSmallBold.copyWith(
                color: shapeAccent,
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox.square(
            dimension: 132,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(_itemBonusSketchCanvasBorderRadius),
                border: Border.all(
                  color: EndpointPalette.softForeground.withValues(alpha: 0.76),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: EndpointPalette.infoAccent.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  _itemBonusSketchCanvasBorderRadius - 1,
                ),
                child: CustomPaint(
                  painter: _ItemBonusSketchPainter(
                    shape: shape,
                    strokeColor: shapeAccent,
                    noiseDots: noiseDots,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _shapeAccent(ItemBonusShape shape) {
    switch (shape) {
      case ItemBonusShape.triangle:
        return EndpointPalette.warningAccent;
      case ItemBonusShape.square:
        return EndpointPalette.infoAccent;
      case ItemBonusShape.circle:
        return EndpointPalette.primaryAccent;
    }
  }
}

class _ItemBonusSketchPainter extends CustomPainter {
  final ItemBonusShape shape;
  final Color strokeColor;
  final List<_ItemBonusSketchNoiseDot> noiseDots;

  const _ItemBonusSketchPainter({
    required this.shape,
    required this.strokeColor,
    required this.noiseDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF030706),
          Color(0xFF0B1210),
          Color(0xFF050907),
        ],
      ).createShader(rect);
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.1, -0.2),
        radius: 1.15,
        colors: [
          EndpointPalette.infoAccent.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(rect);
    final gridPaint = Paint()
      ..color = EndpointPalette.softForeground.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    canvas.drawRect(rect, backgroundPaint);
    canvas.drawRect(rect, vignettePaint);

    for (double y = 12; y <= size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 10; x <= size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (final dot in noiseDots) {
      final dotPaint = Paint()..color = dot.color;
      canvas.drawCircle(
        Offset(
          dot.relativeOffset.dx * size.width,
          dot.relativeOffset.dy * size.height,
        ),
        dot.radius,
        dotPaint,
      );
    }

    _paintStroke(
      canvas,
      _shapePoints(size),
    );
  }

  List<Offset> _shapePoints(Size size) {
    Offset fromUnit(double dx, double dy) =>
        Offset(size.width * dx, size.height * dy);

    switch (shape) {
      case ItemBonusShape.triangle:
        return <Offset>[
          fromUnit(0.5, 0.18),
          fromUnit(0.79, 0.76),
          fromUnit(0.21, 0.76),
        ];
      case ItemBonusShape.square:
        return <Offset>[
          fromUnit(0.24, 0.24),
          fromUnit(0.76, 0.24),
          fromUnit(0.76, 0.76),
          fromUnit(0.24, 0.76),
        ];
      case ItemBonusShape.circle:
        return List<Offset>.generate(37, (index) {
          final angle = (index / 36) * pi * 2;
          return Offset(
            (size.width * 0.5) + (cos(angle) * size.width * 0.27),
            (size.height * 0.5) + (sin(angle) * size.height * 0.27),
          );
        });
    }
  }

  void _paintStroke(Canvas canvas, List<Offset> points) {
    if (points.isEmpty) return;
    final isAngularShape = shape != ItemBonusShape.circle;

    final glowPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = isAngularShape ? StrokeJoin.miter : StrokeJoin.round
      ..strokeWidth = 9
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final corePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = isAngularShape ? StrokeJoin.miter : StrokeJoin.round
      ..strokeWidth = 4.2;

    if (points.length < 2) {
      canvas.drawCircle(
          points.first, 5.2, glowPaint..style = PaintingStyle.fill);
      canvas.drawCircle(
          points.first, 2.8, corePaint..style = PaintingStyle.fill);
      return;
    }

    final path = isAngularShape
        ? _buildAngularStrokePath(points)
        : _buildSmoothStrokePath(points);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, corePaint);
  }

  Path _buildSmoothStrokePath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int index = 1; index < points.length; index++) {
      final previousPoint = points[index - 1];
      final currentPoint = points[index];
      final midPoint = Offset(
        (previousPoint.dx + currentPoint.dx) / 2,
        (previousPoint.dy + currentPoint.dy) / 2,
      );
      path.quadraticBezierTo(
        previousPoint.dx,
        previousPoint.dy,
        midPoint.dx,
        midPoint.dy,
      );
    }
    final lastPoint = points.last;
    path.lineTo(lastPoint.dx, lastPoint.dy);
    return path;
  }

  Path _buildAngularStrokePath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int index = 1; index < points.length; index++) {
      final point = points[index];
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _ItemBonusSketchPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.noiseDots != noiseDots;
  }
}

class _ItemBonusSketchNoiseDot {
  final Offset relativeOffset;
  final double radius;
  final Color color;

  const _ItemBonusSketchNoiseDot({
    required this.relativeOffset,
    required this.radius,
    required this.color,
  });
}

List<_ItemBonusSketchNoiseDot> _buildItemBonusSketchNoiseDots() {
  final seededRandom = Random(_itemBonusSketchNoiseSeed);
  return List<_ItemBonusSketchNoiseDot>.generate(90, (index) {
    final tint = index.isEven
        ? EndpointPalette.softForeground
        : EndpointPalette.soften(EndpointPalette.infoAccent, amount: 0.2);
    return _ItemBonusSketchNoiseDot(
      relativeOffset: Offset(
        seededRandom.nextDouble(),
        seededRandom.nextDouble(),
      ),
      radius: 0.35 + (seededRandom.nextDouble() * 1.05),
      color: tint.withValues(
        alpha: 0.04 + (seededRandom.nextDouble() * 0.1),
      ),
    );
  });
}
