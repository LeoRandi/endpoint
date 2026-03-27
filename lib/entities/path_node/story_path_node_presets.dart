import '_imports.dart';

final velozArchetypeNode = ArchetypePathNode(
  label: 'Veloz',
  tooltip:
      'Cyber Latigos + Gafas de Sol. Perfil agil con un poco mas de ataque base. Empieza con 4C y 3 income.',
  iconEmoji: cyberWhipsItem.iconEmoji,
  playerIconEmoji: cyberWhipsItem.iconEmoji,
  accent: const Color(0xFF59B7FF),
  rarity: RarityTier.blue,
  baseStatModifiers: const {
    BattlerStat.attack: 1,
  },
  moneyModifier: 4,
  incomeModifier: 3,
  startingItems: const [
    cyberWhipsItem,
    sunglassesItem,
  ],
  startingAbilities: const [
    criticalScannerAbility,
  ],
);

final inamovibleArchetypeNode = ArchetypePathNode(
  label: 'Inamovible',
  tooltip:
      'Escudo + Amuleto de Bastion. Perfil resistente con mas defensa y aguante base. Empieza con 6C y 2 income.',
  iconEmoji: shieldItem.iconEmoji,
  playerIconEmoji: shieldItem.iconEmoji,
  accent: const Color(0xFF5AF78E),
  rarity: RarityTier.green,
  baseStatModifiers: const {
    BattlerStat.health: 4,
    BattlerStat.defense: 1,
  },
  moneyModifier: 6,
  incomeModifier: 2,
  startingItems: const [
    shieldItem,
    bulwarkAmuletItem,
  ],
);

final imparableArchetypeNode = ArchetypePathNode(
  label: 'Imparable',
  tooltip:
      'Espada de Hierro + Amuleto de Ascuas. Perfil ofensivo con mas pegada base. Empieza con 4C y 2 income.',
  iconEmoji: ironSwordItem.iconEmoji,
  playerIconEmoji: ironSwordItem.iconEmoji,
  accent: const Color(0xFFF3D35C),
  rarity: RarityTier.yellow,
  baseStatModifiers: const {
    BattlerStat.attack: 2,
  },
  moneyModifier: 4,
  incomeModifier: 2,
  startingItems: const [
    ironSwordItem,
    emberCharmItem,
  ],
  startingAbilities: const [
    criticalScannerAbility,
  ],
);

final scrapArsenalNode = ShopPathNode(
  label: 'Arsenal de Chatarra',
  tooltip: 'Armas funcionales antes del anochecer',
  iconEmoji: '\u2694',
  rarity: RarityTier.gray,
  accent: RarityTier.gray.accent,
  badgeLabel: 'ARMAS',
  showTitle: 'Arsenal de Chatarra',
  shopTitle: 'ARSENAL DE CHATARRA',
  shopSubtitle: 'Herramientas rapidas para sobrevivir a las primeras horas.',
  catalog: const [
    woodenStickItem,
    ironSwordItem,
  ],
);

final bulwarkWorkshopNode = ShopPathNode(
  label: 'Taller Blindado',
  tooltip: 'Protecciones para aguantar hasta la noche',
  iconEmoji: '\u{1F6E1}',
  rarity: RarityTier.green,
  accent: RarityTier.green.accent,
  badgeLabel: 'ARMADURA',
  showTitle: 'Taller Blindado',
  shopTitle: 'TALLER BLINDADO',
  shopSubtitle: 'Piezas defensivas montadas en el acto.',
  catalog: const [
    toxicCatalystItem,
    guardShieldItem,
    platedJacketItem,
  ],
);

final luxuryRelicsNode = ShopPathNode(
  label: 'Reliquias de Lujo',
  tooltip: 'Objetos de gran calidad y procedencia dudosa',
  iconEmoji: '\u{1F48E}',
  rarity: RarityTier.yellow,
  accent: RarityTier.yellow.accent,
  badgeLabel: 'LUJO',
  showTitle: 'Reliquias de Lujo',
  shopTitle: 'RELIQUIAS DE LUJO',
  shopSubtitle:
      'Mercancia premium. TODO: conectar precios altos cuando exista economia.',
  catalog: const [
    sunsteelBladeItem,
    dawnCharmItem,
    voidInjectorItem,
  ],
);

final shadyTechnosurgeonNode = EventPathNode(
  id: PathEventId.shadyTechnosurgeon,
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

final afterHoursArsenalNode = ShopPathNode(
  label: 'Arsenal After Hours',
  tooltip: 'El mercado nocturno mueve armas mas agresivas',
  iconEmoji: '\u{1F52A}',
  rarity: RarityTier.purple,
  accent: RarityTier.purple.accent,
  badgeLabel: 'NOCHE',
  showTitle: 'Arsenal After Hours',
  shopTitle: 'ARSENAL AFTER HOURS',
  shopSubtitle: 'La noche trae filo, ruido y peores decisiones.',
  catalog: const [
    ironSwordItem,
    sunsteelBladeItem,
    voidInjectorItem,
  ],
);

final velvetArmoryNode = ShopPathNode(
  label: 'Velvet Armory',
  tooltip: 'Protecciones discretas para aguantar la noche',
  iconEmoji: '\u{1F9E5}',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'ACERO',
  showTitle: 'Velvet Armory',
  shopTitle: 'VELVET ARMORY',
  shopSubtitle: 'Blindaje elegante para quien espera volver con vida.',
  catalog: const [
    platedJacketItem,
    reactiveCasingItem,
    midnightCloakItem,
    dawnCharmItem,
  ],
);

final afterHoursTechnosurgeonNode = EventPathNode(
  id: PathEventId.afterHoursTechnosurgeon,
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
      'Por ahora no altera tus estadisticas. TODO: aplicar efectos temporales nocturnos.',
);

final debtCollectionNode = EventPathNode(
  id: PathEventId.debtCollection,
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

final restZoneCampNode = CampSitePathNode(
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

final severeMedicationCampNode = CampSitePathNode(
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

final List<ShopPathNode> dayShopNodes = List.unmodifiable([
  scrapArsenalNode,
  bulwarkWorkshopNode,
  luxuryRelicsNode,
]);

final List<ArchetypePathNode> openingArchetypeNodes = List.unmodifiable([
  velozArchetypeNode,
  inamovibleArchetypeNode,
  imparableArchetypeNode,
]);

final List<EventPathNode> dayEventNodes = List.unmodifiable([
  shadyTechnosurgeonNode,
  debtCollectionNode,
]);

final List<ShopPathNode> nightShopNodes = List.unmodifiable([
  afterHoursArsenalNode,
  velvetArmoryNode,
  luxuryRelicsNode,
]);

final List<EventPathNode> nightEventNodes = List.unmodifiable([
  afterHoursTechnosurgeonNode,
  shadyTechnosurgeonNode,
  debtCollectionNode,
]);

final List<CombatPathNode> rareDayCombatNodes = List.unmodifiable([
  grayCombatNode,
  greenCombatNode,
  blueCombatNode,
]);

final List<CombatPathNode> duskCombatNodes = List.unmodifiable([
  greenCombatNode,
  blueCombatNode,
  greenCombatNode,
]);

final List<CombatPathNode> nightCombatNodes = List.unmodifiable([
  greenCombatNode,
  blueCombatNode,
  blueCombatNode,
  purpleCombatNode,
]);

final List<CombatPathNode> sunriseCombatNodes = List.unmodifiable([
  yellowCombatNode,
]);
