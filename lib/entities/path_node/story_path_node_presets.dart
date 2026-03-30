import '../_imports.dart';

/// Arquetipo agil orientado a ataque ligero y economia temprana.
final velozArchetypeNode = ArchetypePathNode(
  nodeId: 'archetype_veloz',
  label: 'Veloz',
  tooltip:
      'Cyber Latigos + Gafas de Sol. Perfil agil de doble golpe que envenena con cada impacto. Empieza con 8C y 6 income.',
  iconEmoji: cyberWhipsItem.iconEmoji,
  playerIconEmoji: cyberWhipsItem.iconEmoji,
  accent: const Color(0xFF59B7FF),
  rarity: RarityTier.blue,
  baseStatModifiers: const {
    BattlerStat.attack: 1,
  },
  moneyModifier: 8,
  incomeModifier: 6,
  startingItems: const [
    cyberWhipsItem,
    sunglassesItem,
  ],
  startingAbilities: const [
    criticalScannerAbility,
  ],
);

/// Arquetipo defensivo centrado en vida, defensa y estabilidad.
final inamovibleArchetypeNode = ArchetypePathNode(
  nodeId: 'archetype_inamovible',
  label: 'Inamovible',
  tooltip:
      'Escudo + Amuleto de Bastion. Perfil resistente con regeneracion pasiva, mas defensa y Reinicio en seco. Empieza con 12C y 4 income.',
  iconEmoji: shieldItem.iconEmoji,
  playerIconEmoji: shieldItem.iconEmoji,
  accent: const Color(0xFF5AF78E),
  rarity: RarityTier.green,
  baseStatModifiers: const {
    BattlerStat.health: 4,
    BattlerStat.defense: 1,
  },
  moneyModifier: 12,
  incomeModifier: 4,
  startingItems: const [
    shieldItem,
    bulwarkAmuletItem,
  ],
  startingAbilities: const [
    hardResetAbility,
  ],
);

/// Arquetipo ofensivo que arranca con mas presion de dano.
final imparableArchetypeNode = ArchetypePathNode(
  nodeId: 'archetype_imparable',
  label: 'Imparable',
  tooltip:
      'Espada de Hierro + Amuleto de Ascuas. Perfil ofensivo con mas pegada base y Sobrecarga venosa de salida. Empieza con 8C y 4 income.',
  iconEmoji: ironSwordItem.iconEmoji,
  playerIconEmoji: ironSwordItem.iconEmoji,
  accent: const Color(0xFFF3D35C),
  rarity: RarityTier.yellow,
  baseStatModifiers: const {
    BattlerStat.attack: 2,
  },
  moneyModifier: 8,
  incomeModifier: 4,
  startingItems: const [
    ironSwordItem,
    emberCharmItem,
  ],
  startingAbilities: const [
    venousOverloadAbility,
  ],
);

/// Criterio gris para tiendas de entrada con objetos baratos y comunes.
final grayShopCriterion = ShopInventoryCriterion(
  label: 'RAREZA GRIS',
  description: 'Solo aparecen objetos grises de bajo valor.',
  exactRarity: RarityTier.gray,
);

/// Criterio defensivo basado en piezas equipables en el slot de soporte.
final armorShopCriterion = ShopInventoryCriterion(
  label: 'ARMADURAS',
  description: 'Solo aparecen piezas de soporte y blindaje.',
  requiredSlot: ItemSlot.offHand,
);

/// Criterio de lujo reservado a reliquias amarillas.
final luxuryShopCriterion = ShopInventoryCriterion(
  label: 'RELIQUIAS DE LUJO',
  description: 'Solo aparecen objetos de rareza amarilla.',
  exactRarity: RarityTier.yellow,
);

/// Criterio ofensivo amplio para mercados centrados en armas.
final weaponShopCriterion = ShopInventoryCriterion(
  label: 'ARMAS',
  description: 'Solo aparecen objetos equipables como arma.',
  requiredSlot: ItemSlot.weapon,
);

