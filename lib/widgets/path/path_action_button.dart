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
    return EndpointActionButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      borderRadius: 14,
      borderWidth: 1.4,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      textStyle: textMediumBold.copyWith(
        fontSize: 18,
        letterSpacing: 1.2,
      ),
    );
  }
}
