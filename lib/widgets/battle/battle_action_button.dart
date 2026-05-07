import '../_imports.dart';

class BattleActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double dimension;
  final EdgeInsetsGeometry padding;

  const BattleActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.tooltip = '',
    this.dimension = 84,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final foreground = onPressed == null
        ? EndpointPalette.softForeground.withOpacity(0.42)
        : EndpointPalette.softForeground;

    return EndpointActionButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      width: dimension,
      height: dimension,
      useMarquee: false,
      layoutAxis: Axis.vertical,
      labelMaxLines: 2,
      iconSize: 18,
      iconSpacing: 6,
      borderRadius: 12,
      borderWidth: 1.5,
      padding: padding,
      textStyle: textSmallBold.copyWith(
        color: foreground,
        fontSize: 12,
        letterSpacing: 0.6,
        height: 1.1,
      ),
      backgroundColor: EndpointPalette.closeButtonBackground,
      foregroundColor: foreground,
      accent: EndpointPalette.primaryAccent,
    );
  }
}
