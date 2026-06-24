import '_imports.dart';

Color endpointItemActionAccent(ItemActionType type) {
  return switch (type) {
    ItemActionType.attack => EndpointPalette.dangerAccent,
    ItemActionType.block => BattlerStat.barrier.accent,
    ItemActionType.heal => EndpointPalette.healthAccent,
    ItemActionType.none => EndpointPalette.patternAccent,
  };
}

class EndpointItemActionPointBadge extends StatelessWidget {
  final ActionEffect action;
  final double size;

  const EndpointItemActionPointBadge({
    super.key,
    required this.action,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final accent = endpointItemActionAccent(action.actionType);
    return Container(
      width: size * 1.32,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: EndpointPalette.blend(
          EndpointPalette.panelBackgroundBattleOpaque,
          accent,
          0.42,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.94)),
      ),
      child: EndpointText(
        '${action.value}',
        style: textSmallNumericBold.copyWith(
          color: EndpointPalette.softForeground,
          fontSize: (size * 0.52).clamp(8.0, 11.0).toDouble(),
          height: 1,
        ),
      ),
    );
  }
}
