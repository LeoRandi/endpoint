import '../_imports.dart';

/// Nodo gris del encuentro mas simple disponible en ruta.
final grayCombatNode = CombatPathNode(
  enemy: grayEnemyBattler,
  tier: CombatNodeTier.gray,
  label: 'SCRAP MITE',
);

/// Nodo verde del combate base de dificultad media-baja.
final greenCombatNode = CombatPathNode(
  enemy: greenEnemyBattler,
  tier: CombatNodeTier.green,
  label: 'HOLLOW DRONE',
);

/// Nodo azul para encuentros mas exigentes del tramo medio.
final blueCombatNode = CombatPathNode(
  enemy: blueEnemyBattler,
  tier: CombatNodeTier.blue,
  label: 'RIFT HOUND',
);

/// Nodo morado reservado para la franja nocturna dura.
final purpleCombatNode = CombatPathNode(
  enemy: purpleEnemyBattler,
  tier: CombatNodeTier.purple,
  label: 'NULL WARDEN',
);

/// Nodo amarillo del combate mas duro del juego actual.
final yellowCombatNode = CombatPathNode(
  enemy: yellowEnemyBattler,
  tier: CombatNodeTier.yellow,
  label: 'SOLAR EXECUTOR',
);

/// Lista de ejemplo con un nodo por tier para previews o debug.
final List<CombatPathNode> combatPathNodeExamples = List.unmodifiable([
  grayCombatNode,
  greenCombatNode,
  blueCombatNode,
  purpleCombatNode,
  yellowCombatNode,
]);

/// Pool generico de nodos base usado como fallback en escenarios simples.
final List<PathNode> defaultPathNodePool = List.unmodifiable([
  grayCombatNode,
  greenCombatNode,
  blueCombatNode,
  purpleCombatNode,
  yellowCombatNode,
  const PathNode.shop(),
  restZoneCampNode,
  severeMedicationCampNode,
]);
