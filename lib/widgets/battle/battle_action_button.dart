import '_imports.dart';

class BattleActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const BattleActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.tooltip = '',
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF5AF78E);
    const foreground = Color(0xFFE6FFF0);

    final button = FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF102519),
        foregroundColor: foreground,
        disabledBackgroundColor: const Color(0xFF102519),
        disabledForegroundColor: foreground.withOpacity(0.42),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        textStyle: textLargeBold.copyWith(
          fontSize: 22,
          letterSpacing: 1.2,
        ),
        side: const BorderSide(color: accent, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ).copyWith(
        overlayColor: MaterialStatePropertyAll(accent.withOpacity(0.14)),
      ),
      icon: Icon(icon, size: 22),
      label: Text(label),
    );

    if (tooltip.isEmpty) return button;
    return HoldTooltip(
      message: tooltip,
      child: button,
    );
  }
}
