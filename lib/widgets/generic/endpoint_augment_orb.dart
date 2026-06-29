import '_imports.dart';

class EndpointAugmentSlotsStrip extends StatelessWidget {
  final List<Augment> augments;
  final Color accent;
  final ValueChanged<Augment>? onAugmentPressed;
  final int minimumSlots;
  final bool reserveEmptySlots;
  final double orbSize;
  final double spacing;
  final String emptyTooltip;

  const EndpointAugmentSlotsStrip({
    super.key,
    this.augments = const [],
    this.accent = EndpointPalette.primaryAccent,
    this.onAugmentPressed,
    this.minimumSlots = 3,
    this.reserveEmptySlots = false,
    this.orbSize = 46,
    this.spacing = 6,
    this.emptyTooltip = 'Slot de aumento',
  });

  @override
  Widget build(BuildContext context) {
    final slotCount = reserveEmptySlots
        ? max(minimumSlots, augments.length)
        : augments.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int index = 0; index < slotCount; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          Builder(
            builder: (context) {
              final augment = index < augments.length ? augments[index] : null;

              return EndpointAugmentOrb(
                key: ValueKey<String>(
                  augment == null ? 'augment-empty-$index' : '${augment.id}',
                ),
                augment: augment,
                accent: accent,
                size: orbSize,
                emptyTooltip: emptyTooltip,
                onPressed: augment != null && onAugmentPressed != null
                    ? () => onAugmentPressed!.call(augment)
                    : null,
              );
            },
          ),
        ],
      ],
    );
  }
}

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
