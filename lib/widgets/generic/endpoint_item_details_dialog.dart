import '../_imports.dart';
import '../../services/_exports.dart';

class EndpointItemDetailsDialog extends StatefulWidget {
  final Item item;
  final Color accent;
  final int price;
  final String priceLabel;
  final String statusText;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onPrimaryAction;
  final bool isActionEnabled;
  final String enabledActionTooltip;
  final String disabledActionTooltip;
  final bool showPrimaryActionUpgradeIndicator;
  final Color? primaryActionUpgradeIndicatorColor;
  final String? secondaryActionLabel;
  final IconData secondaryActionIcon;
  final VoidCallback? onSecondaryAction;
  final bool isSecondaryActionEnabled;
  final String enabledSecondaryActionTooltip;
  final String disabledSecondaryActionTooltip;

  const EndpointItemDetailsDialog({
    super.key,
    required this.item,
    required this.accent,
    required this.price,
    this.priceLabel = 'PRECIO',
    required this.statusText,
    this.actionLabel,
    this.actionIcon = Icons.shopping_bag_outlined,
    this.onPrimaryAction,
    this.isActionEnabled = false,
    this.enabledActionTooltip = '',
    this.disabledActionTooltip = '',
    this.showPrimaryActionUpgradeIndicator = false,
    this.primaryActionUpgradeIndicatorColor,
    this.secondaryActionLabel,
    this.secondaryActionIcon = Icons.swap_vert_rounded,
    this.onSecondaryAction,
    this.isSecondaryActionEnabled = false,
    this.enabledSecondaryActionTooltip = '',
    this.disabledSecondaryActionTooltip = '',
  });

  @override
  State<EndpointItemDetailsDialog> createState() =>
      _EndpointItemDetailsDialogState();
}

class _EndpointItemDetailsDialogState extends State<EndpointItemDetailsDialog> {
  EndpointGameMode _gameMode = EndpointGameMode.classic;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final settings = await EndpointPreferencesService.loadSettingsSnapshot();
    if (!mounted) return;