/// Criterio defensivo amplio para objetos que aportan defensa directa.
final defenseShopCriterion = ShopInventoryCriterion(
  label: 'DEFENSA',
  description: 'Solo aparecen objetos que otorgan defensa.',
  requiredPositiveModifierStat: BattlerStat.defense,
);

/// Criterio quimico que acepta objetos de Quemadura o Intoxicacion hasta azul.
final burnOrPoisonShopCriterion = ShopInventoryCriterion(
  label: 'QUEMADURA / INTOXICACION',
  description:
      'Solo aparecen objetos de Quemadura o Intoxicacion hasta rareza azul.',
  requiredTags: [
    EntityTag.quemadura,
    EntityTag.intoxicacion,
  ],
  matchAnyRequiredTag: true,
  maximumRarity: RarityTier.blue,
);

/// Criterio tematico reservado a objetos que interactuan con Quemadura.
final burnShopCriterion = ShopInventoryCriterion(
  label: 'QUEMADURA',
  description: 'Solo aparecen objetos con la tag de Quemadura.',
  requiredTags: [
    EntityTag.quemadura,
  ],
);

/// Criterio tematico reservado a objetos que interactuan con Intoxicacion.
final poisonShopCriterion = ShopInventoryCriterion(
  label: 'INTOXICACION',
  description: 'Solo aparecen objetos con la tag de Intoxicacion.',
  requiredTags: [
    EntityTag.intoxicacion,
  ],
);

/// Criterio azul para tiendas centradas en aplicar o manipular debuffs.
final debuffShopCriterion = ShopInventoryCriterion(
  label: 'DEBUFF',
  description: 'Solo aparecen objetos con la tag de Debuff.',
  requiredTags: [
    EntityTag.debuff,
  ],
);

/// Criterio azul para objetos que leen o explotan buffs.
final buffShopCriterion = ShopInventoryCriterion(
  label: 'BUFF',
  description: 'Solo aparecen objetos con la tag de Buff.',
  requiredTags: [
    EntityTag.buff,
  ],
);

/// Tienda gris de armas basicas para las primeras horas.
final scrapArsenalNode = ShopPathNode(
  nodeId: 'shop_scrap_arsenal',
  label: 'Arsenal de Chatarra',
  tooltip: 'Armas funcionales antes del anochecer',
  iconEmoji: '\u2694',
  rarity: RarityTier.gray,
  accent: RarityTier.gray.accent,
  badgeLabel: 'ARMAS',
  showTitle: 'Arsenal de Chatarra',
  shopTitle: 'ARSENAL DE CHATARRA',
  shopSubtitle:
      'Herramientas rapidas y mercancia de entrada para la primera hora.',
  stockCriterion: grayShopCriterion,
);

/// Tienda verde de piezas defensivas para estabilizar la run.
final bulwarkWorkshopNode = ShopPathNode(
  nodeId: 'shop_bulwark_workshop',
  label: 'Taller Blindado',
  tooltip: 'Protecciones para aguantar hasta la noche',
  iconEmoji: '\u{1F6E1}',
  rarity: RarityTier.green,
  accent: RarityTier.green.accent,
  badgeLabel: 'ARMADURA',
  showTitle: 'Taller Blindado',
  shopTitle: 'TALLER BLINDADO',
  shopSubtitle: 'Piezas defensivas montadas en el acto.',
  stockCriterion: armorShopCriterion,
);

/// Tienda amarilla de reliquias caras y poderosas.
final luxuryRelicsNode = ShopPathNode(
  nodeId: 'shop_luxury_relics',
  label: 'Reliquias de Lujo',
  tooltip: 'Objetos de gran calidad y procedencia dudosa',
  iconEmoji: '\u{1F48E}',
  rarity: RarityTier.yellow,
  accent: RarityTier.yellow.accent,
  badgeLabel: 'LUJO',
  showTitle: 'Reliquias de Lujo',
  shopTitle: 'RELIQUIAS DE LUJO',
  shopSubtitle:
      'Mercancia premium. Solo para quienes pueden pagar el precio de la exclusividad.',
  stockCriterion: luxuryShopCriterion,
);

