import '_imports.dart';

class EndpointValueChip extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final int value;
  final Color accent;
  final Color foreground;
  final TextStyle? textStyle;

  const EndpointValueChip({
    super.key,
    this.label,
    this.icon,
    required this.value,
    required this.accent,
    required this.foreground,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final text = label == null ? '$value' : '$label $value';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 4),
            ],
            EndpointText(
              text,
              style: (textStyle ??
                      textSmallNumericBold.copyWith(
                        letterSpacing: 1.2,
                      ))
                  .copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
