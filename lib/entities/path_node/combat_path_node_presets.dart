import '_imports.dart';

final grayCombatNode = CombatPathNode(
  enemy: grayEnemyBattler,
  tier: CombatNodeTier.gray,
  label: 'SCRAP MITE',
);

final greenCombatNode = CombatPathNode(
  enemy: greenEnemyBattler,
  tier: CombatNodeTier.green,
  label: 'HOLLOW DRONE',
);

final blueCombatNode = CombatPathNode(
  enemy: blueEnemyBattler,
  tier: CombatNodeTier.blue,
  label: 'RIFT HOUND',
);

final purpleCombatNode = CombatPathNode(
  enemy: purpleEnemyBattler,
  tier: CombatNodeTier.purple,
  label: 'NULL WARDEN',
);

final yellowCombatNode = CombatPathNode(
  enemy: yellowEnemyBattler,
  tier: CombatNodeTier.yellow,
  label: 'SOLAR EXECUTOR',
);

final List<CombatPathNode> combatPathNodeExamples = List.unmodifiable([
  grayCombatNode,
  greenCombatNode,
  blueCombatNode,
  purpleCombatNode,
  yellowCombatNode,
]);

final List<PathNode> defaultPathNodePool = List.unmodifiable([
  grayCombatNode,
  greenCombatNode,
  blueCombatNode,
  purpleCombatNode,
  yellowCombatNode,
  const PathNode.weaponShop(),
  const PathNode.campSite(),
]);
