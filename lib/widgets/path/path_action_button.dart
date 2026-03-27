import '../_imports.dart';

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
      iconSize: 18,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      textStyle: textMediumBold.copyWith(
        fontSize: 15,
        letterSpacing: 0.9,
      ),
    );
  }
}
