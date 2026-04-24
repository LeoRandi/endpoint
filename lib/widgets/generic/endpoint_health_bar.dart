import '../_imports.dart';

class EndpointHealthBar extends StatelessWidget {
  final double value;
  final Color accent;
  final double height;
  final Color? trackColor;
  final double trackOpacity;
  final double fillStartOpacity;
  final double fillEndOpacity;
  final Duration animationDuration;

  const EndpointHealthBar({
    super.key,
    required this.value,
    required this.accent,
    this.height = 12,
    this.trackColor,
    this.trackOpacity = 0.35,
    this.fillStartOpacity = 0.72,
    this.fillEndOpacity = 1,
    this.animationDuration = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedValue = value.clamp(0.0, 1.0).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: height,
        color:
            trackColor ?? Colors.black.withAlpha(_opacityToAlpha(trackOpacity)),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: normalizedValue),
          duration: animationDuration,
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, _) {
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: animatedValue,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withAlpha(_opacityToAlpha(fillStartOpacity)),
                        accent.withAlpha(_opacityToAlpha(fillEndOpacity)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int _opacityToAlpha(double opacity) {
    return (opacity.clamp(0.0, 1.0) * 255).round();
  }
}
