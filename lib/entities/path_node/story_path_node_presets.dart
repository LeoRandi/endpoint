import '../_imports.dart';
import '../../services/run/run_randomizer.dart';

const _scrapShopAccent = Color(0xFFB8C0CC);
const _greenItemShopAccent = Color(0xFF3FE88F);
const _luxuryShopAccent = Color(0xFFFFD56B);
const _emberShopAccent = Color(0xFFFF6A2A);
const _toxinShopAccent = Color(0xFFB9F25C);
const _afterHoursArsenalAccent = Color(0xFFFF4D6D);
const _velvetArmoryAccent = Color(0xFFA95CFF);
const _chemicalExchangeAccent = Color(0xFF4DE7D2);
const _debuffBrokerAccent = Color(0xFFFF5A5F);
const _buffParlorAccent = Color(0xFFFF8BE8);
const _impActsAccent = Color(0xFFF3D35C);
const _firstAidAccent = Color(0xFFFF8BA7);
const _mendingAccent = Color(0xFF59B7FF);
const _gangananciasAccent = Color(0xFFEBCB5A);
const _routineMarketAccent = Color(0xFFC0C0C0);
const _resonanceBankAccent = Color(0xFFD0D5DE);
const _duelowPricesAccent = Color(0xFF55D6C2);
const _contagionCompanyAccent = Color(0xFFB56DFF);

/// Arquetipo agil orientado a ataque ligero y economia temprana.
final velozArchetypeNode = ArchetypePathNode(
  archetypeId: ArchetypeId.veloz,
  nodeId: 'archetype_veloz',
  label: 'Veloz',
  tooltip:
      '1 item Veloz verde + 1 item general gris. Perfil agil de doble golpe que castiga objetivos debilitados. Empieza con 8C y 4 income.',
  iconEmoji: cyberWhipsItem.iconEmoji,
  playerIconEmoji: cyberWhipsItem.iconEmoji,
  accent: const Color(0xFF59B7FF),
  rarity: RarityTier.blue,
  baseStatModifiers: const {
    BattlerStat.attack: 1,
    BattlerStat.barrier: 1,
  },
  moneyModifier: 8,
  incomeModifier: 4,
  startingItems: const [],
  startingAbilities: const [
    weaknessHunterAbility,
  ],
);

/// Arquetipo defensivo centrado en vida, barrera y estabilidad.
final inamovibleArchetypeNode = ArchetypePathNode(
  archetypeId: ArchetypeId.inamovible,
  nodeId: 'archetype_inamovible',
  label: 'Inamovible',
  tooltip:
      '1 item Inamovible verde + 1 item general gris. Perfil resistente con regeneracion pasiva y barrera sostenida. Empieza con 12C y 3 income.',
  iconEmoji: shieldItem.iconEmoji,
  playerIconEmoji: shieldItem.iconEmoji,
  accent: const Color(0xFF5AF78E),
  rarity: RarityTier.green,
  baseStatModifiers: const {
    BattlerStat.health: 5,
    BattlerStat.barrier: 2,
  },
  moneyModifier: 12,
  incomeModifier: 3,
  startingItems: const [],
  startingAbilities: const [
    pulsoRepLAbility,
    kilotonificacionAbility,
  ],
);

/// Arquetipo ofensivo que arranca con mas presion de daño.
final imparableArchetypeNode = ArchetypePathNode(
  archetypeId: ArchetypeId.imparable,
  nodeId: 'archetype_imparable',
  label: 'Imparable',
  tooltip:
      '1 item Imparable verde + 1 item general gris. Perfil ofensivo con mas pegada base y daño extra al pelear herido. Empieza con 8C y 3 income.',
  iconEmoji: ironSwordItem.iconEmoji,
  playerIconEmoji: ironSwordItem.iconEmoji,
  accent: const Color(0xFFFF5A5F),
  rarity: RarityTier.yellow,
  baseStatModifiers: const {
    BattlerStat.health: 5,
    BattlerStat.attack: 2,
  },
  moneyModifier: 8,
  incomeModifier: 3,
  startingItems: const [],
  startingAbilities: const [
    furiaHematicaAbility,
  ],
);

final _merchantGrayPreviewItem = woodenStickItem.copyWith(
  name: 'Objeto Gris Aleatorio',
  description:
      'Al confirmar este arquetipo recibiras un objeto gris aleatorio.',
  iconEmoji: '\u{1F3B2}',
  rarity: RarityTier.gray,
  baseCost: 0,
  value: 0,
  upgradeValue: 0,
  statModifiers: const {},
  upgradeStatModifiers: const {},
  clearEffect: true,
);

final _merchantGreenPreviewItem = shieldItem.copyWith(
  name: 'Objeto Verde Aleatorio',
  description:
      'Al confirmar este arquetipo recibiras un objeto verde aleatorio.',
  iconEmoji: '\u{1F4E6}',
  rarity: RarityTier.green,
  baseCost: 0,
  value: 0,
  upgradeValue: 0,
  statModifiers: const {},
  upgradeStatModifiers: const {},
  clearEffect: true,
);

/// Construye el loadout aleatorio real del Mercante al confirmar arquetipo.
///
/// Los items de preview solo comunican rareza; esta funcion consume el randomizer
/// de la run para entregar dos grises distintos y un verde distinto.
List<Item> _buildMerchantStartingItems(RunRandomizer randomizer) {
  final grayItems = itemPresets
      .where((item) => item.rarity == RarityTier.gray)
      .toList(growable: false);
  final greenItems = itemPresets
      .where((item) => item.rarity == RarityTier.green)
      .toList(growable: false);

  return List<Item>.unmodifiable([
    ...randomizer.pickDistinct(grayItems, 2),
    ...randomizer.pickDistinct(greenItems, 1),
  ]);
}

