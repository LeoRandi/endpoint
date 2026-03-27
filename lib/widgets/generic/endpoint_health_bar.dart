import '../_imports.dart';

class EndpointHealthBar extends StatelessWidget {
  final double value;
  final Color accent;
  final double height;

  const EndpointHealthBar({
    super.key,
    required this.value,
    required this.accent,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: height,
        color: Colors.black.withOpacity(0.35),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(0.72),
                    accent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
