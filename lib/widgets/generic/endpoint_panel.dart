import '_imports.dart';

class EndpointPanel extends StatelessWidget {
  final Widget child;
  final Color accent;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double borderOpacity;
  final double glowOpacity;
  final double blurRadius;
  final double spreadRadius;
  final Border? border;

  const EndpointPanel({
    super.key,
    required this.child,
    this.accent = EndpointPalette.primaryAccent,
    this.backgroundColor = EndpointPalette.panelBackgroundStrong,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.borderOpacity = 0.7,
    this.glowOpacity = 0.12,
    this.blurRadius = 20,
    this.spreadRadius = 2,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: accent.withOpacity(borderOpacity)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(glowOpacity),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