/// Tienda amarilla centrada en herramientas que aplican o explotan Quemadura.
final emberFoundryNode = ShopPathNode(
  nodeId: 'shop_ember_foundry',
  label: 'Forja de Ascuas',
  tooltip: 'Todo el catalogo gira alrededor de la Quemadura',
  iconEmoji: '\u{1F525}',
  rarity: RarityTier.yellow,
  accent: EntityTag.quemadura.accent,
  badgeLabel: 'QUEMA',
  showTitle: 'Forja de Ascuas',
  shopTitle: 'FORJA DE ASCUAS',
  shopSubtitle: 'Brasa embotellada, metal caliente y contratos inflamables.',
  stockCriterion: burnShopCriterion,
);

/// Tienda amarilla centrada en herramientas de Intoxicacion.
final toxinLabNode = ShopPathNode(
  nodeId: 'shop_toxin_lab',
  label: 'Laboratorio Toxico',
  tooltip: 'Catalogo dedicado a la Intoxicacion y sus derivados',
  iconEmoji: '\u2623',
  rarity: RarityTier.yellow,
  accent: EntityTag.intoxicacion.accent,
  badgeLabel: 'TOXICO',
  showTitle: 'Laboratorio Toxico',
  shopTitle: 'LABORATORIO TOXICO',
  shopSubtitle: 'Quimica corrosiva, filtros dudosos y venenos rentables.',
  stockCriterion: poisonShopCriterion,
);

/// Evento verde diurno preparado para futuras mejoras temporales.
final shadyTechnosurgeonNode = EventPathNode(
  id: PathEventId.shadyTechnosurgeon,
  nodeId: 'event_shady_technosurgeon',
  label: 'Shady Technosurgeon',
  tooltip: 'Un cirujano de callejon ofrece ajustes temporales',
  iconEmoji: '\u2695',
  rarity: RarityTier.green,
  accent: RarityTier.green.accent,
  badgeLabel: 'EVENTO',
  showTitle: 'Shady Technosurgeon',
  eventTitle: 'SHADY TECHNOSURGEON',
  description:
      'Un technosurgeon clandestino examina tus implantes y promete una mejora fugaz.',
  outcomeText:
      'Por ahora no aplica nada, pero la escena queda lista para efectos temporales.',
);

/// Tienda morada nocturna centrada en armas mas agresivas.
final afterHoursArsenalNode = ShopPathNode(
  nodeId: 'shop_after_hours_arsenal',
  label: 'Arsenal After Hours',
  tooltip: 'El mercado nocturno mueve armas mas agresivas',
  iconEmoji: '\u{1F52A}',
  rarity: RarityTier.purple,
  accent: RarityTier.purple.accent,
  badgeLabel: 'NOCHE',
  showTitle: 'Arsenal After Hours',
  shopTitle: 'ARSENAL AFTER HOURS',
  shopSubtitle: 'La noche trae filo, ruido y peores decisiones.',
  stockCriterion: weaponShopCriterion,
);

/// Tienda azul nocturna de blindajes y soportes defensivos.
final velvetArmoryNode = ShopPathNode(
  nodeId: 'shop_velvet_armory',
  label: 'Velvet Armory',
  tooltip: 'Protecciones discretas para aguantar la noche',
  iconEmoji: '\u{1F9E5}',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'ACERO',
  showTitle: 'Velvet Armory',
  shopTitle: 'VELVET ARMORY',
  shopSubtitle: 'Blindaje elegante para quien espera volver con vida.',
  stockCriterion: defenseShopCriterion,
);

