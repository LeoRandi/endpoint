import '../_imports.dart';

/// Nodo gris economico centrado en gastar creditos para atacar.
final grayCombatNode = CombatPathNode(
  nodeId: 'combat_debt_mite',
  enemy: debtMiteEnemyBattler,
  tier: CombatNodeTier.gray,
  label: debtMiteEnemyBattler.name,
);

/// Alias explicito del nuevo encuentro gris base.
final debtMiteCombatNode = grayCombatNode;

/// Nodo gris de debuffs toxicos ligeros.
final rustyStingCombatNode = CombatPathNode(
  nodeId: 'combat_rusty_sting',
  enemy: rustyStingEnemyBattler,
  tier: CombatNodeTier.gray,
  label: rustyStingEnemyBattler.name,
);

/// Nodo gris agresivo de Desafio sin barrera.
final duelistHopperCombatNode = CombatPathNode(
  nodeId: 'combat_duelist_hopper',
  enemy: duelistHopperEnemyBattler,
  tier: CombatNodeTier.gray,
  label: duelistHopperEnemyBattler.name,
);

/// Nodo gris defensivo de Conmocion y mitigacion de debuffs.
final signalStagCombatNode = CombatPathNode(
  nodeId: 'combat_signal_stag',
  enemy: signalStagEnemyBattler,
  tier: CombatNodeTier.gray,
  label: signalStagEnemyBattler.name,
);

/// Nodo gris fragil con ataque estable por sobrecarga.
final reactorFleaCombatNode = CombatPathNode(
  nodeId: 'combat_reactor_flea',
  enemy: reactorFleaEnemyBattler,
  tier: CombatNodeTier.gray,
  label: reactorFleaEnemyBattler.name,
);

/// Nodo verde de presion temprana centrada en quemar al objetivo.
final greenCombatNode = CombatPathNode(
  nodeId: 'combat_cinder_claw',
  enemy: cinderClawEnemyBattler,
  tier: CombatNodeTier.green,
  label: cinderClawEnemyBattler.name,
);

/// Alias explicito del encuentro verde conservado.
final cinderClawCombatNode = greenCombatNode;

/// Alias temporal para rutas que aun esperan un segundo encuentro verde.
final venomStitchCombatNode = greenCombatNode;

/// Fallback azul hasta que el nuevo roster azul sea redisenado.
final blueCombatNode = CombatPathNode(
  nodeId: 'combat_cinder_claw_blue',
  enemy: cinderClawEnemyBattler,
  tier: CombatNodeTier.blue,
  label: cinderClawEnemyBattler.name,
);

/// Fallback morado hasta que el nuevo roster morado sea redisenado.
final purpleCombatNode = CombatPathNode(
  nodeId: 'combat_cinder_claw_purple',
  enemy: cinderClawEnemyBattler,
  tier: CombatNodeTier.purple,
  label: cinderClawEnemyBattler.name,
);

/// Nodo amarillo del combate mas duro del juego actual.
final yellowCombatNode = CombatPathNode(
  nodeId: 'combat_solar_executor',
  enemy: yellowEnemyBattler,
  tier: CombatNodeTier.yellow,
  label: yellowEnemyBattler.name,
);

/// Pool actual de enemigos grises disponibles.
final List<CombatPathNode> grayCombatNodes = List.unmodifiable([
  grayCombatNode,
  rustyStingCombatNode,
  duelistHopperCombatNode,
  signalStagCombatNode,
  reactorFleaCombatNode,
]);

/// Pool actual de enemigos verdes disponibles.
final List<CombatPathNode> greenCombatNodes = List.unmodifiable([
  greenCombatNode,
]);

/// Pool temporal azul sin presets enemigos propios.
final List<CombatPathNode> blueCombatNodes = List.unmodifiable([
  blueCombatNode,
]);

/// Pool temporal morado sin presets enemigos propios.
final List<CombatPathNode> purpleCombatNodes = List.unmodifiable([
  purpleCombatNode,
]);

/// Lista de ejemplo con todos los nodos de combate disponibles.
final List<CombatPathNode> combatPathNodeExamples = List.unmodifiable([
  ...grayCombatNodes,
  ...greenCombatNodes,
  ...blueCombatNodes,
  ...purpleCombatNodes,
  yellowCombatNode,
]);

/// Pool generico de nodos base usado como fallback en escenarios simples.
final List<PathNode> defaultPathNodePool = List.unmodifiable([
  ...grayCombatNodes,
  ...greenCombatNodes,
  ...blueCombatNodes,
  ...purpleCombatNodes,
  yellowCombatNode,
  const PathNode.shop(nodeId: 'shop_default_pool'),
  restZoneCampNode,
  severeMedicationCampNode,
]);
