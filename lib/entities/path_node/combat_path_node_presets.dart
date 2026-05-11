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

/// Nodo gris de control puntual con remates y autosustain.
final chiselImpCombatNode = CombatPathNode(
  nodeId: 'combat_chisel_imp',
  enemy: chiselImpEnemyBattler,
  tier: CombatNodeTier.gray,
  label: chiselImpEnemyBattler.name,
);

/// Nodo gris defensivo que castiga al agresor por contacto.
final staticTickCombatNode = CombatPathNode(
  nodeId: 'combat_static_tick',
  enemy: staticTickEnemyBattler,
  tier: CombatNodeTier.gray,
  label: staticTickEnemyBattler.name,
);

/// Nodo gris agresivo que presiona a rivales sin buffs.
final scrapHushCombatNode = CombatPathNode(
  nodeId: 'combat_scrap_hush',
  enemy: scrapHushEnemyBattler,
  tier: CombatNodeTier.gray,
  label: scrapHushEnemyBattler.name,
);

/// Nodo gris de desgaste que se sostiene limpiando debuffs.
final rustLeechCombatNode = CombatPathNode(
  nodeId: 'combat_rust_leech',
  enemy: rustLeechEnemyBattler,
  tier: CombatNodeTier.gray,
  label: rustLeechEnemyBattler.name,
);

/// Nodo verde del combate base de dificultad media-baja.
final greenCombatNode = CombatPathNode(
  nodeId: 'combat_hollow_drone',
  enemy: greenEnemyBattler,
  tier: CombatNodeTier.green,
  label: greenEnemyBattler.name,
);

/// Nodo verde de debuffs en cadena con castigo incremental.
final toxicLacerCombatNode = CombatPathNode(
  nodeId: 'combat_toxic_lacer',
  enemy: toxicLacerEnemyBattler,
  tier: CombatNodeTier.green,
  label: toxicLacerEnemyBattler.name,
);

/// Nodo morado de aguante progresivo con doble motor de barrera.
final bastionSpringCombatNode = CombatPathNode(
  nodeId: 'combat_bastion_spring',
  enemy: bastionSpringEnemyBattler,
  tier: CombatNodeTier.purple,
  label: bastionSpringEnemyBattler.name,
);

/// Nodo verde de presion ofensiva que escala por calor.
final furnaceFangCombatNode = CombatPathNode(
  nodeId: 'combat_furnace_fang',
  enemy: furnaceFangEnemyBattler,
  tier: CombatNodeTier.green,
  label: furnaceFangEnemyBattler.name,
);

/// Nodo verde equilibrado con mezcla de sosten y daño estable.
final shieldmendBruteCombatNode = CombatPathNode(
  nodeId: 'combat_shieldmend_brute',
  enemy: shieldmendBruteEnemyBattler,
  tier: CombatNodeTier.green,
  label: shieldmendBruteEnemyBattler.name,
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

/// Nodo azul de control bilateral basado en Interferencia.
final jammerHowlerCombatNode = CombatPathNode(
  nodeId: 'combat_jammer_howler',
  enemy: jammerHowlerEnemyBattler,
  tier: CombatNodeTier.blue,
  label: jammerHowlerEnemyBattler.name,
);

/// Nodo azul de burst que convierte barrera en daño puntual.
final magnetMaulerCombatNode = CombatPathNode(
  nodeId: 'combat_magnet_mauler',
  enemy: magnetMaulerEnemyBattler,
  tier: CombatNodeTier.blue,
  label: magnetMaulerEnemyBattler.name,
);

/// Nodo azul de ejecucion sobre objetivos ya debilitados.
final veninRunnerCombatNode = CombatPathNode(
  nodeId: 'combat_venin_runner',
  enemy: veninRunnerEnemyBattler,
  tier: CombatNodeTier.blue,
  label: veninRunnerEnemyBattler.name,
);

/// Nodo azul de tempo defensivo con retorno de quemadura.
final ashenFrameCombatNode = CombatPathNode(
  nodeId: 'combat_ashen_frame',
  enemy: ashenFrameEnemyBattler,
  tier: CombatNodeTier.blue,
  label: ashenFrameEnemyBattler.name,
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

/// Nodo morado de inercia que acumula reservas en ambos ejes.
final inertiaHarpoonerCombatNode = CombatPathNode(
  nodeId: 'combat_inertia_harpooner',
  enemy: inertiaHarpoonerEnemyBattler,
  tier: CombatNodeTier.purple,
  label: inertiaHarpoonerEnemyBattler.name,
);

/// Nodo morado de fuego extremo con remate por vida faltante.
final ovenHarrowerCombatNode = CombatPathNode(
  nodeId: 'combat_oven_harrower',
  enemy: ovenHarrowerEnemyBattler,
  tier: CombatNodeTier.purple,
  label: ovenHarrowerEnemyBattler.name,
);

/// Nodo morado hibrido de presion estadistica y castigo reactivo.
final voidLeecherCombatNode = CombatPathNode(
  nodeId: 'combat_void_leecher',
  enemy: voidLeecherEnemyBattler,
  tier: CombatNodeTier.purple,
  label: voidLeecherEnemyBattler.name,
);

/// Nodo morado de control sostenido con economia tactica.
final gloomSmugglerCombatNode = CombatPathNode(
  nodeId: 'combat_gloom_smuggler',
  enemy: gloomSmugglerEnemyBattler,
  tier: CombatNodeTier.purple,
  label: gloomSmugglerEnemyBattler.name,
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
  chiselImpCombatNode,
  staticTickCombatNode,
  scrapHushCombatNode,
  rustLeechCombatNode,
]);

/// Pool completo de enemigos verdes disponibles.
final List<CombatPathNode> greenCombatNodes = List.unmodifiable([
  greenCombatNode,
  venomStitchCombatNode,
  patchBulwarkCombatNode,
  cinderClawCombatNode,
  toxicLacerCombatNode,
  furnaceFangCombatNode,
  shieldmendBruteCombatNode,
]);

/// Pool completo de enemigos azules disponibles.
final List<CombatPathNode> blueCombatNodes = List.unmodifiable([
  blueCombatNode,
  toxicReaverCombatNode,
  phaseBastionCombatNode,
  cinderRamCombatNode,
  jammerHowlerCombatNode,
  magnetMaulerCombatNode,
  veninRunnerCombatNode,
  ashenFrameCombatNode,
]);

/// Pool completo de enemigos morados disponibles.
final List<CombatPathNode> purpleCombatNodes = List.unmodifiable([
  purpleCombatNode,
  venomOracleCombatNode,
  cinderExecutionerCombatNode,
  phaseDredgerCombatNode,
  inertiaHarpoonerCombatNode,
  ovenHarrowerCombatNode,
  voidLeecherCombatNode,
  gloomSmugglerCombatNode,
  bastionSpringCombatNode,
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
