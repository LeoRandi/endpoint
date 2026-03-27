import '../_imports.dart';

/// Arma gris sencilla para encuentros y tiendas de bajo nivel.
const woodenStickItem = Item(
  id: ItemId.woodenStick,
  name: 'Palo',
  description: '+1 ATK mientras este equipado.',
  iconEmoji: '\u{1FAB5}',
  slot: ItemSlot.weapon,
  rarity: RarityTier.gray,
  statModifiers: {
    BattlerStat.attack: 1,
  },
);

/// Variante agil del arma basica usada por el arquetipo Veloz.
const cyberWhipsItem = Item(
  id: ItemId.cyberWhips,
  name: 'Cyber Latigos',
  description: '+1 ATK mientras este equipado.',
  iconEmoji: '\u{26D3}',
  slot: ItemSlot.weapon,
  rarity: RarityTier.gray,
  statModifiers: {
    BattlerStat.attack: 1,
  },
);

/// Accesorio defensivo ligero que da un punto de defensa.
const sunglassesItem = Item(
  id: ItemId.sunglasses,
  name: 'Gafas de Sol',
  description: '+1 DEF mientras esten equipadas.',
  iconEmoji: '\u{1F453}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.gray,
  statModifiers: {
    BattlerStat.defense: 1,
  },
);

/// Soporte defensivo verde para builds de aguante.
const shieldItem = Item(
  id: ItemId.shield,
  name: 'Escudo',
  description: '+2 DEF mientras este equipado.',
  iconEmoji: '\u{1F6E1}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.green,
  statModifiers: {
    BattlerStat.defense: 2,
  },
);

/// Accesorio verde que sube vida maxima y defensa a la vez.
const bulwarkAmuletItem = Item(
  id: ItemId.bulwarkAmulet,
  name: 'Amuleto de Bastion',
  description: '+6 HP y +1 DEF mientras este equipado.',
  iconEmoji: '\u{1F9FF}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.green,
  statModifiers: {
    BattlerStat.health: 6,
    BattlerStat.defense: 1,
  },
);

/// Accesorio gris que acelera la primera habilidad manual de cada combate.
const crackedBatteryItem = Item(
  id: ItemId.crackedBattery,
  name: 'Bateria Rajada',
  description: 'Accesorio inestable que exprime la primera habilidad manual.',
  iconEmoji: '\u{1F50B}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.gray,
  value: 1,
  upgradeValue: 1,
  effect: CrackedBatteryItemEffect(),
);

/// Arma gris que castiga a objetivos sin buffs activos.
const impactGlovesItem = Item(
  id: ItemId.impactGloves,
  name: 'Guantes de Impacto',
  description: '+1 ATK y castigo extra contra objetivos sin buffs.',
  iconEmoji: '\u{1F9E4}',
  slot: ItemSlot.weapon,
  rarity: RarityTier.gray,
  value: 2,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  effect: ImpactGlovesItemEffect(),
);

/// Accesorio verde ofensivo que aplica Intoxicacion al atacar.
const toxicCatalystItem = Item(
  id: ItemId.toxicCatalyst,
  name: 'Catalizador Toxico',
  description: 'Accesorio quimico que contamina cada impacto.',
  iconEmoji: '\u2623',
  slot: ItemSlot.accessory,
  rarity: RarityTier.green,
  effect: IntoxicarOnAttackItemEffect(),
);

/// Accesorio verde ofensivo que aplica Quemadura al atacar.
const emberCharmItem = Item(
  id: ItemId.emberCharm,
  name: 'Amuleto de Ascuas',
  description: 'Accesorio ofensivo que prende fuego en cada impacto.',
  iconEmoji: '\u{1F525}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.green,
  effect: QuemaduraOnAttackItemEffect(),
);

/// Accesorio verde defensivo contra Quemadura e Intoxicacion.
const chemicalFilterItem = Item(
  id: ItemId.chemicalFilter,
  name: 'Filtro Quimico',
  description: 'Reduce la Quemadura y la Intoxicacion que recibes.',
  iconEmoji: '\u{1F637}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.green,
  value: 1,
  effect: ChemicalFilterItemEffect(),
);

/// Soporte verde que cambia vida maxima por income adicional.
const billingModuleItem = Item(
  id: ItemId.billingModule,
  name: 'Modulo de Cobro',
  description: 'Convierte soporte vital en ingresos operativos.',
  iconEmoji: '\u{1F4B3}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.green,
  value: 2,
  upgradeValue: 1,
  incomePerValueUnit: 1,
  maxHealthPercentPerValueUnit: -5,
  effect: BillingModuleItemEffect(),
);

/// Arma verde de ataque alto para la progresion temprana.
const ironSwordItem = Item(
  id: ItemId.ironSword,
  name: 'Espada de Hierro',
  description: '+5 ATK mientras este equipada.',
  iconEmoji: '\u2694',
  slot: ItemSlot.weapon,
  rarity: RarityTier.green,
  statModifiers: {
    BattlerStat.attack: 5,
  },
);

