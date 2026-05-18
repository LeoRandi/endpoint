import '../_imports.dart';

/// Pantalla final de la run que muestra el cierre de victoria o derrota antes de volver al menu.
class RunOutcomePage extends StatelessWidget {
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

  /// Devuelve el acento visual dominante segun el tipo de cierre de run.
  Color get accent {
    switch (completionType) {
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
    switch (completionType) {
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
    switch (completionType) {
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
    switch (completionType) {
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
    for (final reward in runSummary.gainedRewards) {
      final item = reward.item;
      if (item == null) continue;
      _keepBestItem(byId, item);
    }
    for (final item in [
      ...player.equippedItems,
      ...player.inventoryItems,
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
    for (final reward in runSummary.gainedRewards) {
      final ability = reward.ability;
      if (ability == null) continue;
      _keepBestAbility(byId, ability);
    }
    for (final ability in player.abilities) {
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
    final defeatedEnemies = runSummary.defeatedEnemies;

    return EndpointCenterStageScene(
      showTitle: title,
      background: EndpointGradients.event(accent),
      onClose: () => _close(context),
      closeTooltip: 'Volver al menu',
      accent: accent,
      emoji: emoji,
      title: title,
      titleColor: accent,
      content: ConstrainedBox(
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
                    color: EndpointPalette.softForeground.withAlpha(214),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    EndpointValueChip(
                      label: 'LV',
                      value: player.level,
                      accent: accent,
                      foreground: EndpointPalette.softForeground,
                    ),
                    EndpointValueChip(
                      label: 'ATK',
                      value: player.attack,
                      accent: accent,
                      foreground: EndpointPalette.softForeground,
                    ),
                    EndpointValueChip(
                      label: 'BAR',
                      value: player.barrier,
                      accent: BattlerStat.barrier.accent,
                      foreground: EndpointPalette.softForeground,
                    ),
                    EndpointValueChip(
                      label: 'HP',
                      value: player.maxHealth,
                      accent: accent,
                      foreground: EndpointPalette.softForeground,
                    ),
                    EndpointValueChip(
                      label: 'INC',
                      value: player.income,
                      accent: accent,
                      foreground: EndpointPalette.softForeground,
                    ),
                    EndpointValueChip(
                      icon: Icons.monetization_on_rounded,
                      value: player.money,
                      accent: EndpointPalette.warningAccent,
                      foreground: EndpointPalette.softForegroundWarm,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    EndpointValueChip(
                      label: 'ENEMIGOS',
                      value: defeatedEnemies.length,
                      accent: EndpointPalette.dangerAccent,
                      foreground: EndpointPalette.softForeground,
                    ),
                    EndpointValueChip(
                      label: 'OBJETOS',
                      value: runItems.length,
                      accent: EndpointPalette.rewardAccent,
                      foreground: EndpointPalette.softForeground,
                    ),
                    EndpointValueChip(
                      label: 'AUMENTOS',
                      value: runAbilities.length,
                      accent: EndpointPalette.infoAccent,
                      foreground: EndpointPalette.softForeground,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _RunOutcomeCollectionSection(
                  title: 'Enemigos de la run',
                  emptyText: 'Ningun enemigo registrado.',
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
                  emptyText: 'Ningun objeto registrado.',
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
                  emptyText: 'Ningun aumento registrado.',
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
                    tooltip: 'Cerrar la run y volver al menu principal',
                    accent: accent,
                    backgroundColor: EndpointPalette.closeButtonBackground,
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
    );
  }
}

class _RunOutcomeCollectionSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<Widget> children;

  const _RunOutcomeCollectionSection({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EndpointText(
          title,
          style: textSmallBold.copyWith(
            color: EndpointPalette.softForeground,
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
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: children,
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