/// Arquetipo economico flexible que empieza con stock aleatorio y caja extra.
final mercanteArchetypeNode = ArchetypePathNode(
  archetypeId: ArchetypeId.mercante,
  nodeId: 'archetype_mercante',
  label: 'Mercante',
  tooltip:
      '2 objetos grises aleatorios + 1 verde aleatorio. Perfil de dinero, adaptacion y viraje a mitad de run. Empieza con 13C, 5 income y Flujo de Caja.',
  iconEmoji: '\u{1F4B0}',
  playerIconEmoji: '\u{1F4B3}',
  accent: const Color(0xFFEBCB5A),
  rarity: RarityTier.blue,
  baseStatModifiers: const {
    BattlerStat.health: 10,
  },
  moneyModifier: 13,
  incomeModifier: 5,
  startingItems: [
    _merchantGrayPreviewItem,
    _merchantGrayPreviewItem,
    _merchantGreenPreviewItem,
  ],
  startingItemsBuilder: _buildMerchantStartingItems,
  startingAbilities: const [
    cashflowAbility,
  ],
);

/// Criterio gris para tiendas de entrada con objetos baratos y comunes.
final grayShopCriterion = ShopInventoryCriterion(
  label: 'RAREZA GRIS',
  description: 'Solo aparecen objetos grises de bajo valor.',
  exactRarity: RarityTier.gray,
);

/// Criterio verde general para tiendas de objetos de rareza verde.
final greenItemShopCriterion = ShopInventoryCriterion(
  label: 'TIER VERDE',
  description: 'Solo aparecen objetos de rareza verde.',
  exactRarity: RarityTier.green,
);

/// Criterio trampa para tiendas que venden objetos verdes y azules mas caros.
final scamUpgradeShopCriterion = ShopInventoryCriterion(
  label: 'VERDE / AZUL',
  description: 'Solo aparecen objetos de rareza verde o azul.',
  minimumRarity: RarityTier.green,
  maximumRarity: RarityTier.blue,
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
  description: 'Solo aparecen objetos con la tag de Arma.',
  requiredTags: [
    EntityTag.arma,
  ],
);

/// Criterio defensivo amplio para objetos que aportan barrera directa.
final barrierShopCriterion = ShopInventoryCriterion(
  label: 'BARRERA',
  description: 'Solo aparecen objetos que otorgan barrera.',
  requiredPositiveModifierStat: BattlerStat.barrier,
);

/// Criterio de vida para tiendas centradas en aguantar mas tiempo.
final healthShopCriterion = ShopInventoryCriterion(
  label: 'VIDA',
  description: 'Solo aparecen objetos grises con la tag de Vida.',
  exactRarity: RarityTier.gray,
  requiredTags: [
    EntityTag.vida,
  ],
);

/// Criterio ofensivo por tag para tiendas de daño directo.
final attackShopCriterion = ShopInventoryCriterion(
  label: 'ATAQUE',
  description: 'Solo aparecen objetos grises con la tag de Ataque.',
  exactRarity: RarityTier.gray,
  requiredTags: [
    EntityTag.ataque,
  ],
);

/// Criterio gris defensivo para objetos que aportan barrera directa.
final grayBarrierShopCriterion = ShopInventoryCriterion(
  label: 'BARRERA',
  description: 'Solo aparecen objetos grises que otorgan barrera.',
  exactRarity: RarityTier.gray,
  requiredPositiveModifierStat: BattlerStat.barrier,
);

/// Criterio economico para tiendas centradas en dinero y valor.
final economyShopCriterion = ShopInventoryCriterion(
  label: 'ECONOMIA',
  description: 'Solo aparecen objetos verdes con la tag de Economia.',
  exactRarity: RarityTier.green,
  requiredTags: [
    EntityTag.economia,
  ],
);

