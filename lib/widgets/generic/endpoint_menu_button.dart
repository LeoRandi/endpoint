import '_imports.dart';

class EndpointMenuButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final String tooltip;

  const EndpointMenuButton({
    super.key,
    required this.label,
    this.onPressed,
    this.tooltip = '',
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF5AF78E);
    const background = Color(0xFF0D2016);

    final button = SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed ?? () {},
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: const Color(0xFFE7FFF0),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          textStyle: textLargeBold.copyWith(
            fontSize: 28,
            letterSpacing: 2,
          ),
          side: const BorderSide(color: accent, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ).copyWith(
          overlayColor: MaterialStatePropertyAll(accent.withOpacity(0.14)),
        ),
        child: Text(label),
      ),
    );

    if (tooltip.isEmpty) return button;
    return HoldTooltip(
      message: tooltip,
      child: button,
    );
  }
}
