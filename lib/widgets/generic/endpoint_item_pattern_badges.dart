import '../_imports.dart';

class EndpointItemPatternBadges extends StatelessWidget {
  final Item item;
  final WrapAlignment alignment;

  const EndpointItemPatternBadges({
    super.key,
    required this.item,
    this.alignment = WrapAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    if (!item.hasPatternBonus && item.actionType == ItemActionType.none) {
      return const SizedBox.shrink();
    }

    return Wrap(
      alignment: alignment,
      spacing: 3,
      runSpacing: 3,
      children: [
        if (item.actionType != ItemActionType.none)
          _EndpointItemPatternBadge(
            label: _actionLabelFor(item),
            accent: _actionAccentFor(item.actionType),
          ),
        if (item.actionType == ItemActionType.none && item.hasPatternBonus) ...[
          _EndpointItemPatternBadge(
            label: _requirementLabelFor(item.patternRequirement),
            accent: EndpointPalette.patternAccent,
          ),
          _EndpointItemPatternBadge(
            label: _bonusLabelFor(item.patternBonus),
            accent: _bonusAccentFor(item.patternBonusKind),
          ),
        ],
      ],
    );
  }

  String _actionLabelFor(Item item) {
    final label = switch (item.actionType) {
      ItemActionType.attack => 'ATACA',
      ItemActionType.block => 'BLOQUEA',
      ItemActionType.heal => 'CURA',
      ItemActionType.none => 'PASIVO',
    };
    return '$label ${item.actionValue}';
  }

  Color _actionAccentFor(ItemActionType type) {
    return switch (type) {
      ItemActionType.attack => EndpointPalette.dangerAccent,
      ItemActionType.block => BattlerStat.barrier.accent,
      ItemActionType.heal => BattlerStat.health.accent,
      ItemActionType.none => EndpointPalette.patternAccent,
    };
  }

  String _requirementLabelFor(OperativePatternRequirement requirement) {
    return switch (requirement.kind) {
      OperativePatternRequirementKind.firstPoint => 'INI',
      OperativePatternRequirementKind.middlePoint => 'ME',
      OperativePatternRequirementKind.lastPoint => 'FIN',
      OperativePatternRequirementKind.rightAngle => '90\u00BA',
      OperativePatternRequirementKind.straightAngle => '180\u00BA',
      OperativePatternRequirementKind.exactShape => requirement.shortLabel,
    };
  }

  String _bonusLabelFor(OperativePatternBonus bonus) {
    final statLabel = switch (bonus.kind) {
      OperativePatternBonusKind.attack => 'ATK',
      OperativePatternBonusKind.barrier => 'BAR',
      OperativePatternBonusKind.health => 'HP',
    };
    return '+${bonus.amount} $statLabel';
  }

  Color _bonusAccentFor(OperativePatternBonusKind kind) {
    return switch (kind) {
      OperativePatternBonusKind.attack => EndpointPalette.dangerAccent,
      OperativePatternBonusKind.barrier => BattlerStat.barrier.accent,
      OperativePatternBonusKind.health => BattlerStat.health.accent,
    };
  }
}

class _EndpointItemPatternBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _EndpointItemPatternBadge({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.panelBackgroundBattleOpaque,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.72)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
        child: EndpointText(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textSmallBold.copyWith(
            color: EndpointPalette.soften(accent, amount: 0.22),
            fontSize: 8,
            letterSpacing: 0.4,
            height: 1,
          ),
        ),
      ),
    );
  }
}
