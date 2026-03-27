import '../_imports.dart';

/// Nodo gris del encuentro mas simple disponible en ruta.
final grayCombatNode = CombatPathNode(
  enemy: grayEnemyBattler,
  tier: CombatNodeTier.gray,
  label: grayEnemyBattler.name,
);

/// Nodo gris evasivo que cambia potencia por doble golpe.
final shadeSkipperCombatNode = CombatPathNode(
  enemy: shadeSkipperEnemyBattler,
  tier: CombatNodeTier.gray,
  label: shadeSkipperEnemyBattler.name,
);

/// Nodo gris agresivo que castiga a rivales sin buffs.
final lensRuntCombatNode = CombatPathNode(
  enemy: lensRuntEnemyBattler,
  tier: CombatNodeTier.gray,
  label: lensRuntEnemyBattler.name,
);

/// Nodo gris defensivo apoyado en una pasiva de fase.
final phaseMoteCombatNode = CombatPathNode(
  enemy: phaseMoteEnemyBattler,
  tier: CombatNodeTier.gray,
  label: phaseMoteEnemyBattler.name,
);

/// Nodo verde del combate base de dificultad media-baja.
final greenCombatNode = CombatPathNode(
  enemy: greenEnemyBattler,
  tier: CombatNodeTier.green,
  label: greenEnemyBattler.name,
);

/// Nodo verde toxico que abre con presion de Intoxicacion.
final venomStitchCombatNode = CombatPathNode(
  enemy: venomStitchEnemyBattler,
  tier: CombatNodeTier.green,
  label: venomStitchEnemyBattler.name,
);

/// Nodo verde de aguante con curacion sostenida.
final patchBulwarkCombatNode = CombatPathNode(
  enemy: patchBulwarkEnemyBattler,
  tier: CombatNodeTier.green,
  label: patchBulwarkEnemyBattler.name,
);

/// Nodo verde agresivo enfocado en prender fuego al objetivo.
final cinderClawCombatNode = CombatPathNode(
  enemy: cinderClawEnemyBattler,
  tier: CombatNodeTier.green,
  label: cinderClawEnemyBattler.name,
);

/// Nodo azul para encuentros mas exigentes del tramo medio.
final blueCombatNode = CombatPathNode(
  enemy: blueEnemyBattler,
  tier: CombatNodeTier.blue,
  label: blueEnemyBattler.name,
);

/// Nodo azul toxico que escala mejor sobre objetivos ya debilitados.
final toxicReaverCombatNode = CombatPathNode(
  enemy: toxicReaverEnemyBattler,
  tier: CombatNodeTier.blue,
  label: toxicReaverEnemyBattler.name,
);

/// Nodo azul defensivo con curacion, reflejo de Quemadura y malla.
final phaseBastionCombatNode = CombatPathNode(
  enemy: phaseBastionEnemyBattler,
  tier: CombatNodeTier.blue,
  label: phaseBastionEnemyBattler.name,
);

/// Nodo azul de burst inicial apoyado por Sobrecarga venosa.
final cinderRamCombatNode = CombatPathNode(
  enemy: cinderRamEnemyBattler,
  tier: CombatNodeTier.blue,
  label: cinderRamEnemyBattler.name,
);

/// Nodo morado reservado para la franja nocturna dura.
final purpleCombatNode = CombatPathNode(
  enemy: purpleEnemyBattler,
  tier: CombatNodeTier.purple,
  label: purpleEnemyBattler.name,
);

/// Nodo morado toxico con filtro quimico y caza de debilidades.
final venomOracleCombatNode = CombatPathNode(
  enemy: venomOracleEnemyBattler,
  tier: CombatNodeTier.purple,
  label: venomOracleEnemyBattler.name,
);

/// Nodo morado de fuego sostenido que castiga a quien lo deje escalar.
final cinderExecutionerCombatNode = CombatPathNode(
  enemy: cinderExecutionerEnemyBattler,
  tier: CombatNodeTier.purple,
  label: cinderExecutionerEnemyBattler.name,
);

/// Nodo morado tecnico que mezcla defensa, drenaje y primer golpe cargado.
final phaseDredgerCombatNode = CombatPathNode(
  enemy: phaseDredgerEnemyBattler,
  tier: CombatNodeTier.purple,
  label: phaseDredgerEnemyBattler.name,
);

/// Nodo amarillo del combate mas duro del juego actual.
final yellowCombatNode = CombatPathNode(
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
  const PathNode.shop(),
  restZoneCampNode,
  severeMedicationCampNode,
]);
