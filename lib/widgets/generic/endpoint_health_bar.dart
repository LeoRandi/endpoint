import '../_imports.dart';

class EndpointHealthBar extends StatelessWidget {
  final double value;
  final Color accent;
  final double height;
  final Color? trackColor;
  final double trackOpacity;
  final double fillStartOpacity;
  final double fillEndOpacity;

  const EndpointHealthBar({
    super.key,
    required this.value,
    required this.accent,
    this.height = 12,
    this.trackColor,
    this.trackOpacity = 0.35,
    this.fillStartOpacity = 0.72,
    this.fillEndOpacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: height,
        color: trackColor ?? Colors.black.withOpacity(trackOpacity),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(fillStartOpacity),
                    accent.withOpacity(fillEndOpacity),
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
