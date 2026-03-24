import '_imports.dart';

const woodenStickItem = Item(
  id: ItemId.woodenStick,
  name: 'Palo',
  description: '+1 ATK mientras este equipado.',
  iconEmoji: '\u{1FAB5}',
  slot: ItemSlot.weapon,
  statModifiers: {
    BattlerStat.attack: 1,
  },
);

const ironSwordItem = Item(
  id: ItemId.ironSword,
  name: 'Espada de Hierro',
  description: '+5 ATK mientras este equipada.',
  iconEmoji: '\u2694',
  slot: ItemSlot.weapon,
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
  statModifiers: {
    BattlerStat.defense: 2,
  },
);

const platedJacketItem = Item(
  id: ItemId.platedJacket,
  name: 'Chaqueta Blindada',
  description: '+4 DEF mientras este equipada.',
  iconEmoji: '\u{1F9E5}',
  slot: ItemSlot.offHand,
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
  statModifiers: {
    BattlerStat.attack: 4,
    BattlerStat.health: 8,
  },
);

const itemPresets = <Item>[
  ironSwordItem,
  guardShieldItem,
  platedJacketItem,
  sunsteelBladeItem,
  dawnCharmItem,
  midnightCloakItem,
  voidInjectorItem,
];
