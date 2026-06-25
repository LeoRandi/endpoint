import '_imports.dart';

class EndpointAugmentOrb extends StatelessWidget {
  final Augment? augment;
  final Color? accent;
  final double size;
  final VoidCallback? onPressed;
  final String emptyTooltip;

  const EndpointAugmentOrb({
    super.key,
    required this.augment,
    this.accent,
    this.size = 58,
    this.onPressed,
    this.emptyTooltip = 'Sin aumento',
  });

  @override
  Widget build(BuildContext context) {
    final currentAugment = augment;
    final resolvedAccent =
        currentAugment?.accent ?? accent ?? EndpointPalette.primaryAccent;
    final tooltip = currentAugment?.displayDescription ?? emptyTooltip;
    final child = HoldTooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: EndpointPalette.blend(
              EndpointPalette.panelBackgroundGold,
              resolvedAccent,
              currentAugment == null ? 0.06 : 0.18,
            ),
            border: Border.all(
              color: resolvedAccent.withValues(
                  alpha: currentAugment == null ? 0.35 : 0.82),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: resolvedAccent.withValues(
                    alpha: currentAugment == null ? 0.08 : 0.22),
                blurRadius: size * 0.18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              currentAugment?.icon ?? Icons.auto_awesome_rounded,
              color: EndpointPalette.soften(resolvedAccent),
              size: size * 0.45,
            ),
          ),
        ),
      ),
    );

    if (onPressed == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: child,
      ),
    );
  }
}
