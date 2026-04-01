import '../_imports.dart';

/// Nodo gris del encuentro mas simple disponible en ruta.
final grayCombatNode = CombatPathNode(
  nodeId: 'combat_scrap_mite',
  enemy: grayEnemyBattler,
  tier: CombatNodeTier.gray,
  label: grayEnemyBattler.name,
);

/// Nodo gris evasivo que cambia potencia por doble golpe.
final shadeSkipperCombatNode = CombatPathNode(
  nodeId: 'combat_shade_skipper',
  enemy: shadeSkipperEnemyBattler,
  tier: CombatNodeTier.gray,
  label: shadeSkipperEnemyBattler.name,
);

/// Nodo gris agresivo que castiga a rivales sin buffs.
final lensRuntCombatNode = CombatPathNode(
  nodeId: 'combat_lens_runt',
  enemy: lensRuntEnemyBattler,
  tier: CombatNodeTier.gray,
  label: lensRuntEnemyBattler.name,
);

/// Nodo gris defensivo apoyado en una pasiva de fase.
final phaseMoteCombatNode = CombatPathNode(
  nodeId: 'combat_phase_mote',
  enemy: phaseMoteEnemyBattler,
  tier: CombatNodeTier.gray,
  label: phaseMoteEnemyBattler.name,
);

/// Nodo verde del combate base de dificultad media-baja.
final greenCombatNode = CombatPathNode(
  nodeId: 'combat_hollow_drone',
  enemy: greenEnemyBattler,
  tier: CombatNodeTier.green,
  label: greenEnemyBattler.name,
);

/// Nodo verde toxico que abre con presion de Intoxicacion.
final venomStitchCombatNode = CombatPathNode(
  nodeId: 'combat_venom_stitch',
  enemy: venomStitchEnemyBattler,
  tier: CombatNodeTier.green,
  label: venomStitchEnemyBattler.name,
);

/// Nodo verde de aguante con curacion sostenida.
final patchBulwarkCombatNode = CombatPathNode(
  nodeId: 'combat_patch_bulwark',
  enemy: patchBulwarkEnemyBattler,
  tier: CombatNodeTier.green,
  label: patchBulwarkEnemyBattler.name,
);

/// Nodo verde agresivo enfocado en prender fuego al objetivo.
final cinderClawCombatNode = CombatPathNode(
  nodeId: 'combat_cinder_claw',
  enemy: cinderClawEnemyBattler,
  tier: CombatNodeTier.green,
  label: cinderClawEnemyBattler.name,
);

/// Nodo azul para encuentros mas exigentes del tramo medio.
final blueCombatNode = CombatPathNode(
  nodeId: 'combat_rift_hound',
  enemy: blueEnemyBattler,
  tier: CombatNodeTier.blue,
  label: blueEnemyBattler.name,
);

/// Nodo azul toxico que escala mejor sobre objetivos ya debilitados.
final toxicReaverCombatNode = CombatPathNode(
  nodeId: 'combat_toxic_reaver',
  enemy: toxicReaverEnemyBattler,
  tier: CombatNodeTier.blue,
  label: toxicReaverEnemyBattler.name,
);

/// Nodo azul defensivo con curacion, reflejo de Quemadura y malla.
final phaseBastionCombatNode = CombatPathNode(
  nodeId: 'combat_phase_bastion',
  enemy: phaseBastionEnemyBattler,
  tier: CombatNodeTier.blue,
  label: phaseBastionEnemyBattler.name,
);

/// Nodo azul de burst inicial apoyado por Sobrecarga venosa.
final cinderRamCombatNode = CombatPathNode(
  nodeId: 'combat_cinder_ram',
  enemy: cinderRamEnemyBattler,
  tier: CombatNodeTier.blue,
  label: cinderRamEnemyBattler.name,
);

/// Nodo morado reservado para la franja nocturna dura.
final purpleCombatNode = CombatPathNode(
  nodeId: 'combat_null_warden',
  enemy: purpleEnemyBattler,
  tier: CombatNodeTier.purple,
  label: purpleEnemyBattler.name,
);

/// Nodo morado toxico con filtro quimico y caza de debilidades.
final venomOracleCombatNode = CombatPathNode(
  nodeId: 'combat_venom_oracle',
  enemy: venomOracleEnemyBattler,
  tier: CombatNodeTier.purple,
  label: venomOracleEnemyBattler.name,
);

/// Nodo morado de fuego sostenido que castiga a quien lo deje escalar.
final cinderExecutionerCombatNode = CombatPathNode(
  nodeId: 'combat_cinder_executioner',
  enemy: cinderExecutionerEnemyBattler,
  tier: CombatNodeTier.purple,
  label: cinderExecutionerEnemyBattler.name,
);

/// Nodo morado tecnico que mezcla barrera, drenaje y primer golpe cargado.
final phaseDredgerCombatNode = CombatPathNode(
  nodeId: 'combat_phase_dredger',
  enemy: phaseDredgerEnemyBattler,
  tier: CombatNodeTier.purple,
  label: phaseDredgerEnemyBattler.name,
);

/// Nodo amarillo del combate mas duro del juego actual.
final yellowCombatNode = CombatPathNode(
  nodeId: 'combat_solar_executor',
  enemy: yellowEnemyBattler,
  tier: CombatNodeTier.yellow,
  label: yellowEnemyBattler.name,
);

/// Pool completo de enemigos grises disponibles.
final List<CombatPathNode> grayCombatNodes = List.unmodifiable([
  grayCombatNode,
  shadeSkipperCombatNode,
  lensRuntCombatNode,
  phaseMoteCombatNode,
]);

/// Pool completo de enemigos verdes disponibles.
final List<CombatPathNode> greenCombatNodes = List.unmodifiable([
  greenCombatNode,
  venomStitchCombatNode,
  patchBulwarkCombatNode,
  cinderClawCombatNode,
]);

/// Pool completo de enemigos azules disponibles.
final List<CombatPathNode> blueCombatNodes = List.unmodifiable([
  blueCombatNode,
  toxicReaverCombatNode,
  phaseBastionCombatNode,
  cinderRamCombatNode,
]);

/// Pool completo de enemigos morados disponibles.
final List<CombatPathNode> purpleCombatNodes = List.unmodifiable([
  purpleCombatNode,
  venomOracleCombatNode,
  cinderExecutionerCombatNode,
  phaseDredgerCombatNode,
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