    setState(() {
      _gameMode = settings.gameMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final foreground = EndpointPalette.soften(widget.accent);
    final statusSurface = EndpointPalette.blend(
      EndpointPalette.panelBackgroundGold,
      widget.accent,
      0.16,
    );
    final secondaryActionSurface = EndpointPalette.blend(
      EndpointPalette.panelBackground,
      widget.accent,
      0.08,
    );
    final shouldShowPatternBonus = _gameMode == EndpointGameMode.pattern;

    return EndpointDetailsDialogScaffold(
      accent: widget.accent,
      backgroundColor: EndpointPalette.panelBackgroundGold,
      foregroundColor: foreground,
      closeBackgroundColor: EndpointPalette.blend(
        EndpointPalette.panelBackgroundGold,
        widget.accent,
        0.08,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EndpointEmojiSprite(
                emoji: widget.item.iconEmoji,
                accent: widget.accent,
                size: 72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EndpointText(
                      widget.item.displayName,
                      maxLines: null,
                      style: textLargeBold.copyWith(
                        color: foreground,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        EndpointText(
                          widget.priceLabel,
                          style: textSmallBold.copyWith(
                            fontSize: 10,
                            color: EndpointPalette.warningAccent,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const Spacer(),
                        EndpointCurrencyInline(
                          value: widget.price,
                          iconColor: EndpointPalette.warningAccent,
                          textColor: EndpointPalette.softForegroundWarm,
                          iconSize: 13,
                          spacing: 3,
                          textStyle: textSmallNumericBold.copyWith(
                            fontSize: 11,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    if (widget.item.hasTags) ...[
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: EndpointTagPillMarquee(
                          tags: widget.item.tags,
                          accent: widget.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EndpointHighlightedValueText(
            widget.item.displayDescription,
            tags: widget.item.tags,
            maxLines: null,
            style: textMedium.copyWith(
              fontSize: 14,
              color: EndpointPalette.softForeground.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: EndpointText(
                  _buildModifiersText(widget.item),
                  maxLines: null,
                  style: textSmallNumericBold.copyWith(
                    fontSize: 10,
                    color: widget.accent,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ItemArchetypeBadge(item: widget.item),
            ],
          ),
          if (shouldShowPatternBonus) ...[
            const SizedBox(height: 12),
            _ItemPatternBonusSection(item: widget.item),
          ],
          if (widget.actionLabel != null ||
              widget.secondaryActionLabel != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (widget.secondaryActionLabel != null)
                    EndpointActionButton(
                      label: widget.secondaryActionLabel!,
                      icon: widget.secondaryActionIcon,
                      onPressed: widget.isSecondaryActionEnabled
                          ? widget.onSecondaryAction
                          : null,
                      tooltip: widget.isSecondaryActionEnabled
                          ? widget.enabledSecondaryActionTooltip
                          : widget.disabledSecondaryActionTooltip,
                      accent: widget.accent,
                      backgroundColor: secondaryActionSurface,
                      foregroundColor: foreground,
                      borderWidth: 1.2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      textStyle: textSmallBold.copyWith(letterSpacing: 1.1),
                      iconSize: 18,
                      useMarquee: false,
                      width: widget.actionLabel != null ? 118 : null,
                    ),
                  if (widget.actionLabel != null)
                    EndpointActionButton(
                      label: widget.actionLabel!,
                      icon: widget.actionIcon,
                      onPressed: widget.isActionEnabled
                          ? widget.onPrimaryAction
                          : null,
                      tooltip: widget.isActionEnabled
                          ? widget.enabledActionTooltip
                          : widget.disabledActionTooltip,
                      accent: widget.accent,
                      backgroundColor: statusSurface,
                      foregroundColor: foreground,
                      borderWidth: 1.3,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      textStyle: textMediumBold.copyWith(letterSpacing: 1.2),
                      showUpgradeIndicator:
                          widget.showPrimaryActionUpgradeIndicator,
                      upgradeIndicatorColor:
                          widget.primaryActionUpgradeIndicatorColor,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildModifiersText(Item item) {
    final entries = <String>[
      ...item.statModifiers.entries.map((entry) {
        final value = entry.value;
        final sign = value >= 0 ? '+' : '';
        return '$sign$value ${_modifierLabel(entry.key)}';
      }),
    ];

    if (item.incomeModifier != 0) {
      final sign = item.incomeModifier >= 0 ? '+' : '';
      entries.add('$sign${item.incomeModifier} INCOME');
    }

    if (item.maxHealthPercentModifier != 0) {
      final sign = item.maxHealthPercentModifier >= 0 ? '+' : '';
      entries.add('$sign${item.maxHealthPercentModifier}% HP MAX');
    }

    if (entries.isEmpty) return 'Sin modificadores directos.';

    return entries.join('   ');
  }

  String _modifierLabel(BattlerStat stat) {
    if (stat == BattlerStat.barrier) {
      return stat.label;
    }

    return stat.shortLabel;
  }
}

class _ItemArchetypeBadge extends StatelessWidget {
  final Item item;

  const _ItemArchetypeBadge({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final affinities = _displayAffinities(item);
    final accent = _accentForAffinity(affinities.first);
    final label = affinities.map(_labelForAffinity).join(', ');
    final emoji = affinities.map(_emojiForAffinity).join('');

    return Tooltip(
      message:
          'Arquetipo del objeto: $label.\nLos arquetipos agrupan objetos y AUMENTOS para orientar una build.\n${_archetypeLegend()}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EndpointPalette.blend(
            EndpointPalette.panelBackgroundOpaque,
            accent,
            0.18,
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent.withValues(alpha: 0.62),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: EndpointText(
            emoji,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 12,
              height: 1,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  List<ItemArchetypeAffinity> _displayAffinities(Item item) {
    final specificAffinities = item.archetypeAffinities
        .where((affinity) => affinity.isSpecific)
        .toList(growable: false);
    if (specificAffinities.isNotEmpty) return specificAffinities;

    return const [ItemArchetypeAffinity.general];
  }

  String _archetypeLegend() {
    return [
      '${_emojiForAffinity(ItemArchetypeAffinity.general)} General',
      '${_emojiForAffinity(ItemArchetypeAffinity.veloz)} Veloz',
      '${_emojiForAffinity(ItemArchetypeAffinity.inamovible)} Inamovible',
      '${_emojiForAffinity(ItemArchetypeAffinity.imparable)} Imparable',
      '${_emojiForAffinity(ItemArchetypeAffinity.mercante)} Mercante',
    ].join(' | ');
  }

  String _labelForAffinity(ItemArchetypeAffinity affinity) {
    return switch (affinity) {
      ItemArchetypeAffinity.general => 'General',
      ItemArchetypeAffinity.veloz => ArchetypeId.veloz.label,
      ItemArchetypeAffinity.inamovible => ArchetypeId.inamovible.label,
      ItemArchetypeAffinity.imparable => ArchetypeId.imparable.label,
      ItemArchetypeAffinity.mercante => ArchetypeId.mercante.label,
    };
  }

  String _emojiForAffinity(ItemArchetypeAffinity affinity) {
    return switch (affinity) {
      ItemArchetypeAffinity.general => '\u{1FAB5}',
      ItemArchetypeAffinity.veloz => '\u{26D3}',
      ItemArchetypeAffinity.inamovible => '\u{1F6E1}',
      ItemArchetypeAffinity.imparable => '\u2694',
      ItemArchetypeAffinity.mercante => '\u{1F4B0}',
    };
  }

  Color _accentForAffinity(ItemArchetypeAffinity affinity) {
    return switch (affinity) {
      ItemArchetypeAffinity.general => EndpointPalette.softForeground,
      ItemArchetypeAffinity.veloz => const Color(0xFF59B7FF),
      ItemArchetypeAffinity.inamovible => const Color(0xFF5AF78E),
      ItemArchetypeAffinity.imparable => const Color(0xFFF3D35C),
      ItemArchetypeAffinity.mercante => const Color(0xFFEBCB5A),
    };
  }
}

class _ItemPatternBonusSection extends StatelessWidget {
  final Item item;

  const _ItemPatternBonusSection({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final bonus = item.patternBonus;
    final requirement = item.patternRequirement;
    final adjacencyBonuses = item.patternAdjacencyBonuses;
    final accent = _bonusAccent(bonus.kind);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.blend(
          EndpointPalette.panelBackgroundGold,
          accent,
          0.08,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: 0.42),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EndpointText(
                  'PATRON BONUS',
                  style: textSmallBold.copyWith(
                    color: accent,
                    fontSize: 10,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Image.asset(
                  _bonusIconAssetPath(bonus.kind),
                  width: 15,
                  height: 15,
                  filterQuality: FilterQuality.none,
                  color: accent,
                ),
                const SizedBox(width: 4),
                EndpointText(
                  '+${bonus.amount}',
                  style: textSmallNumericBold.copyWith(
                    color: accent,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: EndpointPalette.panelBackgroundOpaque.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: EndpointPalette.softForeground.withValues(
                        alpha: 0.36,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    child: EndpointText(
                      requirement.shortLabel,
                      style: textSmallBold.copyWith(
                        color: EndpointPalette.softForeground,
                        fontSize: 9,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: EndpointText(
                    '${requirement.label}: ${requirement.description}',
                    maxLines: null,
                    style: textSmall.copyWith(
                      color: EndpointPalette.softForeground.withValues(
                        alpha: 0.78,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            if (adjacencyBonuses.isNotEmpty) ...[
              const SizedBox(height: 8),
              EndpointText(
                'ADYACENCIA',
                style: textSmallBold.copyWith(
                  color: EndpointPalette.patternAccent,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final adjacencyBonus in adjacencyBonuses)
                    _PatternAdjacencyBonusChip(
                      adjacencyBonus: adjacencyBonus,
                      accent: _bonusAccent(adjacencyBonus.bonus.kind),
                      iconAssetPath:
                          _bonusIconAssetPath(adjacencyBonus.bonus.kind),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _bonusAccent(OperativePatternBonusKind kind) {
    return switch (kind) {
      OperativePatternBonusKind.attack => EndpointPalette.dangerAccent,
      OperativePatternBonusKind.barrier => BattlerStat.barrier.accent,
    };
  }

  String _bonusIconAssetPath(OperativePatternBonusKind kind) {
    return switch (kind) {
      OperativePatternBonusKind.attack => 'assets/images/icons/icon_sword.png',
      OperativePatternBonusKind.barrier =>
        'assets/images/icons/icon_shield.png',
    };
  }
}

class _PatternAdjacencyBonusChip extends StatelessWidget {
  final OperativePatternAdjacencyBonus adjacencyBonus;
  final Color accent;
  final String iconAssetPath;

  const _PatternAdjacencyBonusChip({
    required this.adjacencyBonus,
    required this.accent,
    required this.iconAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${adjacencyBonus.direction.label}: requiere ${adjacencyBonus.requiredTag.label}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EndpointPalette.panelBackgroundOpaque.withValues(alpha: 0.66),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent.withValues(alpha: 0.38),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: _arrowRotationFor(adjacencyBonus.direction),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 13,
                  color: adjacencyBonus.requiredTag.accent,
                ),
              ),
              const SizedBox(width: 4),
              EndpointText(
                adjacencyBonus.requiredTag.label.toUpperCase(),
                style: textSmallBold.copyWith(
                  color: adjacencyBonus.requiredTag.accent,
                  fontSize: 8,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 5),
              Image.asset(
                iconAssetPath,
                width: 11,
                height: 11,
                filterQuality: FilterQuality.none,
                color: accent,
              ),
              const SizedBox(width: 2),
              EndpointText(
                '+${adjacencyBonus.bonus.amount}',
                style: textSmallNumericBold.copyWith(
                  color: accent,
                  fontSize: 9,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _arrowRotationFor(OperativePatternAdjacencyDirection direction) {
    return switch (direction) {
      OperativePatternAdjacencyDirection.north => pi / 4,
      OperativePatternAdjacencyDirection.east => 3 * pi / 4,
      OperativePatternAdjacencyDirection.south => 5 * pi / 4,
      OperativePatternAdjacencyDirection.west => -pi / 4,
    };
  }
}

