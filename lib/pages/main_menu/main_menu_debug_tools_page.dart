import '_imports.dart';

const _debugToolsAccent = EndpointPalette.infoAccent;
const _debugToolsForeground = EndpointPalette.softForeground;
const _debugToolsMutedForeground = Color(0xFFB7C0C8);
const _debugToolsPanelBackground = Color(0xD911151A);
const _debugToolsCardBackground = Color(0xCC171D23);
const _debugToolsScenePreset = EndpointScenePreset(
  accent: _debugToolsAccent,
  foreground: _debugToolsForeground,
  mutedForeground: _debugToolsMutedForeground,
  background: EndpointGradients.menu,
  panelBackground: _debugToolsPanelBackground,
  closeButtonBackground: EndpointPalette.closeButtonBackground,
  panelPadding: EdgeInsets.fromLTRB(18, 18, 18, 18),
  maxContentWidth: 520,
);
const _debugToolsSectionPreset = EndpointSectionPreset(
  accent: _debugToolsAccent,
  foreground: _debugToolsForeground,
  mutedForeground: _debugToolsMutedForeground,
  backgroundColor: _debugToolsPanelBackground,
  padding: EdgeInsets.fromLTRB(18, 18, 18, 18),
  borderRadius: 18,
  glowOpacity: 0.08,
  blurRadius: 28,
  spreadRadius: 3,
);

