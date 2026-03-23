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
    return EndpointActionButton(
      label: label,
      onPressed: onPressed,
      tooltip: tooltip,
      expands: true,
      borderRadius: 8,
      borderWidth: 2,
      backgroundColor: const Color(0xFF0D2016),
      foregroundColor: const Color(0xFFE7FFF0),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      textStyle: textLargeBold.copyWith(
        fontSize: 28,
        letterSpacing: 2,
      ),
    );
  }
}
