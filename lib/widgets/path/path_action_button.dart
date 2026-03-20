import '_imports.dart';

class PathActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const PathActionButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        textStyle: textMediumBold.copyWith(
          fontSize: 18,
          letterSpacing: 1.2,
        ),
        side: const BorderSide(color: accent, width: 1.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ).copyWith(
        overlayColor: MaterialStatePropertyAll(accent.withOpacity(0.14)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );

    if (tooltip.isEmpty) return button;
    return HoldTooltip(
      message: tooltip,
      child: button,
    );
  }
}