/// Tienda morada nocturna de alquimia agresiva sin superar el stock azul.
final chemicalExchangeNode = ShopPathNode(
  nodeId: 'shop_chemical_exchange',
  label: 'Mercado Quimico',
  tooltip: 'Quemadura e Intoxicacion de alta gama, sin pasar de azul',
  iconEmoji: '\u{1F9EA}',
  rarity: RarityTier.purple,
  accent: RarityTier.purple.accent,
  badgeLabel: 'QUIMICA',
  showTitle: 'Mercado Quimico',
  shopTitle: 'MERCADO QUIMICO',
  shopSubtitle: 'Todo huele a disolvente. O peor',
  stockCriterion: burnOrPoisonShopCriterion,
);

/// Tienda azul nocturna para piezas que aplican o manipulan debuffs.
final debuffBrokerNode = ShopPathNode(
  nodeId: 'shop_debuff_broker',
  label: 'Broker de Debuffs',
  tooltip: 'Mercancia especializada en desventajas persistentes',
  iconEmoji: '\u26A0',
  rarity: RarityTier.blue,
  accent: EntityTag.debuff.accent,
  badgeLabel: 'DEBUFF',
  showTitle: 'Broker de Debuffs',
  shopTitle: 'BROKER DE DEBUFFS',
  shopSubtitle:
      'Venden dolor recurrente, mitigacion selectiva y efectos sucios.',
  stockCriterion: debuffShopCriterion,
);

/// Tienda azul nocturna para objetos que leen o castigan buffs.
final buffParlorNode = ShopPathNode(
  nodeId: 'shop_buff_parlor',
  label: 'Salon de Buffs',
  tooltip: 'Accesorios para explotar buffs o la ausencia de ellos',
  iconEmoji: '\u2728',
  rarity: RarityTier.blue,
  accent: EntityTag.buff.accent,
  badgeLabel: 'BUFF',
  showTitle: 'Salon de Buffs',
  shopTitle: 'SALON DE BUFFS',
  shopSubtitle:
      'Un escaparate pequeño pero muy especializado en mejoras corporales.',
  stockCriterion: buffShopCriterion,
);

/// Evento azul nocturno reservado para efectos temporales mas agresivos.
final afterHoursTechnosurgeonNode = EventPathNode(
  id: PathEventId.afterHoursTechnosurgeon,
  nodeId: 'event_after_hours_technosurgeon',
  label: 'Technosurgeon Nocturno',
  tooltip: 'Un especialista trasnochado ofrece modificaciones ilegales',
  iconEmoji: '\u2699',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'EVENTO',
  showTitle: 'Technosurgeon Nocturno',
  eventTitle: 'TECHNOSURGEON NOCTURNO',
  description:
      'Las luces de neon ocultan a un technosurgeon que ofrece un injerto express.',
  outcomeText:
      'Por ahora no altera tus estadisticas.', // TODO: aplicar efectos temporales nocturnos.'
);

/// Evento azul condicionado por Deuda que intenta cobrar la cuota pendiente.
final debtCollectionNode = EventPathNode(
  id: PathEventId.debtCollection,
  nodeId: 'event_debt_collection',
  label: 'Oficina de Cobros',
  tooltip: 'Un recaudador intenta cerrar tu deuda operativa',
  iconEmoji: '\u{1F4B8}',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'DEUDA',
  showTitle: 'La deuda te ha encontrado',
  eventTitle: 'OFICINA DE COBROS',
  description:
      'Un recaudador del circuito local intercepta tu ruta. O saldas la cuota pendiente o te cobran en carne y credito.',
  outcomeText:
      'La cantidad exacta se resuelve al entrar segun el saldo pendiente de tu Deuda.',
);

/// Nodo de descanso completo que recupera toda la vida.
final restZoneCampNode = CampSitePathNode(
  nodeId: 'camp_rest_zone',
  label: 'Zona de Descanso',
  tooltip: 'Recupera toda tu vida en un refugio seguro',
  iconEmoji: '\u{1F6CF}',
  rarity: RarityTier.green,
  accent: RarityTier.green.accent,
  badgeLabel: 'DESCANSO',
  showTitle: 'Has encontrado una zona de descanso',
  sceneTitle: 'ZONA DE DESCANSO',
  description: 'Recuperas toda tu vida.',
  recoveryFactor: 1,
);

