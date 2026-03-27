import '../_imports.dart';

class EndpointSceneCloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final Color accent;
  final Color foregroundColor;
  final Color backgroundColor;

  const EndpointSceneCloseButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Cerrar',
    this.accent = EndpointPalette.primaryAccent,
    this.foregroundColor = EndpointPalette.softForeground,
    this.backgroundColor = EndpointPalette.closeButtonBackground,
  });

  @override
  Widget build(BuildContext context) {
    return HoldTooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          side: BorderSide(color: accent),
        ),
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}
