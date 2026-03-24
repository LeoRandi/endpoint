import '_imports.dart';

class BattleActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double dimension;

  const BattleActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.tooltip = '',
    this.dimension = 84,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = onPressed == null
        ? const Color(0xFFE6FFF0).withOpacity(0.42)
        : const Color(0xFFE6FFF0);

    Widget button = SizedBox.square(
      dimension: dimension,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF102519),
          foregroundColor: foreground,
          disabledBackgroundColor: const Color(0xFF102519),
          disabledForegroundColor: foreground,
          side: const BorderSide(
            color: Color(0xFF5AF78E),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          elevation: 0,
        ).copyWith(
          overlayColor: const MaterialStatePropertyAll(
            Color(0x245AF78E),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 6),
            EndpointText(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: textSmallBold.copyWith(
                color: foreground,
                fontSize: 12,
                letterSpacing: 0.6,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );

    if (tooltip.isEmpty) return button;

    return HoldTooltip(
      message: tooltip,
      child: button,
    );
  }
}
