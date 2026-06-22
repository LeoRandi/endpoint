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
    final label = endpointItemActionShortLabel(item.actionType);
    return '$label ${item.actionValue}';
  }

  Color _actionAccentFor(ItemActionType type) {
    return endpointItemActionAccent(type);
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

Color endpointItemActionAccent(ItemActionType type) {
  return switch (type) {
    ItemActionType.attack => EndpointPalette.dangerAccent,
    ItemActionType.block => BattlerStat.barrier.accent,
    ItemActionType.heal => const Color(0xFF5AF78E),
    ItemActionType.none => EndpointPalette.patternAccent,
  };
}

String endpointItemActionShortLabel(ItemActionType type) {
  return switch (type) {
    ItemActionType.attack => 'ATACA',
    ItemActionType.block => 'BLOQUEA',
    ItemActionType.heal => 'CURA',
    ItemActionType.none => 'PASIVO',
  };
}

String endpointItemActionDescription(Item item) {
  return switch (item.actionType) {
    ItemActionType.attack => 'Acción: realiza ${item.actionValue} de daño.',
    ItemActionType.block => 'Acción: gana ${item.actionValue} de barrera.',
    ItemActionType.heal => 'Acción: cura ${item.actionValue} de vida.',
    ItemActionType.none => '',
  };
}

class EndpointItemActionPointBadge extends StatelessWidget {
  final Item item;
  final double size;

  const EndpointItemActionPointBadge({
    super.key,
    required this.item,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (item.actionType == ItemActionType.none) {
      return const SizedBox.shrink();
    }

    final accent = endpointItemActionAccent(item.actionType);
    return SizedBox(
      width: size * 1.32,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EndpointPalette.blend(
            EndpointPalette.panelBackgroundBattleOpaque,
            accent,
            0.42,
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent.withValues(alpha: 0.94),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.42),
              blurRadius: 8,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: EndpointText(
            '${item.actionValue}',
            maxLines: 1,
            style: textSmallNumericBold.copyWith(
              color: EndpointPalette.softForeground,
              fontSize: (size * 0.52).clamp(8.0, 11.0).toDouble(),
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ),
      ),
    );
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
