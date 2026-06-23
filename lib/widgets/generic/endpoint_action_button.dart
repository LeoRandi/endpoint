import '_imports.dart';

const endpointUpgradeIndicatorNeonYellow = Color(0xFFDFFF00);

Color endpointComplementaryAccent(Color color) {
  final hslColor = HSLColor.fromColor(color);
  final complementaryHue = (hslColor.hue + 180) % 360;
  final complementarySaturation = hslColor.saturation.clamp(0.62, 0.96);
  final complementaryLightness = hslColor.lightness < 0.5 ? 0.66 : 0.38;

  return hslColor
      .withHue(complementaryHue)
      .withSaturation(complementarySaturation)
      .withLightness(complementaryLightness)
      .toColor();
}

class EndpointActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color accent;
  final Color backgroundColor;
  final Color foregroundColor;
  final TextStyle textStyle;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double borderWidth;
  final double iconSize;
  final bool expands;
  final bool allowDisabledTooltip;
  final Axis layoutAxis;
  final int labelMaxLines;
  final TextAlign labelTextAlign;
  final double iconSpacing;
  final double? width;
  final double? height;
  final bool useMarquee;
  final bool showUpgradeIndicator;
  final Color? upgradeIndicatorColor;

  const EndpointActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.tooltip = '',
    this.accent = EndpointPalette.primaryAccent,
    this.backgroundColor = EndpointPalette.closeButtonBackground,
    this.foregroundColor = EndpointPalette.softForeground,
    this.textStyle = textMediumBold,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    this.borderRadius = 12,
    this.borderWidth = 1.5,
    this.iconSize = 22,
    this.expands = false,
    this.allowDisabledTooltip = true,
    this.layoutAxis = Axis.horizontal,
    this.labelMaxLines = 1,
    this.labelTextAlign = TextAlign.center,
    this.iconSpacing = 4,
    this.width,
    this.height,
    this.useMarquee = true,
    this.showUpgradeIndicator = false,
    this.upgradeIndicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = FilledButton(
      onPressed: onPressed,
      style: _buttonStyle(),
      child: _ButtonContent(
        label: label,
        icon: icon,
        iconSize: iconSize,
        layoutAxis: layoutAxis,
        labelMaxLines: labelMaxLines,
        labelTextAlign: labelTextAlign,
        iconSpacing: iconSpacing,
        useMarquee: useMarquee,
        showUpgradeIndicator: showUpgradeIndicator,
        upgradeIndicatorColor:
            upgradeIndicatorColor ?? endpointUpgradeIndicatorNeonYellow,
      ),
    );

    if (expands) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    } else if (width != null || height != null) {
      button = SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }

    if (tooltip.isEmpty) return button;
    if (onPressed == null && !allowDisabledTooltip) return button;

    return HoldTooltip(
      message: tooltip,
      child: button,
    );
  }

  ButtonStyle _buttonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: backgroundColor,
      disabledForegroundColor: foregroundColor.withValues(alpha: 0.42),
      padding: padding,
      textStyle: textStyle,
      side: BorderSide(color: accent, width: borderWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
    ).copyWith(
      overlayColor: WidgetStatePropertyAll(
        accent.withValues(alpha: 0.14),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final String label;
  final IconData? icon;
  final double iconSize;
  final Axis layoutAxis;
  final int labelMaxLines;
  final TextAlign labelTextAlign;
  final double iconSpacing;
  final bool useMarquee;
  final bool showUpgradeIndicator;
  final Color upgradeIndicatorColor;

  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.layoutAxis,
    required this.labelMaxLines,
    required this.labelTextAlign,
    required this.iconSpacing,
    required this.useMarquee,
    required this.showUpgradeIndicator,
    required this.upgradeIndicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidget = useMarquee
        ? EndpointMarqueeText(
            label,
            overflow: TextOverflow.ellipsis,
          )
        : EndpointText(
            label,
            textAlign: labelTextAlign,
            maxLines: labelMaxLines,
            overflow: TextOverflow.ellipsis,
          );

    final coreContent = _buildCoreContent(labelWidget);
    if (!showUpgradeIndicator) {
      return coreContent;
    }

    return EndpointUpgradeBackdrop(
      color: upgradeIndicatorColor,
      iconSize: max(20, iconSize - 1),
      spacing: max(4, iconSpacing + 2),
      child: Center(
        child: coreContent,
      ),
    );
  }

  Widget _buildCoreContent(Widget labelWidget) {
    if (icon == null) {
      return labelWidget;
    }

    final spacing = SizedBox(
      width: layoutAxis == Axis.horizontal ? iconSpacing : null,
      height: layoutAxis == Axis.vertical ? iconSpacing : null,
    );
    final children = <Widget>[
      Icon(icon, size: iconSize),
      spacing,
      Flexible(
        fit: FlexFit.loose,
        child: labelWidget,
      ),
    ];

    return Flex(
      direction: layoutAxis,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class EndpointUpgradeBackdrop extends StatefulWidget {
  final Widget child;
  final Color color;
  final double iconSize;
  final double spacing;
  final double horizontalInset;
  final BorderRadius? borderRadius;
  final Duration duration;

  const EndpointUpgradeBackdrop({
    super.key,
    required this.child,
    required this.color,
    this.iconSize = 22,
    this.spacing = 6,
    this.horizontalInset = 2,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 1150),
  });

  @override
  State<EndpointUpgradeBackdrop> createState() =>
      _EndpointUpgradeBackdropState();
}

class _EndpointUpgradeBackdropState extends State<EndpointUpgradeBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void didUpdateWidget(covariant EndpointUpgradeBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _controller
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final stack = Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRect(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.horizontalInset,
                    ),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _EndpointUpgradeArrowPatternPainter(
                            color: widget.color,
                            iconSize: widget.iconSize,
                            spacing: widget.spacing,
                            progress: _controller.value,
                          ),
                          child: child,
                        );
                      },
                      child: width.isFinite
                          ? SizedBox(width: width)
                          : SizedBox(
                              width:
                                  (widget.iconSize * 3) + (widget.spacing * 2),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        );

        if (!width.isFinite) {
          return stack;
        }

        return SizedBox(
          width: width,
          child: stack,
        );
      },
    );

    if (widget.borderRadius == null) {
      return content;
    }

    return ClipRRect(
      borderRadius: widget.borderRadius!,
      child: content,
    );
  }
}

class _EndpointUpgradeArrowPatternPainter extends CustomPainter {
  final Color color;
  final double iconSize;
  final double spacing;
  final double progress;

  const _EndpointUpgradeArrowPatternPainter({
    required this.color,
    required this.iconSize,
    required this.spacing,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    const iconData = Icons.arrow_upward_rounded;
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          inherit: false,
          fontSize: iconSize,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: color.withValues(alpha: 0.5),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final stepX = textPainter.width + spacing;
    final stepY = textPainter.height + spacing;
    final columns = max(1, ((size.width + spacing) / stepX).ceil());
    final centeredRowY = (size.height - textPainter.height) / 2;
    final firstRowY = centeredRowY - stepY - (stepY * progress);
    final rowCount = max(3, ((size.height / stepY).ceil()) + 2);

    for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) {
      final y = firstRowY + (rowIndex * stepY);
      if (y > size.height || y + textPainter.height < 0) {
        continue;
      }

      for (var columnIndex = 0; columnIndex < columns; columnIndex++) {
        final x = columnIndex * stepX;
        textPainter.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(
      covariant _EndpointUpgradeArrowPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.iconSize != iconSize ||
        oldDelegate.spacing != spacing ||
        oldDelegate.progress != progress;
  }
}