class MainMenuDebugToolsPage extends StatelessWidget {
  const MainMenuDebugToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EndpointSceneLayout(
        preset: _debugToolsScenePreset,
        onClose: () => Navigator.of(context).pop(),
        closeTooltip: 'Cerrar pruebas',
        child: EndpointSectionPanel(
          preset: _debugToolsSectionPreset,
          mainAxisSize: MainAxisSize.max,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EndpointSceneHeader(
                title: 'DEBUG TESTS',
                description: 'Accesos rapidos para probar pantallas aisladas.',
                foreground: _debugToolsForeground,
                descriptionColor: _debugToolsMutedForeground,
                titleStyle: textExtraLargeBold.copyWith(
                  fontSize: 34,
                  letterSpacing: 2.6,
                ),
                descriptionStyle: textMedium.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _DebugToolButton(
                      label: 'end_result_test',
                      icon: Icons.flag_rounded,
                      tooltip: 'Generar un resumen final aleatorio',
                      onPressed: () => _openGeneratedEndResult(context),
                    ),
                    _DebugToolButton(
                      label: 'pattern_item_actions_test',
                      icon: Icons.gesture_rounded,
                      tooltip:
                          'Combate Patron con pilas de accion simultaneas contra un enemigo gris',
                      onPressed: () => _openPatternItemActionsTest(context),
                    ),
                    _DebugToolButton(
                      label: 'simultaneous_action_piles_test',
                      icon: Icons.sync_alt_rounded,
                      tooltip:
                          'Combate Patron con pilas de accion y equipamiento aleatorio',
                      onPressed: () =>
                          _openSimultaneousActionPilesTest(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openGeneratedEndResult(BuildContext context) {
    final fixture = _EndResultDebugFixture.generate();
    Navigator.of(context).push(
      buildEndpointSceneRoute<void>(
        RunOutcomePage(
          completionType: fixture.completionType,
          player: fixture.player,
          runSummary: fixture.runSummary,
        ),
      ),
    );
  }

  void _openPatternItemActionsTest(BuildContext context) {
    final random = Random(DateTime.now().microsecondsSinceEpoch);
    final enemyNode = grayCombatNodes[random.nextInt(grayCombatNodes.length)];
    final equippedItems = itemPresets
        .map((item) => item.toRuntimeInstance())
        .toList(growable: false);
    final rawPlayer = defaultPlayerBattler.copyWith(
      name: 'ACTION TEST UNIT',
      archetypeId: ArchetypeId.crepitans,
      health: 45,
      equipmentCapacity: equippedItems.length,
      equippedItems: equippedItems,
      inventoryItems: const <Item>[],
      augments: [
        augmentCatalogById[1]!.copyWith(tier: RarityTier.purple),
      ],
      patternItemPointKeys: const <String, String>{},
    );
    final layout = OperativePatternLayoutService.resolveForPlayer(
      player: rawPlayer,
      random: random,
    );

    Navigator.of(context).push(
      buildEndpointSceneRoute<BattleFlowResult>(
        BattlePage(
          enemy: enemyNode.enemy,
          player: layout.player,
          randomizer: RunRandomizer(
            seed: DateTime.now().microsecondsSinceEpoch,
          ),
          phase: RunHourPhase.day,
          showTitle: 'PATTERN ACTION TEST',
          victoryMoneyFactor: enemyNode.tier.factor,
          enemyTier: enemyNode.tier.factor,
          returnResultToCaller: true,
          gameModeOverride: EndpointGameMode.pattern,
        ),
      ),
    );
  }

  void _openSimultaneousActionPilesTest(BuildContext context) {
    final random = Random(DateTime.now().microsecondsSinceEpoch);
    final playerItems = _randomRuntimeItems(random, count: 4);
    final enemyItems = _randomRuntimeItems(random, count: 4);
    final rawPlayer = defaultPlayerBattler.copyWith(
      name: 'ACTION PILE UNIT',
      archetypeId: ArchetypeId.crepitans,
      health: 64,
      equipmentCapacity: playerItems.length,
      equippedItems: playerItems,
      inventoryItems: const <Item>[],
      patternItemPointKeys: const <String, String>{},
      baseStats: const {
        BattlerStat.health: 64,
        BattlerStat.attack: 2,
        BattlerStat.barrier: 2,
      },
    );
    final rawEnemy = defaultEnemyBattler.copyWith(
      name: 'TEST DUMMY',
      health: 64,
      equipmentCapacity: enemyItems.length,
      equippedItems: enemyItems,
      inventoryItems: const <Item>[],
      patternItemPointKeys: const <String, String>{},
      baseStats: const {
        BattlerStat.health: 64,
        BattlerStat.attack: 2,
        BattlerStat.barrier: 2,
      },
    );
    final playerLayout = OperativePatternLayoutService.resolveForPlayer(
      player: rawPlayer,
      random: random,
    );
    final enemyLayout = OperativePatternLayoutService.resolveForPlayer(
      player: rawEnemy,
      random: random,
    );

    Navigator.of(context).push(
      buildEndpointSceneRoute<BattleFlowResult>(
        BattlePage(
          enemy: enemyLayout.player,
          player: playerLayout.player,
          randomizer: RunRandomizer(
            seed: DateTime.now().microsecondsSinceEpoch,
          ),
          phase: RunHourPhase.day,
          showTitle: 'SIMULTANEOUS ACTION PILES',
          victoryMoneyFactor: 1,
          enemyTier: 1,
          returnResultToCaller: true,
          gameModeOverride: EndpointGameMode.pattern,
        ),
      ),
    );
  }

  List<Item> _randomRuntimeItems(Random random, {required int count}) {
    final pool = itemPresets.toList(growable: false)..shuffle(random);
    return pool.take(count).map((item) {
      return item.toRuntimeInstance(forceNewInstance: true).copyWith(
            tier: _randomDebugRarity(random),
          );
    }).toList(growable: false);
  }

  RarityTier _randomDebugRarity(Random random) {
    const weighted = [
      RarityTier.gray,
      RarityTier.green,
      RarityTier.green,
      RarityTier.blue,
      RarityTier.blue,
      RarityTier.purple,
    ];
    return weighted[random.nextInt(weighted.length)];
  }
}

class _DebugToolButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _DebugToolButton({
    required this.label,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EndpointActionButton(
        label: label,
        icon: icon,
        tooltip: tooltip,
        onPressed: onPressed,
        expands: true,
        height: 58,
        borderRadius: 10,
        borderWidth: 1.6,
        accent: _debugToolsAccent,
        backgroundColor: _debugToolsCardBackground,
        foregroundColor: _debugToolsForeground,
        textStyle: textMediumBold.copyWith(
          fontSize: 15,
          letterSpacing: 1.2,
        ),
        useMarquee: false,
      ),
    );
  }
}

class _EndResultDebugFixture {
  final RunCompletionType completionType;
  final Battler player;
  final RunDaySummary runSummary;

  const _EndResultDebugFixture({
    required this.completionType,
    required this.player,
    required this.runSummary,
  });

  static _EndResultDebugFixture generate() {
    final random = Random(DateTime.now().microsecondsSinceEpoch);
    final equippedItems = _randomOwnedItems(random, count: 7);
    final acquiredItems = _randomOwnedItems(random, count: 6);
    final augments = _randomAugments(random, count: 5);
    final defeatedEnemies = _randomDefeatedEnemies(random, count: 13);

    final rawPlayer = defaultPlayerBattler.copyWith(
      name: 'DEBUG ENDPOINT',
      iconEmoji: _pick(
        random,
        const ['\u{1F916}', '\u{1F6F0}', '\u2699', '\u{1F9EA}'],
      ),
      archetypeId: _pick(random, ArchetypeId.values),
      level: 8,
      health: 84,
      money: 42 + random.nextInt(60),
      income: 4 + random.nextInt(6),
      equipmentCapacity: 99,
      baseStats: {
        BattlerStat.health: 84,
        BattlerStat.attack: 8 + random.nextInt(6),
        BattlerStat.barrier: 5 + random.nextInt(7),
      },
      augments: augments,
      inventoryItems: acquiredItems.take(4).toList(growable: false),
      equippedItems: equippedItems,
      reinforcedPatternPointKey: _pick(random, operativePatternPoints).key,
    );
    final layout = OperativePatternLayoutService.resolveForPlayer(
      player: rawPlayer,
      random: random,
    );
    final gainedRewards = <RunDaySummaryReward>[
      for (final item in acquiredItems) RunDaySummaryReward.item(item),
      for (final augment in augments.take(4))
        RunDaySummaryReward.augment(augment),
    ];

    return _EndResultDebugFixture(
      completionType: RunCompletionType.victory,
      player: layout.player,
      runSummary: RunDaySummary(
        dayNumber: 5,
        enemiesKilled: defeatedEnemies.length,
        moneyGained: 80 + random.nextInt(90),
        gainedRewards: List<RunDaySummaryReward>.unmodifiable(gainedRewards),
        defeatedEnemies: List<RunDaySummaryEnemy>.unmodifiable(
          defeatedEnemies,
        ),
      ),
    );
  }

  static List<Item> _randomOwnedItems(Random random, {required int count}) {
    final pool = itemPresets.toList(growable: false)..shuffle(random);
    return pool.take(count).map((item) {
      return item.toOwnedInstance().copyWith(tier: _randomRarity(random));
    }).toList(growable: false);
  }

  static List<Augment> _randomAugments(
    Random random, {
    required int count,
  }) {
    final pool = augmentCatalog.toList(growable: false)..shuffle(random);
    return pool.take(count).map((augment) {
      return augment.copyWith(tier: _randomRarity(random));
    }).toList(growable: false);
  }

  static List<RunDaySummaryEnemy> _randomDefeatedEnemies(
    Random random, {
    required int count,
  }) {
    final pool = combatPathNodeExamples.toList(growable: false)
      ..shuffle(random);
    return pool.take(count).map((node) {
      final scaledNode = node.scaledForDay(1 + random.nextInt(5));
      return RunDaySummaryEnemy.fromBattler(
        scaledNode.enemy,
        rarity: scaledNode.tier.rarity,
      );
    }).toList(growable: false);
  }

  static T _pick<T>(Random random, List<T> values) {
    return values[random.nextInt(values.length)];
  }

  static RarityTier _randomRarity(Random random) {
    const weighted = [
      RarityTier.gray,
      RarityTier.green,
      RarityTier.green,
      RarityTier.blue,
      RarityTier.blue,
      RarityTier.purple,
      RarityTier.yellow,
    ];
    return _pick(random, weighted);
  }
}
