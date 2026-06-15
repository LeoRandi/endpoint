import '../_imports.dart';

class RunDaySummaryPage extends StatefulWidget {
  final RunDaySummary summary;
  final Battler player;

  const RunDaySummaryPage({
    super.key,
    required this.summary,
    required this.player,
  });

  @override
  State<RunDaySummaryPage> createState() => _RunDaySummaryPageState();
}

class _RunDaySummaryPageState extends State<RunDaySummaryPage>
    with SingleTickerProviderStateMixin {
  bool _areItemRewardsExpanded = false;
  bool _areAbilityRewardsExpanded = false;
  bool _areEnemiesExpanded = false;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue(BuildContext context) {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    const accent = EndpointPalette.rewardAccent;
    final itemRewards = widget.summary.gainedRewards
        .where((reward) => reward.type == RunDaySummaryRewardType.item)
        .toList(growable: false);
    final abilityRewards = widget.summary.gainedRewards
        .where((reward) => reward.type == RunDaySummaryRewardType.ability)
        .toList(growable: false);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: NodeSceneWrapper(
          showTitle: 'Resumen del dia ${widget.summary.dayNumber}',
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: EndpointGradients.path,
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight < 680;
                  final spacing = isCompact ? 6.0 : 8.0;
                  final horizontalPadding =
                      constraints.maxWidth < 390 ? 8.0 : 12.0;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      spacing,
                      horizontalPadding,
                      spacing,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Column(
                          children: [
                            Expanded(
                              flex: isCompact ? 27 : 30,
                              child: _AnimatedSummaryBlock(
                                controller: _controller,
                                index: 0,
                                child: _SummaryHeroBlock(
                                  summary: widget.summary,
                                  player: widget.player,
                                  isCompact: isCompact,
                                ),
                              ),
                            ),
                            SizedBox(height: spacing),
                            Expanded(
                              flex: isCompact ? 19 : 20,
                              child: _AnimatedSummaryBlock(
                                controller: _controller,
                                index: 1,
                                child: _SummaryRewardsBlock(
                                  title: 'OBJETOS OBTENIDOS',
                                  caption: '${itemRewards.length}',
                                  icon: Icons.inventory_2_rounded,
                                  rewards: itemRewards,
                                  dayNumber: widget.summary.dayNumber,
                                  emptyText: 'No se han obtenido objetos.',
                                  accent: EndpointPalette.shopAccent,
                                  isExpanded: _areItemRewardsExpanded,
                                  onToggle: () {
                                    setState(() {
                                      _areItemRewardsExpanded =
                                          !_areItemRewardsExpanded;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: spacing),
                            Expanded(
                              flex: isCompact ? 19 : 20,
                              child: _AnimatedSummaryBlock(
                                controller: _controller,
                                index: 2,
                                child: _SummaryRewardsBlock(
                                  title: 'AUMENTOS APRENDIDOS',
                                  caption: '${abilityRewards.length}',
                                  icon: Icons.auto_awesome_rounded,
                                  rewards: abilityRewards,
                                  dayNumber: widget.summary.dayNumber,
                                  emptyText: 'No se han aprendido aumentos.',
                                  accent: EndpointPalette.infoAccent,
                                  isExpanded: _areAbilityRewardsExpanded,
                                  onToggle: () {
                                    setState(() {
                                      _areAbilityRewardsExpanded =
                                          !_areAbilityRewardsExpanded;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: spacing),
                            Expanded(
                              flex: isCompact ? 17 : 18,
                              child: _AnimatedSummaryBlock(
                                controller: _controller,
                                index: 3,
                                child: _SummaryEnemiesBlock(
                                  summary: widget.summary,
                                  isExpanded: _areEnemiesExpanded,
                                  onToggle: () {
                                    setState(() {
                                      _areEnemiesExpanded =
                                          !_areEnemiesExpanded;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: spacing),
                            _AnimatedSummaryBlock(
                              controller: _controller,
                              index: 4,
                              child: EndpointActionButton(
                                label: 'Continuar',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: () => _continue(context),
                                tooltip: 'Empezar el siguiente dia',
                                accent: accent,
                                backgroundColor: EndpointPalette.blend(
                                  EndpointPalette.panelBackground,
                                  accent,
                                  0.22,
                                ),
                                foregroundColor:
                                    EndpointPalette.softForegroundWarm,
                                expands: true,
                                height: isCompact ? 40 : 46,
                                useMarquee: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSummaryBlock extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _AnimatedSummaryBlock({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.13).clamp(0.0, 0.78);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start,
        (start + 0.34).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: Transform.scale(
              scale: 0.98 + (0.02 * value),
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _SummaryHeroBlock extends StatelessWidget {
  final RunDaySummary summary;
  final Battler player;
  final bool isCompact;

  const _SummaryHeroBlock({
    required this.summary,
    required this.player,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    const accent = EndpointPalette.rewardAccent;
    final archetypeLabel = player.archetypeId?.label ?? 'Sin arquetipo';
    final avatarSize = isCompact ? 84.0 : 116.0;

    return EndpointPanel(
      accent: accent,
      backgroundColor: EndpointPalette.panelBackgroundSoft,
      borderRadius: 18,
      glowOpacity: 0.08,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 8 : 10,
        isCompact ? 8 : 10,
        isCompact ? 8 : 10,
        isCompact ? 8 : 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EndpointText(
                  'DIA ${summary.dayNumber} COMPLETADO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textLargeBold.copyWith(
                    color: accent,
                    fontSize: isCompact ? 20 : 24,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                EndpointText(
                  archetypeLabel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textSmallBold.copyWith(
                    color: EndpointPalette.softForeground,
                    fontSize: isCompact ? 10 : 11,
                    letterSpacing: 1.3,
                  ),
                ),
                SizedBox(height: isCompact ? 8 : 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    EndpointValueChip(
                      label: 'LV',
                      value: player.level,
                      accent: accent,
                      foreground: EndpointPalette.softForegroundWarm,
                    ),
                    EndpointValueChip(
                      icon: Icons.monetization_on_rounded,
                      value: player.money,
                      accent: EndpointPalette.warningAccent,
                      foreground: EndpointPalette.softForegroundWarm,
                    ),
                    EndpointValueChip(
                      label: 'HP',
                      value: player.health,
                      accent: BattlerStat.health.accent,
                      foreground: EndpointPalette.softForeground,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Align(
            alignment: Alignment.topRight,
            child: EndpointEmojiSprite(
              emoji: player.iconEmoji,
              accent: EndpointPalette.primaryAccent,
              size: avatarSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRewardsBlock extends StatelessWidget {
  final String title;
  final String caption;
  final IconData icon;
  final List<RunDaySummaryReward> rewards;
  final int dayNumber;
  final String emptyText;
  final Color accent;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SummaryRewardsBlock({
    required this.title,
    required this.caption,
    required this.icon,
    required this.rewards,
    required this.dayNumber,
    required this.emptyText,
    required this.accent,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _SummarySectionShell(
      title: title,
      caption: caption,
      icon: icon,
      accent: accent,
      isExpanded: isExpanded,
      onToggle: onToggle,
      child: rewards.isEmpty
          ? _SummaryEmptyState(message: emptyText)
          : isExpanded
              ? _RewardIconRail(
                  rewards: rewards,
                  dayNumber: dayNumber,
                )
              : _SummaryCollapsedState(
                  message: '${rewards.length} entradas ocultas',
                ),
    );
  }
}

class _RewardIconRail extends StatelessWidget {
  final List<RunDaySummaryReward> rewards;
  final int dayNumber;

  const _RewardIconRail({
    required this.rewards,
    required this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: rewards.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        return Align(
          alignment: Alignment.centerLeft,
          child: _SummaryRewardIconCard(
            reward: rewards[index],
            dayNumber: dayNumber,
          ),
        );
      },
    );
  }
}

class _SummaryRewardIconCard extends StatelessWidget {
  final RunDaySummaryReward reward;
  final int dayNumber;

  const _SummaryRewardIconCard({
    required this.reward,
    required this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    final accent = reward.rarity.accent;
    final canOpenDetails = reward.item != null || reward.ability != null;

    return HoldTooltip(
      message: reward.name,
      child: SizedBox.square(
        dimension: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canOpenDetails
                ? () => _openRewardDetails(
                      context,
                      reward,
                      dayNumber: dayNumber,
                    )
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              decoration: BoxDecoration(
                color: EndpointPalette.blend(
                  EndpointPalette.panelBackgroundStrong,
                  accent,
                  0.14,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accent.withAlpha(150),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: reward.type == RunDaySummaryRewardType.item
                    ? EndpointText(
                        reward.iconEmoji,
                        style: const TextStyle(fontSize: 23, height: 1),
                      )
                    : Icon(
                        reward.ability?.icon ?? Icons.auto_awesome_rounded,
                        color: accent,
                        size: 24,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openRewardDetails(
  BuildContext context,
  RunDaySummaryReward reward, {
  required int dayNumber,
}) async {
  switch (reward.type) {
    case RunDaySummaryRewardType.item:
      final item = reward.item;
      if (item == null) return;

      await _openItemDetails(
        context,
        item,
        statusText: 'Obtenido durante el dia $dayNumber.',
      );
      return;
    case RunDaySummaryRewardType.ability:
      final ability = reward.ability;
      if (ability == null) return;

      await _openAbilityDetails(
        context,
        ability,
        statusText: 'Aprendida durante el dia $dayNumber.',
      );
      return;
  }
}

Future<void> _openItemDetails(
  BuildContext context,
  Item item, {
  required String statusText,
}) async {
  await showEndpointDialog<void>(
    context: context,
    barrierLabel: 'Detalle de objeto',
    barrierColor: EndpointPalette.overlayScrim,
    builder: (context) {
      return EndpointItemDetailsDialog(
        item: item,
        accent: item.rarity.accent,
        price: item.sellValue,
        priceLabel: 'VALOR',
        statusText: statusText,
      );
    },
  );
}

Future<void> _openAbilityDetails(
  BuildContext context,
  BattlerAbility ability, {
  required String statusText,
}) async {
  await showEndpointDialog<void>(
    context: context,
    barrierLabel: 'Detalle de aumento',
    barrierColor: EndpointPalette.overlayScrim,
    builder: (context) {
      return EndpointAbilityDetailsDialog(
        ability: ability,
        accent: ability.accent,
        statusText: statusText,
      );
    },
  );
}

class _SummaryEnemiesBlock extends StatelessWidget {
  final RunDaySummary summary;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SummaryEnemiesBlock({
    required this.summary,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _SummarySectionShell(
      title: 'ENEMIGOS ELIMINADOS',
      caption: '${summary.enemiesKilled}',
      icon: Icons.sports_mma_rounded,
      accent: EndpointPalette.dangerAccent,
      isExpanded: isExpanded,
      onToggle: onToggle,
      child: summary.defeatedEnemies.isEmpty
          ? const _SummaryEmptyState(message: 'Sin datos de enemigos.')
          : isExpanded
              ? Row(
                  children: [
                    _SummaryEnemyTotals(summary: summary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _EnemyIconRail(enemies: summary.defeatedEnemies),
                    ),
                  ],
                )
              : _SummaryCollapsedState(
                  message: '${summary.defeatedEnemies.length} entradas ocultas',
                ),
    );
  }
}

class _SummaryEnemyTotals extends StatelessWidget {
  final RunDaySummary summary;

  const _SummaryEnemyTotals({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          EndpointValueChip(
            icon: Icons.monetization_on_rounded,
            value: summary.moneyGained,
            accent: EndpointPalette.warningAccent,
            foreground: EndpointPalette.softForegroundWarm,
          ),
          EndpointValueChip(
            icon: Icons.inventory_2_rounded,
            value: summary.gainedRewards.length,
            accent: EndpointPalette.infoAccent,
            foreground: EndpointPalette.softForeground,
          ),
        ],
      ),
    );
  }
}

class _EnemyIconRail extends StatelessWidget {
  final List<RunDaySummaryEnemy> enemies;

  const _EnemyIconRail({
    required this.enemies,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: enemies.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final enemy = enemies[index];

        return Align(
          alignment: Alignment.centerLeft,
          child: _SummaryEnemyIconCard(enemy: enemy),
        );
      },
    );
  }
}

class _SummaryEnemyIconCard extends StatelessWidget {
  final RunDaySummaryEnemy enemy;

  const _SummaryEnemyIconCard({
    required this.enemy,
  });

  @override
  Widget build(BuildContext context) {
    final accent = enemy.rarity.accent;

    return HoldTooltip(
      message: enemy.name,
      child: SizedBox.square(
        dimension: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                buildEndpointSceneRoute<void>(
                  _RunSummaryEnemyDetailsPage(enemy: enemy),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              decoration: BoxDecoration(
                color: EndpointPalette.blend(
                  EndpointPalette.panelBackgroundStrong,
                  accent,
                  0.14,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accent.withAlpha(150),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: EndpointText(
                  enemy.iconEmoji,
                  style: const TextStyle(fontSize: 23, height: 1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RunSummaryEnemyDetailsPage extends StatelessWidget {
  final RunDaySummaryEnemy enemy;

  const _RunSummaryEnemyDetailsPage({
    required this.enemy,
  });

  @override
  Widget build(BuildContext context) {
    final battler = enemy.battler;
    final accent = enemy.rarity.accent;

    return Scaffold(
      body: NodeSceneWrapper(
        showTitle: 'Informe enemigo',
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: EndpointGradients.event(accent),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: EndpointSceneCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Volver al resumen',
                          accent: accent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _EnemyDetailsHero(enemy: enemy),
                              const SizedBox(height: 10),
                              _EnemyStatsPanel(
                                battler: battler,
                                accent: accent,
                              ),
                              const SizedBox(height: 10),
                              _EnemyLoadoutPanel(
                                title: 'OBJETOS EQUIPADOS',
                                icon: Icons.inventory_2_rounded,
                                accent: EndpointPalette.shopAccent,
                                enemyName: battler.name,
                                items: battler.equippedItems,
                                statusText: 'Equipado por ${battler.name}.',
                              ),
                              const SizedBox(height: 10),
                              _EnemyLoadoutPanel(
                                title: 'OBJETOS EN RESERVA',
                                icon: Icons.backpack_rounded,
                                accent: EndpointPalette.warningAccent,
                                enemyName: battler.name,
                                items: battler.inventoryItems,
                                statusText: 'En reserva de ${battler.name}.',
                              ),
                              const SizedBox(height: 10),
                              _EnemyAbilitiesPanel(
                                enemyName: battler.name,
                                abilities: battler.abilities,
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
        ),
      ),
    );
  }
}

class _EnemyDetailsHero extends StatelessWidget {
  final RunDaySummaryEnemy enemy;

  const _EnemyDetailsHero({
    required this.enemy,
  });

  @override
  Widget build(BuildContext context) {
    final battler = enemy.battler;
    final accent = enemy.rarity.accent;

    return EndpointPanel(
      accent: accent,
      backgroundColor: EndpointPalette.panelBackgroundSoft,
      borderRadius: 16,
      glowOpacity: 0.08,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        children: [
          EndpointEmojiSprite(
            emoji: battler.iconEmoji,
            accent: accent,
            size: 86,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EndpointText(
                  battler.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textLargeBold.copyWith(
                    color: EndpointPalette.softForeground,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    EndpointValueChip(
                      label: 'LV',
                      value: battler.level,
                      accent: accent,
                      foreground: EndpointPalette.softForegroundWarm,
                    ),
                    EndpointValueChip(
                      label: 'CAP',
                      value: battler.equipmentCapacity,
                      accent: EndpointPalette.infoAccent,
                      foreground: EndpointPalette.softForeground,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnemyStatsPanel extends StatelessWidget {
  final Battler battler;
  final Color accent;

  const _EnemyStatsPanel({
    required this.battler,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return _EnemyDetailsSection(
      title: 'ESTADISTICAS',
      icon: Icons.monitor_heart_rounded,
      accent: accent,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _statChip(BattlerStat.health, battler.maxHealth),
          _statChip(BattlerStat.attack, battler.attack),
          _statChip(BattlerStat.barrier, battler.barrier),
          _statChip(BattlerStat.thorns, battler.thorns),
          _statChip(BattlerStat.damageReduction, battler.damageReduction),
          _statChip(BattlerStat.vampirism, battler.vampirism),
          EndpointValueChip(
            label: 'HITS',
            value: battler.basicAttackCount,
            accent: EndpointPalette.infoAccent,
            foreground: EndpointPalette.softForeground,
          ),
          EndpointValueChip(
            label: 'INC',
            value: battler.income,
            accent: EndpointPalette.warningAccent,
            foreground: EndpointPalette.softForegroundWarm,
          ),
        ],
      ),
    );
  }

  Widget _statChip(BattlerStat stat, int value) {
    return EndpointValueChip(
      label: stat.shortLabel,
      value: value,
      accent: stat.accent,
      foreground: EndpointPalette.softForeground,
    );
  }
}

class _EnemyLoadoutPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final String enemyName;
  final List<Item> items;
  final String statusText;

  const _EnemyLoadoutPanel({
    required this.title,
    required this.icon,
    required this.accent,
    required this.enemyName,
    required this.items,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return _EnemyDetailsSection(
      title: title,
      icon: icon,
      accent: accent,
      child: items.isEmpty
          ? _EnemyDetailsEmptyState(message: '$enemyName no llevaba objetos.')
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in items)
                  _EnemyLoadoutIconCard(
                    tooltip: item.displayName,
                    accent: item.rarity.accent,
                    onPressed: () {
                      _openItemDetails(
                        context,
                        item,
                        statusText: statusText,
                      );
                    },
                    child: EndpointText(
                      item.iconEmoji,
                      style: const TextStyle(fontSize: 24, height: 1),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _EnemyAbilitiesPanel extends StatelessWidget {
  final String enemyName;
  final List<BattlerAbility> abilities;

  const _EnemyAbilitiesPanel({
    required this.enemyName,
    required this.abilities,
  });

  @override
  Widget build(BuildContext context) {
    return _EnemyDetailsSection(
      title: 'AUMENTOS',
      icon: Icons.auto_awesome_rounded,
      accent: EndpointPalette.infoAccent,
      child: abilities.isEmpty
          ? _EnemyDetailsEmptyState(
              message: '$enemyName no tenia aumentos.',
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ability in abilities)
                  _EnemyLoadoutIconCard(
                    tooltip: ability.displayName,
                    accent: ability.accent,
                    onPressed: () {
                      _openAbilityDetails(
                        context,
                        ability,
                        statusText: 'Aumento de $enemyName.',
                      );
                    },
                    child: Icon(
                      ability.icon,
                      color: ability.accent,
                      size: 25,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _EnemyLoadoutIconCard extends StatelessWidget {
  final String tooltip;
  final Color accent;
  final VoidCallback onPressed;
  final Widget child;

  const _EnemyLoadoutIconCard({
    required this.tooltip,
    required this.accent,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return HoldTooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 52,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              decoration: BoxDecoration(
                color: EndpointPalette.blend(
                  EndpointPalette.panelBackgroundStrong,
                  accent,
                  0.13,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withAlpha(148), width: 1.2),
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _EnemyDetailsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  const _EnemyDetailsSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      accent: accent,
      backgroundColor: EndpointPalette.panelBackgroundSoft,
      borderRadius: 16,
      glowOpacity: 0.05,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: EndpointText(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textSmallBold.copyWith(
                    color: EndpointPalette.softForeground,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _EnemyDetailsEmptyState extends StatelessWidget {
  final String message;

  const _EnemyDetailsEmptyState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointText(
      message,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: textSmallBold.copyWith(
        color: EndpointPalette.softForeground.withAlpha(184),
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SummarySectionShell extends StatelessWidget {
  final String title;
  final String caption;
  final IconData icon;
  final Color accent;
  final Widget child;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SummarySectionShell({
    required this.title,
    required this.caption,
    required this.icon,
    required this.accent,
    required this.child,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      accent: accent,
      backgroundColor: EndpointPalette.panelBackgroundSoft,
      borderRadius: 16,
      glowOpacity: 0.05,
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummarySectionHeader(
            title: title,
            caption: caption,
            icon: icon,
            accent: accent,
            isExpanded: isExpanded,
            onToggle: onToggle,
          ),
          const SizedBox(height: 7),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SummarySectionHeader extends StatelessWidget {
  final String title;
  final String caption;
  final IconData icon;
  final Color accent;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SummarySectionHeader({
    required this.title,
    required this.caption,
    required this.icon,
    required this.accent,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: EndpointText(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textSmallBold.copyWith(
              color: EndpointPalette.softForeground,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        EndpointText(
          caption,
          maxLines: 1,
          style: textSmallNumericBold.copyWith(
            color: accent,
            fontSize: 11,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: isExpanded ? 'Ocultar lista' : 'Mostrar lista',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: accent,
                  size: 19,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCollapsedState extends StatelessWidget {
  final String message;

  const _SummaryCollapsedState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EndpointText(
        message,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textSmallBold.copyWith(
          color: EndpointPalette.softForeground.withAlpha(150),
          fontSize: 10,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _SummaryEmptyState extends StatelessWidget {
  final String message;

  const _SummaryEmptyState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EndpointText(
        message,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textSmallBold.copyWith(
          color: EndpointPalette.softForeground.withAlpha(184),
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
