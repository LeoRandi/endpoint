import '../_imports.dart';

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
      disabledForegroundColor: foregroundColor.withOpacity(0.42),
      padding: padding,
      textStyle: textStyle,
      side: BorderSide(color: accent, width: borderWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
    ).copyWith(
      overlayColor: MaterialStatePropertyAll(accent.withOpacity(0.14)),
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

  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.layoutAxis,
    required this.labelMaxLines,
    required this.labelTextAlign,
    required this.iconSpacing,
    required this.useMarquee,
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
