import '../_imports.dart';
import '../../services/run_randomizer.dart';

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

/// Arquetipo agil orientado a ataque ligero y economia temprana.
final velozArchetypeNode = ArchetypePathNode(
  archetypeId: ArchetypeId.veloz,
  nodeId: 'archetype_veloz',
  label: 'Veloz',
  tooltip:
      '1 item Veloz verde + 1 item general gris. Perfil agil de doble golpe que envenena con cada impacto. Empieza con 8C y 4 income.',
  iconEmoji: cyberWhipsItem.iconEmoji,
  playerIconEmoji: cyberWhipsItem.iconEmoji,
  accent: const Color(0xFF59B7FF),
  rarity: RarityTier.blue,
  baseStatModifiers: const {
    BattlerStat.attack: 1,
  },
  moneyModifier: 8,
  incomeModifier: 4,
  startingItems: const [],
  startingAbilities: const [
    criticalScannerAbility,
  ],
);

/// Arquetipo defensivo centrado en vida, barrera y estabilidad.
final inamovibleArchetypeNode = ArchetypePathNode(
  archetypeId: ArchetypeId.inamovible,
  nodeId: 'archetype_inamovible',
  label: 'Inamovible',
  tooltip:
      '1 item Inamovible verde + 1 item general gris. Perfil resistente con regeneracion pasiva, mas barrera y Reinicio en seco. Empieza con 12C y 3 income.',
  iconEmoji: shieldItem.iconEmoji,
  playerIconEmoji: shieldItem.iconEmoji,
  accent: const Color(0xFF5AF78E),
  rarity: RarityTier.green,
  baseStatModifiers: const {
    BattlerStat.health: 4,
    BattlerStat.barrier: 1,
  },
  moneyModifier: 12,
  incomeModifier: 3,
  startingItems: const [],
  startingAbilities: const [
    hardResetAbility,
  ],
);

/// Arquetipo ofensivo que arranca con mas presion de daño.
final imparableArchetypeNode = ArchetypePathNode(
  archetypeId: ArchetypeId.imparable,
  nodeId: 'archetype_imparable',
  label: 'Imparable',
  tooltip:
      '1 item Imparable verde + 1 item general gris. Perfil ofensivo con mas pegada base y Sobrecarga venosa de salida. Empieza con 8C y 3 income.',
  iconEmoji: ironSwordItem.iconEmoji,
  playerIconEmoji: ironSwordItem.iconEmoji,
  accent: const Color(0xFFF3D35C),
  rarity: RarityTier.yellow,
  baseStatModifiers: const {
    BattlerStat.attack: 2,
  },
  moneyModifier: 8,
  incomeModifier: 3,
  startingItems: const [],
  startingAbilities: const [
    venousOverloadAbility,
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
  accent: _scrapShopAccent,
  badgeLabel: 'ARMAS',
  showTitle: 'Arsenal de Chatarra',
  shopTitle: 'ARSENAL DE CHATARRA',
  shopSubtitle:
      'Herramientas rapidas y mercancia de entrada para la primera hora.',
  stockCriterion: grayShopCriterion,
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
      'Un cirujano clandestino ofrece reciclar una habilidad en un protocolo de tier superior.',
  outcomeText: 'Elige una habilidad para someterla a una mutacion controlada.',
  flavorTexts: [
    'Te adentras en un callejón oscuro, esperando que te sirva de atajo. En su lugar, bajo un cartel de neón parpadeante, encuentras a un cirujano que ofrece "servicios", por un precio claro.',
    'El cirujano abre su maletín, despliega herramientas extravagantes sobre una mesa sin esterilizar, y pide que apoyes el brazo.',
  ],
);

/// Mercado clandestino de habilidades con precio segun tier ofertado.
final blackTechnoMarketNode = EventPathNode(
  id: PathEventId.blackTechnoMarket,
  nodeId: 'event_black_techno_market',
  label: 'Black techno-market',
  tooltip: 'Tres habilidades pirateadas se venden por tier',
  iconEmoji: '\u{1F578}',
  rarity: RarityTier.purple,
  accent: RarityTier.purple.accent,
  badgeLabel: 'MERCADO',
  showTitle: 'Black techno-market',
  eventTitle: 'BLACK TECHNO-MARKET',
  description: 'Tres orbes de habilidad aleatorios orbitan sobre la mesa.',
  outcomeText: 'Elige una habilidad y paga su coste para integrarla.',
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
  tooltip: 'Subasta objetos, recicla stats o intercambia habilidades',
  iconEmoji: '\u{1F4E2}',
  rarity: RarityTier.blue,
  accent: RarityTier.blue.accent,
  badgeLabel: 'SUBASTA',
  showTitle: 'Has encontrado una subasta de chatarra',
  eventTitle: 'SU-BASTA-YA',
  description:
      'Un operador ha puesto precio a todo lo que llevas encima. Puedes subastar un objeto, reciclarlo por stats o cambiar una habilidad.',
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
      'Las luces de neón ocultan a un cirujano que cambia una habilidad por otra de tier superior.',
  outcomeText: 'Elige una habilidad para someterla a una mutacion controlada.',
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
  greenItemVendorNode,
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
  shadyTechnosurgeonNode,
  blackTechnoMarketNode,
  sobreKarNode,
  pasadizoSecretoNode,
  suBastaYaNode,
  pitonisaQuitapenasNode,
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
  blackTechnoMarketNode,
  shadyTechnosurgeonNode,
  sobreKarNode,
  pasadizoSecretoNode,
  suBastaYaNode,
  pitonisaQuitapenasNode,
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
