import '_imports.dart';

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
  final bool expands;
  final bool allowDisabledTooltip;

  const EndpointActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.tooltip = '',
    this.accent = const Color(0xFF5AF78E),
    this.backgroundColor = const Color(0xFF102519),
    this.foregroundColor = const Color(0xFFE6FFF0),
    this.textStyle = textMediumBold,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    this.borderRadius = 12,
    this.borderWidth = 1.5,
    this.expands = false,
    this.allowDisabledTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;
    if (icon == null) {
      button = FilledButton(
        onPressed: onPressed,
        style: _buttonStyle(),
        child: Text(label, overflow: TextOverflow.ellipsis),
      );
    } else {
      button = FilledButton.icon(
        onPressed: onPressed,
        style: _buttonStyle(),
        icon: Icon(icon, size: 22),
        label: Text(label, overflow: TextOverflow.ellipsis),
      );
    }

    if (expands) {
      button = SizedBox(
        width: double.infinity,
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
