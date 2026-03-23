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
    return EndpointActionButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      textStyle: textLargeBold.copyWith(
        fontSize: 22,
        letterSpacing: 1.2,
      ),
    );
  }
}
