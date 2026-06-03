import '../_imports.dart';
import 'package:showcaseview/showcaseview.dart';

/// Muestra el detalle completo de un arquetipo antes de aplicarlo al jugador.
class ArchetypeSelectionDialog extends StatefulWidget {
  final Battler player;
  final ArchetypePathNode archetype;
  final Battler projectedPlayer;
  final bool isTutorialRun;

  const ArchetypeSelectionDialog({
    super.key,
    required this.player,
    required this.archetype,
    required this.projectedPlayer,
    this.isTutorialRun = false,
  });

  @override
  State<ArchetypeSelectionDialog> createState() =>
      _ArchetypeSelectionDialogState();
}

class _ArchetypeSelectionDialogState extends State<ArchetypeSelectionDialog> {
  static const _tutorialShowcaseScope = 'archetype_selection.tutorial';

  final GlobalKey _dialogShowcaseKey = GlobalKey();
  final GlobalKey _confirmShowcaseKey = GlobalKey();
  ShowcaseView? _tutorialShowcase;

  @override
  void initState() {
    super.initState();
    if (!widget.isTutorialRun) return;

    _tutorialShowcase = ShowcaseView.register(
      scope: _tutorialShowcaseScope,
      disableBarrierInteraction: true,
      disableMovingAnimation: false,
      disableScaleAnimation: false,
      blurValue: 0,
      skipIfTargetNotPresent: true,
      globalTooltipActionConfig: const TooltipActionConfig(
        alignment: MainAxisAlignment.end,
        actionGap: 8,
        position: TooltipActionPosition.inside,
      ),
      globalTooltipActions: [
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: 'SIGUIENTE',
          backgroundColor: EndpointPalette.blend(
            EndpointPalette.panelBackgroundBattle,
            EndpointPalette.infoAccent,
            0.22,
          ),
          textStyle: textSmallBold.copyWith(
            color: EndpointPalette.softForegroundWarm,
            letterSpacing: 0.8,
          ),
          border: Border.all(
            color: EndpointPalette.infoAccent.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
    _scheduleTutorialShowcase();
  }

  @override
  void dispose() {
    _tutorialShowcase?.unregister();
    super.dispose();
  }

  void _scheduleTutorialShowcase() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;

        _tutorialShowcase?.startShowCase([
          _dialogShowcaseKey,
          _confirmShowcaseKey,
        ]);
      });
    });
  }

  void _confirmArchetype() {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final archetype = widget.archetype;
    final accent = archetype.accent;
    final foreground = EndpointPalette.soften(accent);
    final screenSize = MediaQuery.sizeOf(context);
    final impactEntries = _buildImpactEntries();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: min(560, screenSize.width - 36),
            maxHeight: screenSize.height * 0.86,
          ),
          child: _buildDialogShowcase(
            child: EndpointPanel(
              accent: accent,
              backgroundColor: EndpointPalette.panelBackgroundOpaque,
              borderRadius: 20,
              glowOpacity: 0.12,
              blurRadius: 26,
              spreadRadius: 2,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ArchetypeHeader(
                              archetype: archetype,
                              foreground: foreground,
                            ),
                            const SizedBox(height: 12),
                            _ArchetypeSectionHeader(
                              title: 'DESCRIPCION',
                              caption: archetype.badgeLabel,
                              accent: accent,
                            ),
                            const SizedBox(height: 6),
                            EndpointPanel(
                              accent: accent,
                              backgroundColor: EndpointPalette.blend(
                                EndpointPalette.panelBackgroundGold,
                                accent,
                                0.1,
                              ),
                              borderRadius: 14,
                              glowOpacity: 0.04,
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                              child: EndpointText(
                                archetype.tooltip,
                                maxLines: null,
                                style: textMedium.copyWith(
                                  color:
                                      EndpointPalette.softForeground.withAlpha(
                                    219,
                                  ),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _ArchetypeSectionHeader(
                              title: 'IMPACTO TOTAL',
                              caption: '${impactEntries.length} CAMBIOS',
                              accent: accent,
                            ),
                            const SizedBox(height: 6),
                            if (impactEntries.isEmpty)
                              const _ArchetypeEmptyState(
                                message:
                                    'Este arquetipo no altera ninguna stat del operativo actual.',
                              )
                            else
                              Column(
                                children: [
                                  for (int index = 0;
                                      index < impactEntries.length;
                                      index++) ...[
                                    if (index > 0) const SizedBox(height: 8),
                                    _ArchetypeImpactCard(
                                      entry: impactEntries[index],
                                      accent: accent,
                                    ),
                                  ],
                                ],
                              ),
                            const SizedBox(height: 14),
                            _ArchetypeSectionHeader(
                              title: 'OBJETOS INICIALES',
                              caption: '${archetype.startingItems.length}',
                              accent: accent,
                            ),
                            const SizedBox(height: 6),
                            if (archetype.startingItems.isEmpty)
                              const _ArchetypeEmptyState(
                                message: 'No entrega objetos iniciales.',
                              )
                            else
                              Column(
                                children: [
                                  for (int index = 0;
                                      index < archetype.startingItems.length;
                                      index++) ...[
                                    if (index > 0) const SizedBox(height: 10),
                                    _ArchetypeItemCard(
                                      item: archetype.startingItems[index],
                                    ),
                                  ],
                                ],
                              ),
                            const SizedBox(height: 14),
                            _ArchetypeSectionHeader(
                              title: 'AUMENTOS',
                              caption: '${archetype.startingAbilities.length}',
                              accent: accent,
                            ),
                            const SizedBox(height: 6),
                            if (archetype.startingAbilities.isEmpty)
                              const _ArchetypeEmptyState(
                                message: 'No entrega aumentos iniciales.',
                              )
                            else
                              Column(
                                children: [
                                  for (int index = 0;
                                      index <
                                          archetype.startingAbilities.length;
                                      index++) ...[
                                    if (index > 0) const SizedBox(height: 10),
                                    _ArchetypeAbilityCard(
                                      ability:
                                          archetype.startingAbilities[index],
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: accent.withAlpha(92),
                        ),
                      ),
                      color: EndpointPalette.blend(
                        EndpointPalette.panelBackgroundGold,
                        accent,
                        0.08,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: EndpointActionButton(
                              label: 'Volver',
                              icon: Icons.arrow_back_rounded,
                              onPressed: () => Navigator.of(context).pop(false),
                              tooltip: 'Volver a la seleccion de arquetipo',
                              accent: EndpointPalette.softForeground,
                              backgroundColor:
                                  EndpointPalette.closeButtonBackground,
                              foregroundColor: EndpointPalette.softForeground,
                              expands: true,
                              useMarquee: false,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildConfirmButton(
                              accent: accent,
                              foreground: foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogShowcase({
    required Widget child,
  }) {
    if (!widget.isTutorialRun) return child;

    return Showcase(
      key: _dialogShowcaseKey,
      scope: _tutorialShowcaseScope,
      title: 'Arquetipo',
      description:
          'El arquetipo dicta gran parte de los objetos y aumentos con los que interactuaras durante una partida.',
      targetBorderRadius: BorderRadius.circular(20),
      targetPadding: const EdgeInsets.all(4),
      overlayColor: EndpointPalette.overlayScrimStrong,
      overlayOpacity: 0.9,
      tooltipPosition: TooltipPosition.top,
      tooltipBackgroundColor: EndpointPalette.panelBackgroundOpaque,
      tooltipBorderRadius: BorderRadius.circular(12),
      tooltipPadding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      titleTextStyle: textMediumBold.copyWith(
        color: EndpointPalette.infoAccent,
        letterSpacing: 1.1,
      ),
      descTextStyle: textSmallBold.copyWith(
        color: EndpointPalette.softForeground,
        fontSize: 14,
        letterSpacing: 0.4,
        height: 1.25,
      ),
      textColor: EndpointPalette.softForeground,
      disableDefaultTargetGestures: true,
      disableBarrierInteraction: true,
      movingAnimationDuration: const Duration(milliseconds: 240),
      child: child,
    );
  }

  Widget _buildConfirmButton({
    required Color accent,
    required Color foreground,
  }) {
    final button = EndpointActionButton(
      label: widget.isTutorialRun ? 'Continuar' : 'Aceptar',
      icon: Icons.check_rounded,
      onPressed: _confirmArchetype,
      tooltip: 'Aplicar arquetipo y avanzar',
      accent: accent,
      backgroundColor: EndpointPalette.blend(
        EndpointPalette.panelBackgroundGold,
        accent,
        0.18,
      ),
      foregroundColor: foreground,
      expands: true,
      useMarquee: false,
    );
    if (!widget.isTutorialRun) return button;

    return Showcase(
      key: _confirmShowcaseKey,
      scope: _tutorialShowcaseScope,
      title: 'Continuar',
      description: 'Elijamos el arquetipo Imparable',
      targetBorderRadius: BorderRadius.circular(12),
      targetPadding: const EdgeInsets.all(6),
      overlayColor: EndpointPalette.overlayScrimStrong,
      overlayOpacity: 0.9,
      tooltipPosition: TooltipPosition.top,
      tooltipBackgroundColor: EndpointPalette.panelBackgroundOpaque,
      tooltipBorderRadius: BorderRadius.circular(12),
      tooltipPadding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      titleTextStyle: textMediumBold.copyWith(
        color: EndpointPalette.infoAccent,
        letterSpacing: 1.1,
      ),
      descTextStyle: textSmallBold.copyWith(
        color: EndpointPalette.softForeground,
        fontSize: 14,
        letterSpacing: 0.4,
        height: 1.25,
      ),
      textColor: EndpointPalette.softForeground,
      disableDefaultTargetGestures: false,
      disableBarrierInteraction: true,
      movingAnimationDuration: const Duration(milliseconds: 240),
      onTargetClick: _confirmArchetype,
      disposeOnTap: true,
      tooltipActions: const [],
      child: button,
    );
  }

  // Mercante mantiene placeholders aqui; su stock real se resuelve al aceptar.
  List<_ArchetypeImpactEntry> _buildImpactEntries() {
    final player = widget.player;
    final projectedPlayer = widget.projectedPlayer;
    final entries = <_ArchetypeImpactEntry>[
      _ArchetypeImpactEntry(
        label: 'HP MAX',
        currentValue: player.maxHealth,
        nextValue: projectedPlayer.maxHealth,
      ),
      _ArchetypeImpactEntry(
        label: 'ATK',
        currentValue: player.attack,
        nextValue: projectedPlayer.attack,
      ),
      _ArchetypeImpactEntry(
        label: 'Barrera',
        currentValue: player.barrier,
        nextValue: projectedPlayer.barrier,
        accent: BattlerStat.barrier.accent,
      ),
      _ArchetypeImpactEntry(
        label: 'ESPINAS',
        currentValue: player.thorns,
        nextValue: projectedPlayer.thorns,
      ),
      _ArchetypeImpactEntry(
        label: 'RED. DAÑO',
        currentValue: player.damageReduction,
        nextValue: projectedPlayer.damageReduction,
      ),
      _ArchetypeImpactEntry(
        label: 'VAMPIRISMO',
        currentValue: player.vampirism,
        nextValue: projectedPlayer.vampirism,
      ),
      _ArchetypeImpactEntry(
        label: 'CREDITOS',
        currentValue: player.money,
        nextValue: projectedPlayer.money,
      ),
      _ArchetypeImpactEntry(
        label: 'INCOME',
        currentValue: player.income,
        nextValue: projectedPlayer.income,
      ),
    ];

    return List<_ArchetypeImpactEntry>.unmodifiable(
      entries.where((entry) => entry.delta != 0),
    );
  }
}

class _ArchetypeHeader extends StatelessWidget {
  final ArchetypePathNode archetype;
  final Color foreground;

  const _ArchetypeHeader({
    required this.archetype,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EndpointEmojiSprite(
          emoji: archetype.playerIconEmoji,
          accent: archetype.accent,
          size: 82,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EndpointText(
                archetype.label,
                maxLines: null,
                style: textLargeBold.copyWith(
                  color: foreground,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              EndpointText(
                'ARQUETIPO INICIAL',
                maxLines: null,
                style: textSmallBold.copyWith(
                  color: archetype.accent,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              EndpointText(
                'Revisa el loadout completo antes de confirmarlo.',
                maxLines: null,
                style: textSmallBold.copyWith(
                  color: EndpointPalette.softForeground.withAlpha(194),
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArchetypeSectionHeader extends StatelessWidget {
  final String title;
  final String caption;
  final Color accent;

  const _ArchetypeSectionHeader({
    required this.title,
    required this.caption,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: EndpointText(
            title,
            style: textMediumBold.copyWith(
              color: EndpointPalette.softForeground,
              letterSpacing: 1.4,
            ),
          ),
        ),
        EndpointText(
          caption,
          style: textSmallBold.copyWith(
            color: accent,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ArchetypeEmptyState extends StatelessWidget {
  final String message;

  const _ArchetypeEmptyState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      backgroundColor: EndpointPalette.panelBackgroundSoft,
      borderRadius: 14,
      glowOpacity: 0.02,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Center(
        child: EndpointText(
          message,
          textAlign: TextAlign.center,
          maxLines: null,
          style: textSmallBold.copyWith(
            color: EndpointPalette.softForeground.withAlpha(184),
            letterSpacing: 0.7,
          ),
        ),
      ),
    );
  }
}

class _ArchetypeImpactEntry {
  final String label;
  final int currentValue;
  final int nextValue;
  final Color? accent;

  const _ArchetypeImpactEntry({
    required this.label,
    required this.currentValue,
    required this.nextValue,
    this.accent,
  });

  int get delta => nextValue - currentValue;

  String get deltaLabel {
    final sign = delta >= 0 ? '+' : '';
    return '$sign$delta';
  }

  String get flowLabel => '$currentValue -> $nextValue';
}

class _ArchetypeImpactCard extends StatelessWidget {
  final _ArchetypeImpactEntry entry;
  final Color accent;

  const _ArchetypeImpactCard({
    required this.entry,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final deltaAccent = entry.delta >= 0
        ? (entry.accent ?? accent)
        : EndpointPalette.dangerAccent;

    return EndpointPanel(
      accent: deltaAccent,
      backgroundColor: EndpointPalette.blend(
        EndpointPalette.panelBackgroundSoft,
        deltaAccent,
        0.1,
      ),
      borderRadius: 14,
      glowOpacity: 0.03,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EndpointText(
                  entry.label,
                  style: textSmallBold.copyWith(
                    color: EndpointPalette.softForeground,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                EndpointText(
                  entry.flowLabel,
                  style: textSmallNumericBold.copyWith(
                    color: Colors.white.withAlpha(168),
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          EndpointText(
            entry.deltaLabel,
            style: textMediumNumericBold.copyWith(
              color: deltaAccent,
              fontSize: 15,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchetypeItemCard extends StatelessWidget {
  final Item item;

  const _ArchetypeItemCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final accent = item.rarity.accent;
    final modifiersText = _buildModifiersText(item);

    return EndpointPanel(
      accent: accent,
      backgroundColor: EndpointPalette.blend(
        EndpointPalette.panelBackgroundSoft,
        accent,
        0.12,
      ),
      borderRadius: 14,
      glowOpacity: 0.04,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EndpointEmojiSprite(
            emoji: item.iconEmoji,
            accent: accent,
            size: 54,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EndpointText(
                  item.displayName,
                  maxLines: null,
                  style: textMediumBold.copyWith(
                    color: EndpointPalette.softForeground,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                EndpointHighlightedValueText(
                  item.displayDescription,
                  tags: item.tags,
                  maxLines: null,
                  style: textSmallBold.copyWith(
                    color: Colors.white.withAlpha(196),
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
                if (modifiersText != null) ...[
                  const SizedBox(height: 6),
                  EndpointText(
                    modifiersText,
                    maxLines: null,
                    style: textSmallNumericBold.copyWith(
                      color: accent,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _buildModifiersText(Item item) {
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

    if (entries.isEmpty) return null;

    return entries.join('   ');
  }

  String _modifierLabel(BattlerStat stat) {
    if (stat == BattlerStat.barrier) {
      return stat.label;
    }

    return stat.shortLabel;
  }
}

class _ArchetypeAbilityCard extends StatelessWidget {
  final BattlerAbility ability;

  const _ArchetypeAbilityCard({
    required this.ability,
  });

  @override
  Widget build(BuildContext context) {
    final accent = ability.accent;
    final activationLabel = ability.manualActivationContext?.label ?? 'Pasiva';

    return EndpointPanel(
      accent: accent,
      backgroundColor: EndpointPalette.blend(
        EndpointPalette.panelBackgroundSoft,
        accent,
        0.12,
      ),
      borderRadius: 14,
      glowOpacity: 0.04,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Center(
              child: EndpointAbilityOrb(
                ability: ability,
                size: 52,
                enableTooltipLongPress: false,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EndpointText(
                  ability.displayName,
                  maxLines: null,
                  style: textMediumBold.copyWith(
                    color: EndpointPalette.softForeground,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                EndpointText(
                  '${ability.rarity.label}  |  $activationLabel',
                  maxLines: null,
                  style: textSmallBold.copyWith(
                    color: accent,
                    fontSize: 10,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                EndpointHighlightedValueText(
                  ability.displayDescription,
                  tags: ability.tags,
                  maxLines: null,
                  style: textSmallBold.copyWith(
                    color: Colors.white.withAlpha(196),
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                EndpointText(
                  _buildAbilitySummary(ability),
                  maxLines: null,
                  style: textSmallNumericBold.copyWith(
                    color: accent,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildAbilitySummary(BattlerAbility ability) {
    final parts = <String>[
      'POTENCIA ${ability.currentValue}',
    ];

    if (ability.upgradeValue > 0) {
      parts.add('MEJORA +${ability.upgradeValue}');
    }

    parts.add('COOLDOWN ${ability.cooldownLabel}');

    return parts.join('   ');
  }
}