/// Criterio de ciclo para piezas que premian la cadencia de la run.
final cycleShopCriterion = ShopInventoryCriterion(
  label: 'CICLO',
  description: 'Solo aparecen objetos verdes con la tag de Ciclo.',
  exactRarity: RarityTier.green,
  requiredTags: [
    EntityTag.ciclo,
  ],
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

/// Criterio azul para objetos de Resonancia.
final resonanceShopCriterion = ShopInventoryCriterion(
  label: 'RESONANCIA',
  description: 'Solo aparecen objetos con la tag de Resonancia.',
  requiredTags: [
    EntityTag.resonancia,
  ],
);

/// Criterio azul para objetos de Desafio.
final challengeShopCriterion = ShopInventoryCriterion(
  label: 'DESAFIO',
  description: 'Solo aparecen objetos con la tag de Desafio.',
  requiredTags: [
    EntityTag.desafio,
  ],
);

/// Criterio azul para objetos de Contagio.
final contagionShopCriterion = ShopInventoryCriterion(
  label: 'CONTAGIO',
  description: 'Solo aparecen objetos con la tag de Contagio.',
  requiredTags: [
    EntityTag.contagio,
  ],
);

/// Criterio hibrido para piezas tacticas de ataque y barrera.
final tacticsShopCriterion = ShopInventoryCriterion(
  label: 'ATAQUE / BARRERA',
  description: 'Solo aparecen objetos con las tags de Ataque y Barrera.',
  requiredTags: [
    EntityTag.ataque,
    EntityTag.barrera,
  ],
);

/// Tienda gris de armas basicas para las primeras horas.
final scrapArsenalNode = ShopPathNode(
  nodeId: 'shop_scrap_arsenal',
  label: 'Arsenal de Chatarra',
  tooltip: 'Armas funcionales antes del anochecer',
  iconEmoji: '\u2694',
  rarity: RarityTier.gray,
  accent: _scrapShopAccent,
  badgeLabel: 'ARMAS',
  showTitle: 'Arsenal de Chatarra',
  shopTitle: 'ARSENAL DE CHATARRA',
  shopSubtitle:
      'Herramientas rapidas y mercancia de entrada para la primera hora.',
  stockCriterion: grayShopCriterion,
);

/// Tienda gris de vida y supervivencia temprana.
final firstAidStandNode = ShopPathNode(
  nodeId: 'shop_first_aid_stand',
  label: 'Puesto de Primeros Auxilios',
  tooltip: 'Suministros basicos para seguir respirando',
  iconEmoji: '\u{1FA79}',
  rarity: RarityTier.gray,
  accent: _firstAidAccent,
  badgeLabel: 'VIDA',
  showTitle: 'Puesto de Primeros Auxilios',
  shopTitle: 'PUESTO DE PRIMEROS AUXILIOS',
  shopSubtitle:
      'Gasas limpias, reanimadores y la promesa de seguir respirando.',
  stockCriterion: healthShopCriterion,
);

/// Tienda gris centrada en objetos de ataque.
final impActsNode = ShopPathNode(
  nodeId: 'shop_imp_acts',
  label: 'Imp Acts',
  tooltip: 'Herramientas tempranas para hacer daño',
  iconEmoji: '\u{1F528}',
  rarity: RarityTier.gray,
  accent: _impActsAccent,
  badgeLabel: 'ATAQUE',
  showTitle: 'Imp Acts',
  shopTitle: 'IMP ACTS',
  shopSubtitle: 'Todo pesa, corta o golpea. Algunas cosas hacen las tres.',
  stockCriterion: attackShopCriterion,
);

/// Tienda gris centrada en protecciones de entrada.
final remiendosAndDontsNode = ShopPathNode(
  nodeId: 'shop_remiendos_and_donts',
  label: "Remiendos and don'ts",
  tooltip: 'Blindaje barato con advertencias razonables',
  iconEmoji: '\u{1F9F5}',
  rarity: RarityTier.gray,
  accent: _mendingAccent,
  badgeLabel: 'BARRERA',
  showTitle: "Remiendos and don'ts",
  shopTitle: "REMIENDOS AND DON'TS",
  shopSubtitle: 'Placas torcidas, cierres rapidos y blindaje con historial.',
  stockCriterion: grayBarrierShopCriterion,
);

/// Tienda gris sospechosa con stock superior a precio inflado.
final gangananciasNode = ShopPathNode(
  nodeId: 'shop_ganganancias',
  label: 'Ganganancias',
  tooltip: 'Objetos verdes y azules al doble de precio',
  iconEmoji: '\u{1F4B8}',
  rarity: RarityTier.gray,
  accent: _gangananciasAccent,
  badgeLabel: 'TRATO',
  showTitle: 'Ganganancias',
  shopTitle: 'GANGANANCIAS',
  shopSubtitle: 'Ofertas demasiado buenas para ser verdad y aun mas caras.',
  stockCriterion: scamUpgradeShopCriterion,
  priceMultiplier: 2,
);

/// Tienda verde generalista de objetos de rareza verde.
final greenItemVendorNode = ShopPathNode(
  nodeId: 'shop_bulwark_workshop',
  label: 'Vendedor Verde',
  tooltip: 'Objetos de rareza verde sin especialidad fija',
  iconEmoji: '\u{1F4E6}',
  rarity: RarityTier.green,
  accent: _greenItemShopAccent,
  badgeLabel: 'VERDE',
  showTitle: 'Vendedor Verde',
  shopTitle: 'VENDEDOR VERDE',
  shopSubtitle: 'Un puesto directo: todo el stock es de rareza verde.',
  stockCriterion: greenItemShopCriterion,
);

/// Tienda verde Mercante de economia.
final cambientGoldSellerNode = ShopPathNode(
  nodeId: 'shop_cambient_gold_seller',
  label: 'Cambient Gold Seller',
  tooltip: 'Mercado economico reservado para Mercante',
  iconEmoji: '\u{1F4B1}',
  rarity: RarityTier.green,
  accent: _gangananciasAccent,
  badgeLabel: 'ORO',
  showTitle: 'Cambient Gold Seller',
  shopTitle: 'CAMBIENT GOLD SELLER',
  shopSubtitle:
      'Comisiones abusivas, oportunidades reales y recibos imposibles.',
  stockCriterion: economyShopCriterion,
  possibleArchetypes: const [
    ArchetypeId.mercante,
  ],
);

/// Tienda verde Veloz de ciclo.
final routineMarketNode = ShopPathNode(
  nodeId: 'shop_routine_market',
  label: 'Routine Market',
  tooltip: 'Piezas de ciclo reservadas para Veloz',
  iconEmoji: '\u{1F501}',
  rarity: RarityTier.green,
  accent: _routineMarketAccent,
  badgeLabel: 'CICLO',
  showTitle: 'Routine Market',
  shopTitle: 'ROUTINE MARKET',
  shopSubtitle:
      'Maquinas repetitivas, relojes abiertos y piezas que vuelven solas.',
  stockCriterion: cycleShopCriterion,
  possibleArchetypes: const [
    ArchetypeId.veloz,
  ],
);

/// Tienda amarilla de reliquias caras y poderosas.
final luxuryRelicsNode = ShopPathNode(
  nodeId: 'shop_luxury_relics',
  label: 'Reliquias de Lujo',
  tooltip: 'Objetos de gran calidad y procedencia dudosa',
  iconEmoji: '\u{1F48E}',
  rarity: RarityTier.yellow,
  accent: _luxuryShopAccent,
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
  accent: _emberShopAccent,
  badgeLabel: 'QUEMA',
  showTitle: 'Forja de Ascuas',
  shopTitle: 'FORJA DE ASCUAS',
  shopSubtitle: 'Brasa embotellada, metal caliente y contratos inflamables.',
  stockCriterion: burnShopCriterion,
  possibleArchetypes: const [
    ArchetypeId.imparable,
  ],
);

/// Tienda amarilla centrada en herramientas de Intoxicacion.
final toxinLabNode = ShopPathNode(
  nodeId: 'shop_toxin_lab',
  label: 'Laboratorio Toxico',
  tooltip: 'Catalogo dedicado a la Intoxicacion y sus derivados',
  iconEmoji: '\u2623',
  rarity: RarityTier.yellow,
  accent: _toxinShopAccent,
  badgeLabel: 'TOXICO',
  showTitle: 'Laboratorio Toxico',
  shopTitle: 'LABORATORIO TOXICO',
  shopSubtitle: 'Quimica corrosiva, filtros dudosos y venenos rentables.',
  stockCriterion: poisonShopCriterion,
  possibleArchetypes: const [
    ArchetypeId.veloz,
  ],
);

/// Hallazgo gris temprano que entrega equipo del arquetipo actual.
final strandedTrashNode = EventPathNode(
  id: PathEventId.strandedTrash,
  nodeId: 'event_stranded_trash',
  label: 'Basura Varada',
  tooltip: 'Encuentra un objeto gris gratis del arquetipo actual',
  iconEmoji: '\u{1F5D1}',
  rarity: RarityTier.gray,
  accent: RarityTier.gray.accent,
  badgeLabel: 'HALLAZGO',
  showTitle: 'Has encontrado basura varada',
  eventTitle: 'BASURA VARADA',
  description:
      'Un monton de chatarra quedo atascado entre dos barreras de contencion. Algo util todavia parpadea debajo.',
  outcomeText: 'Recibes un objeto gris del arquetipo actual.',
  flavorTexts: [
    'La ruta se estrecha junto a un canal seco. Entre plasticos, cables y etiquetas viejas, una pieza aun conserva carga.',
    'No parece elegante, pero encaja con tus protocolos. A veces la calle tambien hace entregas.',
  ],
);

/// Hallazgo verde temprano que entrega equipo del arquetipo actual.
final lostCacheNode = EventPathNode(
  id: PathEventId.lostCache,
  nodeId: 'event_lost_cache',
  label: 'Alijo Perdido',
  tooltip: 'Encuentra un objeto verde gratis del arquetipo actual',
  iconEmoji: '\u{1F4E6}',
  rarity: RarityTier.green,
  accent: RarityTier.green.accent,
  badgeLabel: 'CACHE',
  showTitle: 'Has encontrado un alijo perdido',
  eventTitle: 'ALIJO PERDIDO',
  description:
      'Una caja de suministro aparece bajo un falso panel de mantenimiento. El sello esta roto, pero el contenido sigue intacto.',
  outcomeText: 'Recibes un objeto verde del arquetipo actual.',
  flavorTexts: [
    'El contenedor no figura en ningun mapa operativo. Eso suele ser una mala senal, salvo cuando se abre sin explotar.',
    'Dentro hay piezas limpias, ordenadas y demasiado compatibles con tu equipo como para ser casualidad.',
  ],
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
      'Un cirujano clandestino ofrece reciclar un aumento en un protocolo de tier superior.',
  outcomeText: 'Elige un aumento para someterlo a una mutacion controlada.',
  flavorTexts: [
    'Te adentras en un callejón oscuro, esperando que te sirva de atajo. En su lugar, bajo un cartel de neón parpadeante, encuentras a un cirujano que ofrece "servicios", por un precio claro.',
    'El cirujano abre su maletín, despliega herramientas extravagantes sobre una mesa sin esterilizar, y pide que apoyes el brazo.',
  ],
);

/// Mercado clandestino de aumentos con precio segun tier ofertado.
final blackTechnoMarketNode = EventPathNode(
  id: PathEventId.blackTechnoMarket,
  nodeId: 'event_black_techno_market',
  label: 'Black techno-market',
  tooltip: 'Tres aumentos pirateados se venden por tier',
  iconEmoji: '\u{1F578}',
  rarity: RarityTier.purple,
  accent: RarityTier.purple.accent,
  badgeLabel: 'MERCADO',
  showTitle: 'Black techno-market',
  eventTitle: 'BLACK TECHNO-MARKET',
  description: 'Tres orbes de aumento aleatorios orbitan sobre la mesa.',
  outcomeText: 'Elige un aumento y paga su coste para integrarlo.',
  flavorTexts: [
    'Entras a un mercado en plena calle. Llama tu atención un mercader en concreto, que vigila sin mucho interés unos orbes sobre una mesa de mármol',
    'Los orbes giran en sus platos de control, de forma inestable. El mercader te mira enfurruñado, y te pide que no le hagas perder el tiempo.',
  ],
);

/// Evento azul donde una start-up mejora equipo gratis con coste oculto.
final sobreKarNode = EventPathNode(
  id: PathEventId.sobreKar,
  nodeId: 'event_sobre_kar',
  label: 'SobreKar',
  tooltip: 'Mejora un objeto gratis y acepta un efecto secundario aleatorio',
  iconEmoji: '\u{1F697}',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'EVENTO',
  showTitle: 'SobreKar',
  eventTitle: 'SOBREKAR',
  description:
      'Un chatarrero novato quiere hacer lucir su nueva start-up mejorando uno de tus objetos gratuitamente. ¿Qué podría salir mal?',
  outcomeText:
      'Selecciona un objeto para mejorarlo gratis. Al terminar, recibirás un debuff aleatorio.',
  flavorTexts: [
    'Un chatarrero novato te para en la calle',
    '<¡Ey, perdona, estamos haciendo muestras gratuitas de nuestros servicios! ¿Te interesaría reforzar alguno de tus objetos?>',
  ],
);

/// Evento azul donde una mujer cromada ofrece asegurar un nodo futuro.
final pasadizoSecretoNode = EventPathNode(
  id: PathEventId.pasadizoSecreto,
  nodeId: 'event_pasadizo_secreto',
  label: 'Pasadizo Secreto',
  tooltip: 'Ofrece forzar una oferta de tienda o evento por 10 creditos',
  iconEmoji: '\u{1F9CA}',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'TRATO',
  showTitle: 'Pasadizo Secreto',
  eventTitle: 'PASADIZO SECRETO',
  description:
      'Una mujer cromada te ofrece un trato: pagar 10C para asegurar una ruta concreta en la siguiente eleccion.',
  outcomeText:
      'Selecciona una tienda o evento, paga 10C y ese nodo aparecera en la siguiente tanda.',
  flavorTexts: [
    'Desde un callejon lateral, una mujer cromada de pies a cabeza te hace una senal con la mano.',
    'Promete una via mas placentera si aceptas el trato y pones creditos sobre la mesa.',
  ],
);

/// Evento de subasta donde puedes vender, reciclar o intercambiar piezas de la run.
final suBastaYaNode = EventPathNode(
  id: PathEventId.suBastaYa,
  nodeId: 'event_su_basta_ya',
  label: 'SU-Basta-Ya',
  tooltip: 'Subasta objetos, recicla stats o intercambia aumentos',
  iconEmoji: '\u{1F4E2}',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'SUBASTA',
  showTitle: 'Has encontrado una subasta de chatarra',
  eventTitle: 'SU-BASTA-YA',
  description:
      'Un operador ha puesto precio a todo lo que llevas encima. Puedes subastar un objeto, reciclarlo por stats o cambiar un aumento.',
  outcomeText: 'Elige un trato o rechaza todas las ofertas.',
  flavorTexts: [
    'Varias pantallas se iluminan cuando cruzas el umbral. Tu inventario aparece listado antes de que lo autorices.',
    'El subastador no mira a nadie en concreto. Solo golpea la mesa, sonrie y espera que algo tuyo deje de pertenecerte.',
  ],
);

/// Evento ritual que elimina debuffs, cura con ofrendas o reduce cooldowns.
final pitonisaQuitapenasNode = EventPathNode(
  id: PathEventId.pitonisaQuitapenas,
  nodeId: 'event_pitonisa_quitapenas',
  label: 'Pitonisa Quitapenas',
  tooltip: 'Purga debuffs, cura con una ofrenda o paga por reducir un cooldown',
  iconEmoji: '\u{1F52E}',
  rarity: RarityTier.purple,
  accent: RarityTier.purple.accent,
  badgeLabel: 'RITUAL',
  showTitle: 'Has encontrado a la Pitonisa Quitapenas',
  eventTitle: 'PITONISA QUITAPENAS',
  description:
      'La cabina huele a incienso quemado y plastico caliente. La pitonisa promete quitarte una pena, pero cada alivio exige una decision o creditos.',
  outcomeText: 'Elige que pena quieres dejar atras.',
  flavorTexts: [
    'La cortina se cierra sola a tu espalda. Una voz suave enumera tus fallos con una precision bastante incomoda.',
    'Sobre la mesa hay cartas, cables y un lector de cooldowns. La pitonisa no pregunta que te duele; ya lo sabe.',
  ],
);

final clinicaReflejosNode = EventPathNode(
  id: PathEventId.clinicaReflejos,
  nodeId: 'event_clinica_reflejos',
  label: 'Clinica de Reflejos',
  tooltip: 'Aumento Veloz o 6 Quemadura por +1 ATK permanente',
  iconEmoji: '\u{1F489}',
  rarity: RarityTier.green,
  accent: RarityTier.green.accent,
  badgeLabel: 'VELOZ',
  showTitle: 'Has encontrado la Clinica de Reflejos',
  eventTitle: 'CLINICA DE REFLEJOS',
  description:
      'Una clinica de latencia mide tus parpadeos y ofrece acelerar tus protocolos. Puedes aceptar un aumento Veloz calibrado para esta fase de la run o una inyeccion ardiente por potencia permanente.',
  outcomeText: 'Elige una intervencion.',
  flavorTexts: [
    'El visor de diagnostico sigue tus ojos antes de que termines de entrar.',
    'La doctora no pregunta si corres rapido. Solo pregunta cuanto dolor cabe en ese margen.',
  ],
);

final viktorOperationsNode = EventPathNode(
  id: PathEventId.viktorOperations,
  nodeId: 'event_viktor_operations',
  label: 'Viktor Operations',
  tooltip: 'Mejora a morado un item de Contagio, Debuff o Intoxicacion',
  iconEmoji: '\u{1F9EA}',
  rarity: RarityTier.purple,
  accent: RarityTier.purple.accent,
  badgeLabel: 'VELOZ',
  showTitle: 'Viktor Operations abre la puerta',
  eventTitle: 'VIKTOR OPERATIONS',
  description:
      'Un doctor impecablemente limpio ofrece mejorar uno de tus objetos "especialmente deliciosos". Solo acepta piezas de Contagio, Debuff o Intoxicacion que aun no sean moradas ni amarillas.',
  outcomeText: 'Selecciona un objeto compatible para elevarlo a MORADO.',
  flavorTexts: [
    'La sala no tiene polvo, ni sangre, ni historia. Viktor sonrie como si eso fuera normal.',
    'Sus guantes rozan el aire encima de tu inventario. "Este tiene sabor", dice.',
  ],
);

final arquitecbrosSlNode = EventPathNode(
  id: PathEventId.arquitecbrosSl,
  nodeId: 'event_arquitecbros_sl',
  label: 'Arquitecbros SL',
  tooltip: 'Muralla futura y stats permanentes, o combate morado',
  iconEmoji: '\u{1F3D7}',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'INAMOV',
  showTitle: 'Arquitecbros SL quiere presupuestar tu matriz',
  eventTitle: 'ARQUITECBROS SL',
  description:
      'Dos hermanos con cascos demasiado limpios prometen construir una muralla en la matriz de tu proximo combate. Tambien mencionan, muy tarde, que hay un tercer hermano esperando si prefieres discutir.',
  outcomeText: 'Acepta la obra o reta al tercer hermano.',
  flavorTexts: [
    'Uno habla de estabilidad. El otro de hormigon emocional.',
    'Los dos senalan el contrato a la vez. En la letra pequena se oye respirar a alguien mas.',
  ],
);

final barreraLibreNode = EventPathNode(
  id: PathEventId.barreraLibre,
  nodeId: 'event_barrera_libre',
  label: 'Barrera Libre',
  tooltip:
      'Refuerza un punto del Patron para ganar Barrera al colocar Murallas adyacentes',
  iconEmoji: '\u{1F6E1}',
  rarity: RarityTier.green,
  accent: RarityTier.green.accent,
  badgeLabel: 'INAMOV',
  showTitle: 'Has encontrado una protesta vecinal',
  eventTitle: 'BARRERA LIBRE',
  description:
      'Acepta una placa improvisada para reforzar un punto aleatorio del Patron. Las Murallas colocadas junto a ese punto te dan +1 Barrera.',
  outcomeText: 'Acepta el punto reforzado.',
  flavorTexts: [
    'La calle por la que pasas esta llena de personas, protestando en contra de desahucios y problemas de vivienda',
    'Un hombre maltrecho entre la multitud se acerca a ti: <Toma, te protegera de esas malditas corporaciones>',
  ],
);

final capillaStShieladurnNode = EventPathNode(
  id: PathEventId.capillaStShieladurn,
  nodeId: 'event_capilla_st_shieladurn',
  label: 'Capilla a St. Shieladurn',
  tooltip: 'Ofrece un objeto para ganar Barrera permanente',
  iconEmoji: '\u{1F6E1}',
  rarity: RarityTier.green,
  accent: RarityTier.green.accent,
  badgeLabel: 'INAMOV',
  showTitle: 'Has encontrado la Capilla a St. Shieladurn',
  eventTitle: 'CAPILLA A ST. SHIELADURN',
  description:
      'Una capilla hecha de placas antiguas acepta una pieza de tu inventario. A cambio promete blindaje permanente, sin explicar que algunas ofrendas pesan mas que otras.',
  outcomeText: 'Entrega un objeto como ofrenda.',
  flavorTexts: [
    'No hay sacerdote. Solo un escudo clavado en el altar y una ranura para donaciones.',
    'La capilla vibra con un silencio metalico cuando acercas tus cosas.',
  ],
);

final contratontosNode = EventPathNode(
  id: PathEventId.contratontos,
  nodeId: 'event_contratontos',
  label: 'Contratontos',
  tooltip: 'Entrenamientos Imparables con costes brutales',
  iconEmoji: '\u{1F4AA}',
  rarity: RarityTier.green,
  accent: RarityTier.green.accent,
  badgeLabel: 'IMPAR',
  showTitle: 'Contratontos ofrece entrenamiento especial',
  eventTitle: 'CONTRATONTOS',
  description:
      'El entrenador personal de un famoso luchador de holo-arena te vende una sesion especial. Todo el programa parece disenado por alguien que confunde dolor con metodologia.',
  outcomeText: 'Elige una rutina.',
  flavorTexts: [
    'El entrenador aplaude demasiado fuerte, incluso cuando nadie ha hecho nada.',
    'En la pizarra solo hay tres palabras: ARDE, APRENDE, REPITE.',
  ],
);

final hornoJuramentosNode = EventPathNode(
  id: PathEventId.hornoJuramentos,
  nodeId: 'event_horno_juramentos',
  label: 'Horno de Juramentos',
  tooltip: 'Mejora un objeto a cambio de Quemadura y HP actual',
  iconEmoji: '\u{1F525}',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'IMPAR',
  showTitle: 'Has encontrado el Horno de Juramentos',
  eventTitle: 'HORNO DE JURAMENTOS',
  description:
      'El horno no mejora piezas sueltas. Exige que el portador entre con ellas. La salida deja mejor equipo, 3 Quemadura y una mordida de vida actual que nunca remata.',
  outcomeText: 'Selecciona un objeto para entrar con el.',
  flavorTexts: [
    'La puerta del horno se abre desde dentro.',
    'El metal canta nombres que no recuerdas haber prometido.',
  ],
);

final auditoriaCreativaNode = EventPathNode(
  id: PathEventId.auditoriaCreativa,
  nodeId: 'event_auditoria_creativa',
  label: 'Auditoria Creativa',
  tooltip: 'Pierde HP maximo por creditos o acepta Deuda por un aumento verde',
  iconEmoji: '\u{1F4CA}',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'MERC',
  showTitle: 'Auditoria Creativa revisa tus activos',
  eventTitle: 'AUDITORIA CREATIVA',
  description:
      'Una auditora sonriente declara que tu futuro biologico esta infravalorado. Puede convertir salud maxima en liquidez inmediata o abrir deuda por un aumento verde.',
  outcomeText: 'Elige una formula contable.',
  flavorTexts: [
    'Su calculadora imprime humo y recibos con tu pulso cardiaco.',
    'Cada columna termina en beneficio. Ninguna parece tuya.',
  ],
);

final mercadoFuturosNode = EventPathNode(
  id: PathEventId.mercadoFuturos,
  nodeId: 'event_mercado_futuros',
  label: 'Mercado de Futuros',
  tooltip: 'Apuesta una cara de moneda por XP y buff de combate',
  iconEmoji: '\u{1FA99}',
  rarity: RarityTier.yellow,
  accent: RarityTier.yellow.accent,
  badgeLabel: 'MERC',
  showTitle: 'El Mercado de Futuros propone una apuesta',
  eventTitle: 'MERCADO DE FUTUROS',
  description:
      'Un broker quiere jugar a suerte pura. Elige una cara, mira la moneda girar, y si aciertas recibes 2 XP y +1 ATK/+1 Barrera en el proximo combate.',
  outcomeText: 'Escoge una cara antes de que caiga.',
  flavorTexts: [
    'El broker no ensena las dos caras de la moneda. Eso forma parte del encanto, dice.',
    'Durante un segundo, el canto refleja rutas que todavia no has comprado.',
  ],
);

final thePurgameNode = EventPathNode(
  id: PathEventId.thePurgame,
  nodeId: 'event_the_purgame',
  label: 'The Purgame',
  tooltip: 'Elige como quieres alterar la Purga durante el resto de la run',
  iconEmoji: '\u{26EA}',
  rarity: RarityTier.purple,
  accent: RarityTier.purple.accent,
  badgeLabel: 'PURGA',
  showTitle: 'The Purgame abre sus capillas',
  eventTitle: 'THE PURGAME',
  description:
      'Dos capillas enfrentadas ofrecen caminos opuestos ante la Purga. Ninguno promete salvacion, solo una forma distinta de llegar al final.',
  outcomeText: 'Elige tu camino ante la Purga.',
  flavorTexts: [
    'Una capilla enorme, decorada con estructuras post-post-post-modernistas, abre sus puertas a aquellos que deseen ayudar a ralentizar, futilmente, la Purga.',
    'En la acera de enfrente, otra capilla, mucho mas pequena, esta repleta de fanaticos y adoradores de la Purga, que la aceptan como una purificacion divina',
  ],
);

final tempografoNode = EventPathNode(
  id: PathEventId.tempografo,
  nodeId: 'event_tempografo',
  label: 'Tempografo',
  tooltip: 'Sesga la rareza de tiendas o eventos durante el resto del dia',
  iconEmoji: '\u{1F570}',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'TIEMPO',
  showTitle: 'El Tempografo despliega sus herramientas',
  eventTitle: 'TEMPOGRAFO',
  description:
      'Elige tiendas o eventos. La opcion elegida tirara rareza como si fuera el dia siguiente, y la otra como si fuera el dia anterior, hasta que termine el dia.',
  outcomeText: 'Elige que parte de la ruta quieres adelantar.',
  flavorTexts: [
    'Un anciano con monoculo te detiene entre dos relojes abiertos. Sus herramientas no parecen medir la hora, sino la paciencia de la ciudad.',
    'Insiste en demostrarlo gratis: con un ajuste minimo, asegura que encontraras lo que buscas con mas facilidad.',
  ],
);

final sWitchCabinNode = EventPathNode(
  id: PathEventId.sWitchCabin,
  nodeId: 'event_s_witch_cabin',
  label: "S. Witch's Cabin",
  tooltip: 'Intercambia el bonus de Patron entre dos objetos propios',
  iconEmoji: '\u{1F3DA}',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'PATRON',
  showTitle: "Has encontrado S. Witch's Cabin",
  eventTitle: "S. WITCH'S CABIN",
  description:
      'Una cabina pequena brilla entre distritos, rodeada de niebla rosa. Dentro, una niña demasiado joven ofrece "cambiar como son las cosas".',
  outcomeText: 'Elige dos objetos para intercambiar sus bonus de Patron.',
  flavorTexts: [
    'La cabina no figura en ningun mapa. La luz bajo la puerta late como si respirara.',
    'La niña sonrie sin parpadear. Dice que cambiar las cosas es facil; lo raro es querer dejarlas igual.',
  ],
);

final hackathonBoothNode = EventPathNode(
  id: PathEventId.hackathonBooth,
  nodeId: 'event_hackathon_booth',
  label: 'Hackathon Booth',
  tooltip: 'Supera un reto de patrones para ganar objetos y aumentos',
  iconEmoji: '\u{1F4BB}',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'RETO',
  showTitle: 'Hackathon Booth abre la cola',
  eventTitle: 'HACKATHON BOOTH',
  description:
      'Un grupo de cyber-nerds presume de recompensas increibles para quien aguante su prueba de patrones.',
  outcomeText:
      'Acepta el reto y dibuja seis formas antes de que acabe el tiempo.',
  flavorTexts: [
    'El puesto esta lleno de pantallas, refrescos tibios y gente explicando reglas a la vez.',
    'Prometen premios increibles si sobrevives a su trial. La palabra "trial" aparece en demasiados colores.',
  ],
);

final tintoreriaFantasmaNode = EventPathNode(
  id: PathEventId.tintoreriaFantasma,
  nodeId: 'event_tintoreria_fantasma',
  label: 'Tintoreria Fantasma',
  tooltip: 'Toma un objeto prestado de rareza adelantada durante dos combates',
  iconEmoji: '\u{1F9FA}',
  rarity: RarityTier.purple,
  accent: RarityTier.purple.accent,
  badgeLabel: 'FANTASMA',
  showTitle: 'Has entrado en la Tintoreria Fantasma',
  eventTitle: 'TINTORERIA FANTASMA',
  description:
      'Elige un objeto de rareza adelantada. Lo llevaras durante dos combates; despues tendras que devolverlo al tecno-eter o pagar para fijarlo en la realidad.',
  outcomeText: 'Elige una prenda prestada.',
  flavorTexts: [
    'Sin darte cuenta has entrado en una tintoreria de las de antano. Una bruma te rodea y, aunque no ves bien su cara, un ser te atiende desde la barra.',
    '<Oh, si, llevate algo prestado. Su verdadero dueno no volvera de todos modos...>',
  ],
  flavorEmoji: '\u{1F9FA}',
);

/// Tienda morada nocturna centrada en armas mas agresivas.
final afterHoursArsenalNode = ShopPathNode(
  nodeId: 'shop_after_hours_arsenal',
  label: 'Arsenal After Hours',
  tooltip: 'El mercado nocturno mueve armas mas agresivas',
  iconEmoji: '\u{1F52A}',
  rarity: RarityTier.purple,
  accent: _afterHoursArsenalAccent,
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
  accent: _velvetArmoryAccent,
  badgeLabel: 'ACERO',
  showTitle: 'Velvet Armory',
  shopTitle: 'VELVET ARMORY',
  shopSubtitle: 'Blindaje elegante para quien espera volver con vida.',
  stockCriterion: barrierShopCriterion,
  possibleArchetypes: const [
    ArchetypeId.inamovible,
  ],
);

/// Tienda morada nocturna de alquimia agresiva sin superar el stock azul.
final chemicalExchangeNode = ShopPathNode(
  nodeId: 'shop_chemical_exchange',
  label: 'Mercado Quimico',
  tooltip: 'Quemadura e Intoxicacion de alta gama, sin pasar de azul',
  iconEmoji: '\u{1F9EA}',
  rarity: RarityTier.purple,
  accent: _chemicalExchangeAccent,
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
  accent: _debuffBrokerAccent,
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
  accent: _buffParlorAccent,
  badgeLabel: 'BUFF',
  showTitle: 'Salon de Buffs',
  shopTitle: 'SALON DE BUFFS',
  shopSubtitle:
      'Un escaparate pequeño pero muy especializado en mejoras corporales.',
  stockCriterion: buffShopCriterion,
);

/// Tienda azul Inamovible centrada en Resonancia.
final resonanceBankNode = ShopPathNode(
  nodeId: 'shop_resonance_bank',
  label: 'Banco de Resonancia',
  tooltip: 'Piezas de Resonancia reservadas para Inamovible',
  iconEmoji: '\u{1F3E6}',
  rarity: RarityTier.blue,
  accent: _resonanceBankAccent,
  badgeLabel: 'RESON',
  showTitle: 'Banco de Resonancia',
  shopTitle: 'BANCO DE RESONANCIA',
  shopSubtitle: 'Cada pieza vibra con algo que todavia no has equipado.',
  stockCriterion: resonanceShopCriterion,
  possibleArchetypes: const [
    ArchetypeId.inamovible,
  ],
);

/// Tienda azul Imparable centrada en Desafio.
final duelowPricesNode = ShopPathNode(
  nodeId: 'shop_duelow_prices',
  label: 'Duelow Prices',
  tooltip: 'Piezas de Desafio reservadas para Imparable',
  iconEmoji: '\u2694',
  rarity: RarityTier.blue,
  accent: _duelowPricesAccent,
  badgeLabel: 'DUELO',
  showTitle: 'Duelow Prices',
  shopTitle: 'DUELOW PRICES',
  shopSubtitle: 'Cuanto peor pinta la pelea, mas alto sube el descuento.',
  stockCriterion: challengeShopCriterion,
  possibleArchetypes: const [
    ArchetypeId.imparable,
  ],
);

/// Tienda azul Veloz centrada en Contagio.
final contagionCompanyNode = ShopPathNode(
  nodeId: 'shop_contagion_company',
  label: 'The Contagion Company',
  tooltip: 'Piezas de Contagio reservadas para Veloz',
  iconEmoji: '\u{1F9AB}',
  rarity: RarityTier.blue,
  accent: _contagionCompanyAccent,
  badgeLabel: 'CONTAG',
  showTitle: 'The Contagion Company',
  shopTitle: 'THE CONTAGION COMPANY',
  shopSubtitle:
      'Nada se queda en un solo objetivo si pagas al intermediario correcto.',
  stockCriterion: contagionShopCriterion,
  possibleArchetypes: const [
    ArchetypeId.veloz,
  ],
);

/// Tienda azul hibrida de ataque y barrera.
final tacticsAndTreasuresNode = ShopPathNode(
  nodeId: 'shop_tactics_and_treasures',
  label: 'Tactics and Treasures',
  tooltip: 'Objetos tacticos que combinan ataque y barrera',
  iconEmoji: '\u{1F5FA}',
  rarity: RarityTier.blue,
  accent: _velvetArmoryAccent,
  badgeLabel: 'TACTIC',
  showTitle: 'Tactics and Treasures',
  shopTitle: 'TACTICS AND TREASURES',
  shopSubtitle: 'Golpear sin caer: una filosofia cara, pero popular.',
  stockCriterion: tacticsShopCriterion,
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
      'Las luces de neón ocultan a un cirujano que cambia un aumento por otro de tier superior.',
  outcomeText: 'Elige un aumento para someterlo a una mutacion controlada.',
  flavorTexts: [
    'El neón parpadea sobre acero quirúrgico. No hay preguntas, solo consentimiento implícito.',
    'El especialista te ofrece una mutacion más agresiva de lo normal. Si aceptas, no hay marcha atrás.',
  ],
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
      'Un recaudador y un bruto local interceptan tu ruta. O saldas la cuota pendiente o te cobran en carne y crédito.',
  outcomeText:
      'La cantidad exacta se resuelve al entrar según el saldo pendiente de tu Deuda.',
  flavorTexts: [
    'Te cortan el paso antes de cruzar la siguiente esquina. Dos sombras y una tablet con tu historial financiero.',
    'El recaudador repite la cifra sin alzar la voz: o pagas ahora, o el pago se te descontará ...en vida.',
  ],
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
  firstAidStandNode,
  impActsNode,
  remiendosAndDontsNode,
  gangananciasNode,
  greenItemVendorNode,
  cambientGoldSellerNode,
  routineMarketNode,
  emberFoundryNode,
  toxinLabNode,
]);

