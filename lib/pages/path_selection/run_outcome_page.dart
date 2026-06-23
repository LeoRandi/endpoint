import '_imports.dart';

/// Pantalla final de la run que muestra el cierre de victoria o derrota antes de volver al menu.
class RunOutcomePage extends StatefulWidget {
  final RunCompletionType completionType;
  final Battler player;
  final RunDaySummary runSummary;

  /// Recibe el tipo de cierre y el estado final del jugador para pintar el resumen.
  const RunOutcomePage({
    super.key,
    required this.completionType,
    required this.player,
    required this.runSummary,
  });

  @override
  State<RunOutcomePage> createState() => _RunOutcomePageState();
}

class _RunOutcomePageState extends State<RunOutcomePage> {
  bool _areEnemiesExpanded = false;
  bool _areItemsExpanded = false;
  bool _areAbilitiesExpanded = false;
  bool _areStatsExpanded = false;

  /// Devuelve el acento visual dominante segun el tipo de cierre de run.
  Color get accent {
    switch (widget.completionType) {
      case RunCompletionType.victory:
        return EndpointPalette.rewardAccent;
      case RunCompletionType.defeat:
        return EndpointPalette.dangerAccent;
      case RunCompletionType.retreated:
        return EndpointPalette.infoAccent;
    }
  }

  /// Devuelve el titulo principal grande que remata la run.
  String get title {
    switch (widget.completionType) {
      case RunCompletionType.victory:
        return 'YOU WIN!';
      case RunCompletionType.defeat:
        return 'GAME OVER';
      case RunCompletionType.retreated:
        return 'RUN ENDED';
    }
  }

  /// Devuelve la linea descriptiva corta que contextualiza el cierre.
  String get description {
    switch (widget.completionType) {
      case RunCompletionType.victory:
        return 'Has completado el quinto dia y cerrado la run con vida.';
      case RunCompletionType.defeat:
        return 'La unidad ha quedado fuera de servicio antes de completar la run.';
      case RunCompletionType.retreated:
        return 'La retirada ha cerrado la operacion antes del final de la run.';
    }
  }

  /// Devuelve el emoji central usado para reforzar el tono del resultado final.
  String get emoji {
    switch (widget.completionType) {
      case RunCompletionType.victory:
        return '\u2600';
      case RunCompletionType.defeat:
        return '\u2620';
      case RunCompletionType.retreated:
        return '\u26A0';
    }
  }

  /// Cierra la pantalla final y devuelve el control a la pagina de ruta para volver al menu.
  void _close(BuildContext context) {
    Navigator.of(context).pop();
  }

  List<Item> get _runItems {
    final byId = <ItemId, Item>{};
    for (final reward in widget.runSummary.gainedRewards) {
      final item = reward.item;
      if (item == null) continue;
      _keepBestItem(byId, item);
    }
    for (final item in [
      ...widget.player.equippedItems,
      ...widget.player.inventoryItems,
    ]) {
      _keepBestItem(byId, item);
    }
    final items = byId.values.toList(growable: false);
    items.sort((a, b) {
      final rarityOrder = b.rarity.index.compareTo(a.rarity.index);
      if (rarityOrder != 0) return rarityOrder;
      return a.displayName.compareTo(b.displayName);
    });
    return items;
  }

  List<BattlerAbility> get _runAbilities {
    final byId = <BattlerAbilityId, BattlerAbility>{};
    for (final reward in widget.runSummary.gainedRewards) {
      final ability = reward.ability;
      if (ability == null) continue;
      _keepBestAbility(byId, ability);
    }
    for (final ability in widget.player.abilities) {
      _keepBestAbility(byId, ability);
    }
    final abilities = byId.values.toList(growable: false);
    abilities.sort((a, b) {
      final rarityOrder = b.rarity.index.compareTo(a.rarity.index);
      if (rarityOrder != 0) return rarityOrder;
      return a.displayName.compareTo(b.displayName);
    });
    return abilities;
  }

  void _keepBestItem(Map<ItemId, Item> byId, Item item) {
    final current = byId[item.id];
    if (current == null || item.rarity.index > current.rarity.index) {
      byId[item.id] = item;
    }
  }

  void _keepBestAbility(
    Map<BattlerAbilityId, BattlerAbility> byId,
    BattlerAbility ability,
  ) {
    final current = byId[ability.id];
    if (current == null ||
        ability.rarity.index > current.rarity.index ||
        ability.value > current.value) {
      byId[ability.id] = ability;
    }
  }

