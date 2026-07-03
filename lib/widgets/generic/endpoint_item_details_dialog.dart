import '_imports.dart';

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
                imageAsset: widget.item.asset,
                accent: widget.accent,
                size: 92,
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.accent.withValues(alpha: 0.8),
                                  widget.accent.withValues(alpha: 0.12),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ItemArchetypeBadge(item: widget.item),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.item.hasTags)
                      SizedBox(
                        width: double.infinity,
                        child: EndpointTagPillMarquee(
                          tags: widget.item.tags,
                          accent: widget.accent,
                        ),
                      )
                    else
                      EndpointText(
                        'SIN TAGS',
                        style: textSmallBold.copyWith(
                          color: EndpointPalette.softForeground.withValues(
                            alpha: 0.38,
                          ),
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                    if (widget.item.isGhostly) ...[
                      const SizedBox(height: 6),
                      const _GhostItemDetailBadge(),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.item.localizedDisplayDescription.isNotEmpty) ...[
            EndpointHighlightedValueText(
              widget.item.localizedDisplayDescription,
              tags: widget.item.tags,
              maxLines: null,
              style: textMedium.copyWith(
                color: EndpointPalette.softForeground.withValues(alpha: 0.84),
                fontSize: 13,
                height: 1.32,
              ),
            ),
            const SizedBox(height: 14),
          ],
          _ItemEffectGroups(
            item: widget.item,
            accent: widget.accent,
          ),
          const SizedBox(height: 14),
          _ItemDialogStatusRow(
            item: widget.item,
            price: widget.price,
            priceLabel: widget.priceLabel,
            statusText: widget.statusText,
            accent: widget.accent,
          ),
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
}

class _ItemEffectGroups extends StatelessWidget {
  final Item item;
  final Color accent;

  const _ItemEffectGroups({
    required this.item,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final actions = item.actionEffects;
    final patterns = item.patternEffects;
    final passives = item.effects.keys.whereType<PassiveEffect>().toList();
    var isFirstGroup = true;
    final groups = <Widget>[];

    void addGroup({
      required String title,
      required IconData icon,
      required Color groupAccent,
      required int count,
      required Widget child,
    }) {
      if (count == 0) return;
      groups.add(
        _CollapsibleEffectGroup(
          title: title,
          icon: icon,
          accent: groupAccent,
          count: count,
          initiallyExpanded: isFirstGroup,
          child: child,
        ),
      );
      isFirstGroup = false;
    }

    addGroup(
      title: 'ACCIONES',
      icon: Icons.touch_app_rounded,
      groupAccent: EndpointPalette.dangerAccent,
      count: actions.length,
      child: _ActionEffectsContent(
        actions: actions,
        tags: item.tags,
      ),
    );
    addGroup(
      title: 'PATRONES',
      icon: Icons.gesture_rounded,
      groupAccent: EndpointPalette.patternAccent,
      count: patterns.length,
      child: _PatternEffectsContent(item: item, patterns: patterns),
    );
    addGroup(
      title: 'PASIVOS',
      icon: Icons.autorenew_rounded,
      groupAccent: accent,
      count: passives.length,
      child: _PassiveEffectsContent(
        passives: passives,
        tags: item.tags,
      ),
    );

    if (groups.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: EndpointPalette.panelBackgroundOpaque.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: 0.24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: EndpointText(
            'Este objeto no tiene efectos.',
            maxLines: null,
            style: textMedium.copyWith(
              color: EndpointPalette.softForeground.withValues(alpha: 0.62),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < groups.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          groups[index],
        ],
      ],
    );
  }
}

class _CollapsibleEffectGroup extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final int count;
  final bool initiallyExpanded;
  final Widget child;

  const _CollapsibleEffectGroup({
    required this.title,
    required this.icon,
    required this.accent,
    required this.count,
    required this.initiallyExpanded,
    required this.child,
  });

  @override
  State<_CollapsibleEffectGroup> createState() =>
      _CollapsibleEffectGroupState();
}

class _CollapsibleEffectGroupState extends State<_CollapsibleEffectGroup> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: EndpointPalette.blend(
            EndpointPalette.panelBackgroundGold,
            widget.accent,
            0.07,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.accent.withValues(alpha: 0.38),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: widget.accent, size: 17),
                    const SizedBox(width: 7),
                    Expanded(
                      child: EndpointText(
                        widget.title,
                        style: textSmallBold.copyWith(
                          color: widget.accent,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    EndpointText(
                      '${widget.count}',
                      style: textSmallNumericBold.copyWith(
                        color: widget.accent,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: widget.accent,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(11, 2, 11, 11),
                child: widget.child,
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionEffectsContent extends StatelessWidget {
  final List<ActionEffect> actions;
  final Iterable<EntityTag> tags;

  const _ActionEffectsContent({
    required this.actions,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EndpointHighlightedValueText(
          'Al usarse:',
          tags: tags,
          style: textMediumBold.copyWith(
            color: EndpointPalette.softForeground,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: EndpointHighlightedValueText(
              '-${_itemActionDescription(action)}',
              tags: tags,
              maxLines: null,
              style: textMedium.copyWith(
                color: EndpointPalette.softForeground.withValues(alpha: 0.86),
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _PatternEffectsContent extends StatelessWidget {
  final Item item;
  final List<PatternEffect> patterns;

  const _PatternEffectsContent({
    required this.item,
    required this.patterns,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < patterns.length; index++) ...[
          if (index > 0)
            Divider(
              height: 17,
              color: EndpointPalette.patternAccent.withValues(alpha: 0.2),
            ),
          _PatternEffectRow(item: item, effect: patterns[index]),
        ],
      ],
    );
  }
}

class _PatternEffectRow extends StatelessWidget {
  final Item item;
  final PatternEffect effect;

  const _PatternEffectRow({
    required this.item,
    required this.effect,
  });

  @override
  Widget build(BuildContext context) {
    final action = effect.actionEffect;
    final effectAccent = endpointItemActionAccent(action.actionType);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ItemPatternRequirementPreview(
          item: item,
          requirement: effect.patternType,
          accent: EndpointPalette.patternAccent,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EndpointText(
                effect.patternType.label,
                maxLines: null,
                style: textSmallBold.copyWith(
                  color: EndpointPalette.softForeground.withValues(alpha: 0.7),
                  fontSize: 9,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  if (action.actionType != ItemActionType.none)
                    Image.asset(
                      _effectIconAsset(action.actionType),
                      width: 18,
                      height: 18,
                      filterQuality: FilterQuality.none,
                      color: effectAccent,
                    )
                  else
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: effectAccent,
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: EndpointHighlightedValueText(
                      _effectDescription(effect),
                      tags: item.tags,
                      maxLines: null,
                      style: textMediumBold.copyWith(
                        color: effectAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _effectDescription(PatternEffect effect) =>
      _itemActionDescription(effect.actionEffect);

  String _effectIconAsset(ItemActionType actionType) => switch (actionType) {
        ItemActionType.attack => 'assets/images/icons/icon_sword.png',
        ItemActionType.block => 'assets/sprites/status/escudo.png',
        ItemActionType.heal => 'assets/sprites/status/vida.png',
        ItemActionType.none => 'assets/images/icons/icon_pattern.png',
      };
}

String _itemActionDescription(ActionEffect action) =>
    switch (action.actionType) {
      ItemActionType.attack => 'Ataca por ${action.totalValue} de daño',
      ItemActionType.block => 'Bloquea por ${action.totalValue} de barrera',
      ItemActionType.heal => 'Cúrate ${action.totalValue} de vida',
      ItemActionType.none => action.resolvedDescription!,
    };

class _PassiveEffectsContent extends StatelessWidget {
  final List<PassiveEffect> passives;
  final Iterable<EntityTag> tags;

  const _PassiveEffectsContent({
    required this.passives,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final descriptions = <String>[
      for (final passive in passives) _descriptionFor(passive),
    ];

    return EndpointHighlightedValueText(
      descriptions.join('\n\n'),
      tags: tags,
      maxLines: null,
      style: textMedium.copyWith(
        color: EndpointPalette.softForeground.withValues(alpha: 0.86),
        fontSize: 13,
        height: 1.35,
      ),
    );
  }

  String _descriptionFor(PassiveEffect effect) {
    return effect.resolvedDescription;
  }
}

class _ItemDialogStatusRow extends StatelessWidget {
  final Item item;
  final int price;
  final String priceLabel;
  final String statusText;
  final Color accent;

  const _ItemDialogStatusRow({
    required this.item,
    required this.price,
    required this.priceLabel,
    required this.statusText,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: EndpointHighlightedValueText(
            statusText,
            tags: item.tags,
            maxLines: null,
            style: textSmallBold.copyWith(
              color: accent,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
        ),
        if (price > 0) ...[
          EndpointText(
            priceLabel,
            style: textSmallBold.copyWith(
              color: EndpointPalette.warningAccent,
              fontSize: 9,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 6),
          EndpointCurrencyInline(
            value: price,
            iconColor: EndpointPalette.warningAccent,
            textColor: EndpointPalette.softForegroundWarm,
            iconSize: 13,
            spacing: 3,
            textStyle: textSmallNumericBold.copyWith(fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _GhostItemDetailBadge extends StatelessWidget {
  const _GhostItemDetailBadge();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'Objeto fantasma: debes devolverlo o pagar para fijarlo en la realidad.',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EndpointPalette.blend(
            EndpointPalette.panelBackgroundOpaque,
            RarityTier.purple.accent,
            0.2,
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: RarityTier.purple.accent.withValues(alpha: 0.72),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: EndpointText(
            '\u{1F47B} FANTASMA',
            style: textSmallBold.copyWith(
              color: EndpointPalette.soften(RarityTier.purple.accent),
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
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
    return <ItemArchetypeAffinity>[item.affinity];
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
      ItemArchetypeAffinity.imparable => const Color(0xFFFF5A5F),
      ItemArchetypeAffinity.mercante => const Color(0xFFEBCB5A),
    };
  }
}

class _ItemPatternBonusSection extends StatefulWidget {
  final Item item;

  const _ItemPatternBonusSection({
    required this.item,
  });

  @override
  State<_ItemPatternBonusSection> createState() =>
      _ItemPatternBonusSectionState();
}

class _ItemPatternBonusSectionState extends State<_ItemPatternBonusSection> {
  bool _isMatrixExpanded = false;

  void _toggleMatrix() {
    setState(() {
      _isMatrixExpanded = !_isMatrixExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final patternEffect = item.patternEffects.first;
    final requirement = patternEffect.patternType;
    final bonus = OperativePatternBonus(
      kind: switch (patternEffect.actionEffect.actionType) {
        ItemActionType.attack => OperativePatternBonusKind.attack,
        ItemActionType.block => OperativePatternBonusKind.barrier,
        ItemActionType.heal => OperativePatternBonusKind.health,
        ItemActionType.none => OperativePatternBonusKind.barrier,
      },
      amount: patternEffect.totalValue,
    );
    const adjacencyBonuses = <OperativePatternAdjacencyBonus>[];
    final accent = _bonusAccent(bonus.kind);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleMatrix,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
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
                    const SizedBox(width: 4),
                    Icon(
                      _isMatrixExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: accent,
                      size: 18,
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
                      child: EndpointHighlightedValueText(
                        '${requirement.label}: ${requirement.description}',
                        tags: item.tags,
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
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _ItemPatternRequirementPreview(
                      item: item,
                      requirement: requirement,
                      accent: EndpointPalette.patternAccent,
                    ),
                  ),
                  crossFadeState: _isMatrixExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 180),
                  sizeCurve: Curves.easeOutCubic,
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
        ),
      ),
    );
  }

  Color _bonusAccent(OperativePatternBonusKind kind) {
    return switch (kind) {
      OperativePatternBonusKind.attack => EndpointPalette.dangerAccent,
      OperativePatternBonusKind.barrier => BattlerStat.barrier.accent,
      OperativePatternBonusKind.health => BattlerStat.health.accent,
    };
  }

  String _bonusIconAssetPath(OperativePatternBonusKind kind) {
    return switch (kind) {
      OperativePatternBonusKind.attack => 'assets/images/icons/icon_sword.png',
      OperativePatternBonusKind.barrier => 'assets/sprites/status/escudo.png',
      OperativePatternBonusKind.health => 'assets/sprites/status/vida.png',
    };
  }
}

class _ItemPatternRequirementPreview extends StatefulWidget {
  final Item item;
  final OperativePatternRequirement requirement;
  final Color accent;

  const _ItemPatternRequirementPreview({
    required this.item,
    required this.requirement,
    required this.accent,
  });

  @override
  State<_ItemPatternRequirementPreview> createState() =>
      _ItemPatternRequirementPreviewState();
}

class _ItemPatternRequirementPreviewState
    extends State<_ItemPatternRequirementPreview> {
  static const _pointStepDuration = Duration(milliseconds: 260);
  static const _completedHoldDuration = Duration(seconds: 2);
  static const _clearedHoldDuration = Duration(milliseconds: 180);

  Timer? _timer;
  int _visiblePointCount = 0;
  int _variantIndex = 0;

  List<_PatternPreviewVariant> get _variants =>
      _PatternPreviewVariant.buildFor(widget.requirement);

  _PatternPreviewVariant get _activeVariant {
    final variants = _variants;
    return variants[_variantIndex % variants.length];
  }

  @override
  void initState() {
    super.initState();
    _scheduleNextStep(_clearedHoldDuration);
  }

  @override
  void didUpdateWidget(covariant _ItemPatternRequirementPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requirement == widget.requirement &&
        oldWidget.accent == widget.accent) {
      return;
    }

    _timer?.cancel();
    _visiblePointCount = 0;
    _variantIndex = 0;
    _scheduleNextStep(_clearedHoldDuration);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNextStep(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _advanceAnimation);
  }

  void _advanceAnimation() {
    if (!mounted) return;

    final path = _activeVariant.path;
    if (path.isEmpty) return;

    if (_visiblePointCount >= path.length) {
      setState(() {
        _visiblePointCount = 0;
        _variantIndex = (_variantIndex + 1) % _variants.length;
      });
      _scheduleNextStep(_clearedHoldDuration);
      return;
    }

    setState(() {
      _visiblePointCount++;
    });
    _scheduleNextStep(
      _visiblePointCount >= path.length
          ? _completedHoldDuration
          : _pointStepDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final variant = _activeVariant;
    final path = variant.path;
    if (path.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: _PatternRequirementMiniMatrix(
        item: widget.item,
        itemPoint: variant.itemPoint,
        visiblePath: path.take(_visiblePointCount).toList(growable: false),
        accent: widget.accent,
      ),
    );
  }
}

class _PatternPreviewVariant {
  final List<OperativePatternPoint> path;
  final OperativePatternPoint itemPoint;

  const _PatternPreviewVariant({
    required this.path,
    required this.itemPoint,
  });

  static List<_PatternPreviewVariant> buildFor(
    OperativePatternRequirement requirement,
  ) {
    return switch (requirement.kind) {
      OperativePatternRequirementKind.firstPoint => [
          _variant([
            const OperativePatternPoint(x: -1, y: 0),
            const OperativePatternPoint(x: 0, y: 0),
            const OperativePatternPoint(x: 1, y: 0),
          ], const OperativePatternPoint(x: -1, y: 0)),
          _variant([
            const OperativePatternPoint(x: 0, y: 1),
            const OperativePatternPoint(x: 0, y: 0),
            const OperativePatternPoint(x: 0, y: -1),
          ], const OperativePatternPoint(x: 0, y: 1)),
        ],
      OperativePatternRequirementKind.middlePoint => [
          _variant([
            const OperativePatternPoint(x: -1, y: 0),
            const OperativePatternPoint(x: 0, y: 0),
            const OperativePatternPoint(x: 1, y: 0),
          ], const OperativePatternPoint(x: 0, y: 0)),
          _variant([
            const OperativePatternPoint(x: -1, y: 1),
            const OperativePatternPoint(x: 0, y: 0),
            const OperativePatternPoint(x: 1, y: -1),
          ], const OperativePatternPoint(x: 0, y: 0)),
        ],
      OperativePatternRequirementKind.lastPoint => [
          _variant([
            const OperativePatternPoint(x: -1, y: 0),
            const OperativePatternPoint(x: 0, y: 0),
            const OperativePatternPoint(x: 1, y: 0),
          ], const OperativePatternPoint(x: 1, y: 0)),
          _variant([
            const OperativePatternPoint(x: 0, y: 1),
            const OperativePatternPoint(x: 0, y: 0),
            const OperativePatternPoint(x: 0, y: -1),
          ], const OperativePatternPoint(x: 0, y: -1)),
        ],
      OperativePatternRequirementKind.rightAngle => [
          _variant([
            const OperativePatternPoint(x: -1, y: 0),
            const OperativePatternPoint(x: 0, y: 0),
            const OperativePatternPoint(x: 0, y: 1),
          ], const OperativePatternPoint(x: 0, y: 0)),
          _variant([
            const OperativePatternPoint(x: 0, y: -1),
            const OperativePatternPoint(x: 0, y: 0),
            const OperativePatternPoint(x: 1, y: 0),
          ], const OperativePatternPoint(x: 0, y: 0)),
        ],
      OperativePatternRequirementKind.straightAngle => [
          _variant([
            const OperativePatternPoint(x: -1, y: 0),
            const OperativePatternPoint(x: 0, y: 0),
            const OperativePatternPoint(x: 1, y: 0),
          ], const OperativePatternPoint(x: 0, y: 0)),
          _variant([
            const OperativePatternPoint(x: -1, y: -1),
            const OperativePatternPoint(x: 0, y: 0),
            const OperativePatternPoint(x: 1, y: 1),
          ], const OperativePatternPoint(x: 0, y: 0)),
        ],
    };
  }

  static _PatternPreviewVariant _variant(
    List<OperativePatternPoint> points,
    OperativePatternPoint itemPoint,
  ) {
    return _PatternPreviewVariant(
      path: List<OperativePatternPoint>.unmodifiable(points),
      itemPoint: itemPoint,
    );
  }

}

class _PatternRequirementMiniMatrix extends StatelessWidget {
  final Item item;
  final OperativePatternPoint itemPoint;
  final List<OperativePatternPoint> visiblePath;
  final Color accent;

  const _PatternRequirementMiniMatrix({
    required this.item,
    required this.itemPoint,
    required this.visiblePath,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    const matrixSize = 100.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.panelBackgroundOpaque.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withValues(alpha: 0.34),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
        child: SizedBox(
          width: matrixSize,
          height: matrixSize,
          child: CustomPaint(
            painter: _PatternRequirementMiniMatrixPainter(
              item: item,
              itemPoint: itemPoint,
              visiblePath: visiblePath,
              accent: accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _PatternRequirementMiniMatrixPainter extends CustomPainter {
  final Item item;
  final OperativePatternPoint itemPoint;
  final List<OperativePatternPoint> visiblePath;
  final Color accent;

  const _PatternRequirementMiniMatrixPainter({
    required this.item,
    required this.itemPoint,
    required this.visiblePath,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const points = operativePatternPoints;
    final visibleKeys = visiblePath.map((point) => point.key).toSet();

    final lineOffsets = visiblePath.map((point) {
      return _centerFor(point, size);
    }).toList(growable: false);
    _drawPath(canvas, lineOffsets);

    for (final point in points) {
      final center = _centerFor(point, size);
      final isVisible = visibleKeys.contains(point.key);
      final isItemPoint = point == itemPoint;
      final ringPaint = Paint()
        ..color = isVisible
            ? (isItemPoint ? item.rarity.accent : accent).withValues(alpha: 0.9)
            : EndpointPalette.softForeground.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isItemPoint
            ? 2.1
            : isVisible
                ? 1.8
                : 1.1;
      final fillPaint = Paint()
        ..color = isItemPoint
            ? item.rarity.accent.withValues(alpha: isVisible ? 0.32 : 0.18)
            : isVisible
                ? accent.withValues(alpha: 0.24)
                : Colors.black.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, isItemPoint ? 7.2 : 5.8, fillPaint);
      canvas.drawCircle(center, isItemPoint ? 7.2 : 5.8, ringPaint);
      if (isItemPoint) {
        _drawItemGlyph(canvas, center);
      } else if (isVisible) {
        canvas.drawCircle(
          center,
          2.2,
          Paint()
            ..color = EndpointPalette.softForeground.withValues(alpha: 0.82),
        );
      }
    }
  }

  void _drawItemGlyph(Canvas canvas, Offset center) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: item.iconEmoji,
        style: const TextStyle(
          fontSize: 10,
          height: 1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawPath(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final corePaint = Paint()
      ..color = EndpointPalette.softForeground.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, corePaint);
  }

  Offset _centerFor(OperativePatternPoint point, Size size) {
    final usableWidth = max(1.0, size.width - 16);
    final usableHeight = max(1.0, size.height - 16);
    final column = point.x + 1;
    final row = 1 - point.y;
    final x = 8 + (column / 2) * usableWidth;
    final y = 8 + (row / 2) * usableHeight;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(
    covariant _PatternRequirementMiniMatrixPainter oldDelegate,
  ) {
    return oldDelegate.item != item ||
        oldDelegate.itemPoint != itemPoint ||
        oldDelegate.visiblePath != visiblePath ||
        oldDelegate.accent != accent;
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