/// Pool completo de arquetipos que puede ofrecer la primera hora.
final List<ArchetypePathNode> openingArchetypeNodes = List.unmodifiable([
  velozArchetypeNode,
  inamovibleArchetypeNode,
  imparableArchetypeNode,
  mercanteArchetypeNode,
]);

/// Eventos candidatos para el tramo diurno.
final List<EventPathNode> dayEventNodes = List.unmodifiable([
  strandedTrashNode,
  lostCacheNode,
  shadyTechnosurgeonNode,
  clinicaReflejosNode,
  viktorOperationsNode,
  arquitecbrosSlNode,
  barreraLibreNode,
  capillaStShieladurnNode,
  contratontosNode,
  hornoJuramentosNode,
  auditoriaCreativaNode,
  mercadoFuturosNode,
  thePurgameNode,
  blackTechnoMarketNode,
  sobreKarNode,
  pasadizoSecretoNode,
  suBastaYaNode,
  pitonisaQuitapenasNode,
  debtCollectionNode,
  tempografoNode,
  sWitchCabinNode,
  hackathonBoothNode,
  tintoreriaFantasmaNode,
]);

/// Tiendas posibles durante el tramo nocturno.
final List<ShopPathNode> nightShopNodes = List.unmodifiable([
  afterHoursArsenalNode,
  velvetArmoryNode,
  resonanceBankNode,
  duelowPricesNode,
  contagionCompanyNode,
  tacticsAndTreasuresNode,
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
  clinicaReflejosNode,
  viktorOperationsNode,
  arquitecbrosSlNode,
  barreraLibreNode,
  capillaStShieladurnNode,
  contratontosNode,
  hornoJuramentosNode,
  auditoriaCreativaNode,
  mercadoFuturosNode,
  thePurgameNode,
  blackTechnoMarketNode,
  shadyTechnosurgeonNode,
  sobreKarNode,
  pasadizoSecretoNode,
  suBastaYaNode,
  pitonisaQuitapenasNode,
  debtCollectionNode,
  tempografoNode,
  sWitchCabinNode,
  hackathonBoothNode,
  tintoreriaFantasmaNode,
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
