import '_imports.dart';

final scrapArsenalNode = ShopPathNode(
  label: 'Arsenal de Chatarra',
  tooltip: 'Armas funcionales antes del anochecer',
  iconEmoji: '\u2694',
  accent: const Color(0xFFDBB95A),
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
  accent: const Color(0xFF7DB5FF),
  badgeLabel: 'ARMADURA',
  showTitle: 'Taller Blindado',
  shopTitle: 'TALLER BLINDADO',
  shopSubtitle: 'Piezas defensivas montadas en el acto.',
  catalog: const [
    guardShieldItem,
    platedJacketItem,
  ],
);

final luxuryRelicsNode = ShopPathNode(
  label: 'Reliquias de Lujo',
  tooltip: 'Objetos de gran calidad y procedencia dudosa',
  iconEmoji: '\u{1F48E}',
  accent: const Color(0xFFF3D35C),
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
  label: 'Shady Technosurgeon',
  tooltip: 'Un cirujano de callejon ofrece ajustes temporales',
  iconEmoji: '\u2695',
  accent: const Color(0xFF55D4C8),
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
  accent: const Color(0xFFBE7CFF),
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
  accent: const Color(0xFF7B88FF),
  badgeLabel: 'ACERO',
  showTitle: 'Velvet Armory',
  shopTitle: 'VELVET ARMORY',
  shopSubtitle: 'Blindaje elegante para quien espera volver con vida.',
  catalog: const [
    platedJacketItem,
    midnightCloakItem,
    dawnCharmItem,
  ],
);

final afterHoursTechnosurgeonNode = EventPathNode(
  label: 'Technosurgeon Nocturno',
  tooltip: 'Un especialista trasnochado ofrece modificaciones ilegales',
  iconEmoji: '\u2699',
  accent: const Color(0xFF59B7FF),
  badgeLabel: 'EVENTO',
  showTitle: 'Technosurgeon Nocturno',
  eventTitle: 'TECHNOSURGEON NOCTURNO',
  description:
      'Las luces de neón ocultan a un technosurgeon que ofrece un injerto express.',
  outcomeText:
      'Por ahora no altera tus estadisticas. TODO: aplicar efectos temporales nocturnos.',
);

const dayCampNode = PathNode.campSite(
  label: 'Campamento de Ruta',
  tooltip: 'Un respiro breve antes de que caiga el sol',
);

final List<ShopPathNode> dayShopNodes = List.unmodifiable([
  scrapArsenalNode,
  bulwarkWorkshopNode,
  luxuryRelicsNode,
]);

final List<EventPathNode> dayEventNodes = List.unmodifiable([
  shadyTechnosurgeonNode,
]);

final List<ShopPathNode> nightShopNodes = List.unmodifiable([
  afterHoursArsenalNode,
  velvetArmoryNode,
  luxuryRelicsNode,
]);

final List<EventPathNode> nightEventNodes = List.unmodifiable([
  afterHoursTechnosurgeonNode,
  shadyTechnosurgeonNode,
]);

final List<CombatPathNode> rareDayCombatNodes = List.unmodifiable([
  grayCombatNode,
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
