import '_imports.dart';

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

const toxicCatalystItem = Item(
  id: ItemId.toxicCatalyst,
  name: 'Catalizador Toxico',
  description: 'Accesorio quimico que contamina cada impacto.',
  iconEmoji: '\u2623',
  slot: ItemSlot.accessory,
  rarity: RarityTier.green,
  effect: IntoxicarOnAttackItemEffect(),
);

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

const reactiveCasingItem = Item(
  id: ItemId.reactiveCasing,
  name: 'Coraza Reactiva',
  description: 'Blindaje inestable que devuelve fuego al agresor.',
  iconEmoji: '\u{1F9F1}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.blue,
  effect: QuemaduraOnHitReceivedItemEffect(),
);

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

const itemPresets = <Item>[
  toxicCatalystItem,
  ironSwordItem,
  guardShieldItem,
  platedJacketItem,
  reactiveCasingItem,
  sunsteelBladeItem,
  dawnCharmItem,
  midnightCloakItem,
  voidInjectorItem,
];