/// Soporte verde defensivo para enemigos y tienda.
const guardShieldItem = Item(
  id: ItemId.guardShield,
  name: 'Escudo de Guardia',
  description: '+2 DEF mientras este equipado.',
  iconEmoji: '\u{1F6E1}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.green,
  statModifiers: {
    BattlerStat.defense: 2,
  },
);

/// Soporte azul reactivo que devuelve Quemadura al recibir golpes.
const reactiveCasingItem = Item(
  id: ItemId.reactiveCasing,
  name: 'Coraza Reactiva',
  description: 'Blindaje inestable que devuelve fuego al agresor.',
  iconEmoji: '\u{1F9F1}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.blue,
  effect: QuemaduraOnHitReceivedItemEffect(),
);

/// Blindaje azul de defensa plana alta.
const platedJacketItem = Item(
  id: ItemId.platedJacket,
  name: 'Chaqueta Blindada',
  description: '+4 DEF mientras este equipada.',
  iconEmoji: '\u{1F9E5}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.blue,
  statModifiers: {
    BattlerStat.defense: 4,
  },
);

/// Arma amarilla de dano alto para el tramo final.
const sunsteelBladeItem = Item(
  id: ItemId.sunsteelBlade,
  name: 'Filo Solar',
  description: '+8 ATK mientras este equipado.',
  iconEmoji: '\u{1F5E1}',
  slot: ItemSlot.weapon,
  rarity: RarityTier.yellow,
  statModifiers: {
    BattlerStat.attack: 8,
  },
);

/// Accesorio amarillo centrado en vida maxima.
const dawnCharmItem = Item(
  id: ItemId.dawnCharm,
  name: 'Amuleto del Alba',
  description: '+16 HP mientras este equipado.',
  iconEmoji: '\u2600',
  slot: ItemSlot.accessory,
  rarity: RarityTier.yellow,
  statModifiers: {
    BattlerStat.health: 16,
  },
);

/// Soporte morado defensivo simple y consistente.
const midnightCloakItem = Item(
  id: ItemId.midnightCloak,
  name: 'Capa de Medianoche',
  description: '+5 DEF mientras este equipada.',
  iconEmoji: '\u{1F576}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.purple,
  statModifiers: {
    BattlerStat.defense: 5,
  },
);

/// Soporte morado que potencia Quemaduras y las devuelve al portador cada turno.
const portableOvenItem = Item(
  id: ItemId.portableOven,
  name: 'Horno Portatil',
  description: 'Amplifica tus Quemaduras, pero siempre deja rescoldos.',
  iconEmoji: '\u{1F525}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.purple,
  value: 1,
  effect: PortableOvenItemEffect(),
);

/// Accesorio morado que cura al entrar habilidades en cooldown.
const parasiticCapacitorItem = Item(
  id: ItemId.parasiticCapacitor,
  name: 'Capacitador Parasitario',
  description:
      '+5 HP y drenaje energetico cada vez que una habilidad entra en cooldown.',
  iconEmoji: '\u26A1',
  slot: ItemSlot.accessory,
  rarity: RarityTier.purple,
  value: 5,
  statModifiers: {
    BattlerStat.health: 5,
  },
  effect: ParasiticCapacitorItemEffect(),
);

/// Accesorio morado mixto de ataque y vida maxima.
const voidInjectorItem = Item(
  id: ItemId.voidInjector,
  name: 'Inyector del Vacio',
  description: '+4 ATK y +8 HP mientras este equipado.',
  iconEmoji: '\u{1F489}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.purple,
  statModifiers: {
    BattlerStat.attack: 4,
    BattlerStat.health: 8,
  },
);

/// Soporte amarillo que potencia la primera activacion manual del combate.
const eclipseMantleItem = Item(
  id: ItemId.eclipseMantle,
  name: 'Manto de Eclipse',
  description:
      '+4 DEF y un pulso de potencia en la primera activacion manual del combate.',
  iconEmoji: '\u{1F318}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.yellow,
  value: 3,
  statModifiers: {
    BattlerStat.defense: 4,
  },
  effect: EclipseMantleItemEffect(),
);

/// Accesorio amarillo que evita una muerte por combate y reinicia habilidades.
const operativeBlackBoxItem = Item(
  id: ItemId.operativeBlackBox,
  name: 'Caja Negra del Operativo',
  description:
      'Failsafe de emergencia que rehusa dejar caer la unidad a la primera.',
  iconEmoji: '\u{1F4E6}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.yellow,
  effect: OperativeBlackBoxItemEffect(),
);

/// Pool maestro de objetos ofrecidos por tiendas y recompensas.
const itemPresets = <Item>[
  crackedBatteryItem,
  impactGlovesItem,
  toxicCatalystItem,
  emberCharmItem,
  chemicalFilterItem,
  billingModuleItem,
  ironSwordItem,
  guardShieldItem,
  platedJacketItem,
  reactiveCasingItem,
  portableOvenItem,
  parasiticCapacitorItem,
  sunsteelBladeItem,
  dawnCharmItem,
  eclipseMantleItem,
  operativeBlackBoxItem,
  midnightCloakItem,
  voidInjectorItem,
];
