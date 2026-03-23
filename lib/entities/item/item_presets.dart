import '_imports.dart';

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

const itemPresets = <Item>[
  ironSwordItem,
  guardShieldItem,
];