  @override
  Widget build(BuildContext context) {
    final runItems = _runItems;
    final runAbilities = _runAbilities;
    final defeatedEnemies = widget.runSummary.defeatedEnemies;

    return Scaffold(
      body: NodeSceneWrapper(
        showTitle: title,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: EndpointGradients.event(accent),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: EndpointSceneCloseButton(
                      onPressed: () => _close(context),
                      tooltip: 'Volver al menu',
                      accent: accent,
                    ),
                  ),
                  const Spacer(),
                  _RunOutcomeHeader(
                    title: title,
                    emoji: emoji,
                    accent: accent,
                    completionType: widget.completionType,
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.58,
                    ),
                    child: EndpointPanel(
                      accent: accent,
                      backgroundColor: EndpointPalette.panelBackgroundSoft,
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EndpointText(
                              description,
                              textAlign: TextAlign.center,
                              maxLines: null,
                              style: textMedium.copyWith(
                                color: EndpointPalette.softForeground
                                    .withAlpha(214),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _RunOutcomePatternBoard(player: widget.player),
                            const SizedBox(height: 14),
                            _RunOutcomeCollectionSection(
                              title: 'Estadisticas',
                              count: 6,
                              emptyText: 'Sin estadisticas registradas.',
                              collapsedText: '6 stats ocultas',
                              isExpanded: _areStatsExpanded,
                              onToggle: () {
                                setState(() {
                                  _areStatsExpanded = !_areStatsExpanded;
                                });
                              },
                              children: [
                                EndpointValueChip(
                                  label: 'LV',
                                  value: widget.player.level,
                                  accent: accent,
                                  foreground: EndpointPalette.softForeground,
                                ),
                                EndpointValueChip(
                                  label: 'ATK',
                                  value: widget.player.attack,
                                  accent: accent,
                                  foreground: EndpointPalette.softForeground,
                                ),
                                EndpointValueChip(
                                  label: 'BAR',
                                  value: widget.player.barrier,
                                  accent: BattlerStat.barrier.accent,
                                  foreground: EndpointPalette.softForeground,
                                ),
                                EndpointValueChip(
                                  label: 'HP',
                                  value: widget.player.maxHealth,
                                  accent: accent,
                                  foreground: EndpointPalette.softForeground,
                                ),
                                EndpointValueChip(
                                  label: 'INC',
                                  value: widget.player.income,
                                  accent: accent,
                                  foreground: EndpointPalette.softForeground,
                                ),
                                EndpointValueChip(
                                  icon: Icons.monetization_on_rounded,
                                  value: widget.player.money,
                                  accent: EndpointPalette.warningAccent,
                                  foreground:
                                      EndpointPalette.softForegroundWarm,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _RunOutcomeCollectionSection(
                              title: 'Enemigos de la run',
                              count: defeatedEnemies.length,
                              emptyText: 'Ningun enemigo registrado.',
                              isExpanded: _areEnemiesExpanded,
                              onToggle: () {
                                setState(() {
                                  _areEnemiesExpanded = !_areEnemiesExpanded;
                                });
                              },
                              children: defeatedEnemies
                                  .map(
                                    (enemy) => _RunOutcomePill(
                                      label: enemy.name,
                                      leading: enemy.iconEmoji,
                                      accent: enemy.rarity.accent,
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 10),
                            _RunOutcomeCollectionSection(
                              title: 'Objetos de la run',
                              count: runItems.length,
                              emptyText: 'Ningun objeto registrado.',
                              isExpanded: _areItemsExpanded,
                              onToggle: () {
                                setState(() {
                                  _areItemsExpanded = !_areItemsExpanded;
                                });
                              },
                              children: runItems
                                  .map(
                                    (item) => _RunOutcomePill(
                                      label: item.displayName,
                                      leading: item.iconEmoji,
                                      accent: item.rarity.accent,
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 10),
                            _RunOutcomeCollectionSection(
                              title: 'Aumentos de la run',
                              count: runAbilities.length,
                              emptyText: 'Ningun aumento registrado.',
                              isExpanded: _areAbilitiesExpanded,
                              onToggle: () {
                                setState(() {
                                  _areAbilitiesExpanded =
                                      !_areAbilitiesExpanded;
                                });
                              },
                              children: runAbilities
                                  .map(
                                    (ability) => _RunOutcomePill(
                                      label: ability.displayName,
                                      icon: Icons.auto_awesome_rounded,
                                      accent: ability.rarity.accent,
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: EndpointActionButton(
                                label: 'Volver al menu',
                                icon: Icons.home_rounded,
                                onPressed: () => _close(context),
                                tooltip:
                                    'Cerrar la run y volver al menu principal',
                                accent: accent,
                                backgroundColor:
                                    EndpointPalette.closeButtonBackground,
                                foregroundColor: EndpointPalette.softForeground,
                                expands: true,
                                useMarquee: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RunOutcomeHeader extends StatelessWidget {
  final String title;
  final String emoji;
  final Color accent;
  final RunCompletionType completionType;

  const _RunOutcomeHeader({
    required this.title,
    required this.emoji,
    required this.accent,
    required this.completionType,
  });

  @override
  Widget build(BuildContext context) {
    if (completionType != RunCompletionType.victory) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EndpointEmojiSprite(
            emoji: emoji,
            accent: accent,
            size: 138,
          ),
          const SizedBox(height: 12),
          EndpointText(
            title,
            textAlign: TextAlign.center,
            style: textLargeBold.copyWith(
              color: accent,
              letterSpacing: 2.1,
            ),
          ),
        ],
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _VictoryTitleWord(
              text: 'YOU',
              accent: accent,
              textAlign: TextAlign.right,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: EndpointEmojiSprite(
              emoji: emoji,
              accent: accent,
              size: 138,
            ),
          ),
          Expanded(
            child: _VictoryTitleWord(
              text: 'WIN!',
              accent: accent,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _VictoryTitleWord extends StatelessWidget {
  final String text;
  final Color accent;
  final TextAlign textAlign;

  const _VictoryTitleWord({
    required this.text,
    required this.accent,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: textAlign == TextAlign.right
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: EndpointText(
        text,
        textAlign: textAlign,
        maxLines: 1,
        style: textLargeBold.copyWith(
          color: accent,
          fontSize: 40,
          letterSpacing: 2.1,
          shadows: [
            Shadow(
              color: accent.withValues(alpha: 0.32),
              blurRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _RunOutcomeCollectionSection extends StatelessWidget {
  final String title;
  final int count;
  final String emptyText;
  final String? collapsedText;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _RunOutcomeCollectionSection({
    required this.title,
    required this.count,
    required this.emptyText,
    this.collapsedText,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: EndpointText(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textSmallBold.copyWith(
                        color: EndpointPalette.softForeground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  EndpointText(
                    '$count',
                    maxLines: 1,
                    style: textSmallNumericBold.copyWith(
                      color: EndpointPalette.softForeground.withAlpha(196),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: EndpointPalette.softForeground.withAlpha(210),
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (children.isEmpty)
          EndpointText(
            emptyText,
            maxLines: null,
            style: textSmall.copyWith(
              color: EndpointPalette.softForeground.withAlpha(168),
            ),
          )
        else if (isExpanded)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: children,
          )
        else
          EndpointText(
            collapsedText ?? '$count entradas ocultas',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textSmall.copyWith(
              color: EndpointPalette.softForeground.withAlpha(142),
            ),
          ),
      ],
    );
  }
}

class _RunOutcomePatternBoard extends StatelessWidget {
  final Battler player;

  const _RunOutcomePatternBoard({
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final layout = OperativePatternLayoutService.resolveForPlayer(
      player: player,
      random: Random(0),
    );
    final contentsByPointKey = <String, OperativePatternPointContent>{
      for (final entry in layout.itemsByPointKey.entries)
        entry.key: OperativePatternPointContent(
          item: entry.value,
          bonus: entry.value.hasPatternBonus ? entry.value.patternBonus : null,
          requirement: entry.value.hasPatternBonus
              ? entry.value.patternRequirement
              : null,
          adjacencyBonuses: entry.value.patternAdjacencyBonuses,
          hasAura: entry.value.hasPatternAura,
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EndpointText(
          'Tablero final',
          style: textSmallBold.copyWith(
            color: EndpointPalette.patternAccent,
          ),
        ),
        AspectRatio(
          aspectRatio: 1,
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.68,
              heightFactor: 0.68,
              child: Transform.rotate(
                angle: pi / 4,
                child: OperativePatternBoard(
                  contentsByPointKey: contentsByPointKey,
                  reinforcedPointKey: player.reinforcedPatternPointKey,
                  isPatternInputEnabled: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RunOutcomePill extends StatelessWidget {
  final String label;
  final String? leading;
  final IconData? icon;
  final Color accent;

  const _RunOutcomePill({
    required this.label,
    this.leading,
    this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.blend(
          EndpointPalette.panelBackgroundSoft,
          accent,
          0.18,
        ),
        border: Border.all(
          color: accent.withAlpha(172),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null && leading!.isNotEmpty) ...[
              EndpointText(
                leading!,
                style: textSmall,
              ),
              const SizedBox(width: 5),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: accent,
              ),
              const SizedBox(width: 5),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 168),
              child: EndpointText(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textSmall.copyWith(
                  color: EndpointPalette.softForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
