import '_imports.dart';

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
    this.accent = const Color(0xFF5AF78E),
    this.foregroundColor = const Color(0xFFE6FFF0),
    this.backgroundColor = const Color(0xFF102519),
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