/// Nodo de tratamiento parcial que cura y purga un debuff aleatorio.
final severeMedicationCampNode = CampSitePathNode(
  nodeId: 'camp_severe_medication',
  label: 'Medicacion Severa',
  tooltip: 'Recupera 33% de tu vida maxima y elimina un debuff aleatorio',
  iconEmoji: '\u{1F489}',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'TRATAMIENTO',
  showTitle: 'Has encontrado un modulo de medicacion severa',
  sceneTitle: 'MEDICACION SEVERA',
  description:
      'Recuperas 33% de tu vida maxima y eliminas un debuff aleatorio.',
  recoveryFactor: 1 / 3,
  removeRandomDebuff: true,
);

/// Tiendas posibles durante el tramo diurno de la run.
final List<ShopPathNode> dayShopNodes = List.unmodifiable([
  scrapArsenalNode,
  bulwarkWorkshopNode,
  emberFoundryNode,
  toxinLabNode,
]);

/// Arquetipos mostrados siempre en la primera hora.
final List<ArchetypePathNode> openingArchetypeNodes = List.unmodifiable([
  velozArchetypeNode,
  inamovibleArchetypeNode,
  imparableArchetypeNode,
]);

/// Eventos candidatos para el tramo diurno.
final List<EventPathNode> dayEventNodes = List.unmodifiable([
  shadyTechnosurgeonNode,
  debtCollectionNode,
]);

/// Tiendas posibles durante el tramo nocturno.
final List<ShopPathNode> nightShopNodes = List.unmodifiable([
  afterHoursArsenalNode,
  velvetArmoryNode,
  luxuryRelicsNode,
  emberFoundryNode,
  toxinLabNode,
  chemicalExchangeNode,
  debuffBrokerNode,
  buffParlorNode,
]);

/// Eventos candidatos para la noche, incluida la deuda si aplica.
final List<EventPathNode> nightEventNodes = List.unmodifiable([
  afterHoursTechnosurgeonNode,
  shadyTechnosurgeonNode,
  debtCollectionNode,
]);

/// Combates raros que pueden colarse de dia como amenaza extra.
final List<CombatPathNode> rareDayCombatNodes = List.unmodifiable([
  ...grayCombatNodes,
  ...greenCombatNodes,
]);

/// Combates fijos del anochecer que marcan el salto de fase.
final List<CombatPathNode> duskCombatNodes = List.unmodifiable([
  greenCombatNode,
  blueCombatNode,
  venomStitchCombatNode,
]);

/// Combates posibles del tramo nocturno normal.
final List<CombatPathNode> nightCombatNodes = List.unmodifiable([
  ...greenCombatNodes,
  ...blueCombatNodes,
  ...blueCombatNodes,
  ...purpleCombatNodes,
]);

/// Pool final de amanecer con el combate de cierre de run.
final List<CombatPathNode> sunriseCombatNodes = List.unmodifiable([
  yellowCombatNode,
]);

/// Registro canonico de nodos por id para evitar identidades basadas en texto visible.
final Map<String, PathNode> pathNodeRegistry =
    Map<String, PathNode>.unmodifiable({
  for (final node in <PathNode>[
    ...openingArchetypeNodes,
    ...dayShopNodes,
    ...dayEventNodes,
    ...nightShopNodes,
    ...nightEventNodes,
    ...grayCombatNodes,
    ...greenCombatNodes,
    ...blueCombatNodes,
    ...purpleCombatNodes,
    ...sunriseCombatNodes,
    restZoneCampNode,
    severeMedicationCampNode,
  ])
    node.nodeId: node,
});

/// Vista lineal del registro canonico, util para tooling y futuros validadores.
final List<PathNode> allPathNodes = List<PathNode>.unmodifiable(
  pathNodeRegistry.values,
);
