import '../_imports.dart';

/// Objetos neutros que cualquier arquetipo puede encontrar en tiendas.
const generalItemPool = <Item>[
  woodenStickItem,
  crackedBatteryItem,
  ironSwordItem,
  guardShieldItem,
  platedJacketItem,
  sunsteelBladeItem,
  dawnCharmItem,
  operativeBlackBoxItem,
  midnightCloakItem,
  rescueBladeItem,
  voidInjectorItem,
];

/// Objetos con identidad ofensiva, Quemadura, Calentando o motor de Inercia.
const imparableItemPool = <Item>[
  impactGlovesItem,
  emberCharmItem,
  reactiveCasingItem,
  serratedEdgeItem,
  thermalTurbineItem,
  pulseCarbineItem,
  inertialCoreItem,
  impulseSpearItem,
  portableOvenItem,
  overloadInjectorItem,
  vectorBulwarkItem,
  overloadAnchorItem,
  inertiaCrownItem,
  sunExecutionBladeItem,
];

/// Objetos centrados en curacion, barrera y buffs defensivos.
const inamovibleItemPool = <Item>[
  shieldItem,
  bulwarkAmuletItem,
  chemicalFilterItem,
  emergencyPlatingItem,
  containmentCoilItem,
  phaseVeilItem,
  reboundHarnessItem,
  concussionPrismItem,
  vectorBulwarkItem,
  contingencySealItem,
  parasiticCapacitorItem,
  eclipseMantleItem,
  shockMeshItem,
  deflectiveCapacitorItem,
  responseFrameItem,
  reboundLensItem,
];

/// Objetos de Intoxicacion, debuffs y defensas ligeras para builds rapidas.
const velozItemPool = <Item>[
  cyberWhipsItem,
  sunglassesItem,
  toxicCatalystItem,
  chemicalFilterItem,
  stunBatonItem,
  pocketJammerItem,
  serratedEdgeItem,
  pulseCarbineItem,
  concussionPrismItem,
  toxicScalpelItem,
  deflectiveCapacitorItem,
  interferenceCannonItem,
  reboundLensItem,
];

/// Objetos economicos, curativos y defensivos para un perfil adaptable.
const mercanteItemPool = <Item>[
  shieldItem,
  bulwarkAmuletItem,
  chemicalFilterItem,
  billingModuleItem,
  emergencyPlatingItem,
  containmentCoilItem,
  phaseVeilItem,
  contingencySealItem,
  parasiticCapacitorItem,
  eclipseMantleItem,
  shockMeshItem,
  deflectiveCapacitorItem,
  responseFrameItem,
  reboundLensItem,
];

const archetypeSpecificItemPools = <ArchetypeId, List<Item>>{
  ArchetypeId.veloz: velozItemPool,
  ArchetypeId.inamovible: inamovibleItemPool,
  ArchetypeId.imparable: imparableItemPool,
  ArchetypeId.mercante: mercanteItemPool,
};

/// Devuelve la pool de tienda combinando items generales y del arquetipo.
List<Item> itemPoolForArchetype(ArchetypeId? archetypeId) {
  return _deduplicateByItemId([
    ...generalItemPool,
    ...?archetypeSpecificItemPools[archetypeId],
  ]);
}

List<Item> _deduplicateByItemId(Iterable<Item> items) {
  final seen = <ItemId>{};
  final result = <Item>[];

  for (final item in items) {
    if (!seen.add(item.id)) continue;
    result.add(item);
  }

  return List<Item>.unmodifiable(result);
}
