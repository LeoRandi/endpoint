import '_imports.dart';

const ironSwordItem = Item(
  id: 'iron_sword',
  name: 'Espada de Hierro',
  description: '+5 ATK mientras este equipada.',
  iconEmoji: '\u2694',
  statModifiers: {
    BattlerStat.attack: 5,
  },
);

const guardShieldItem = Item(
  id: 'guard_shield',
  name: 'Escudo de Guardia',
  description: '+2 DEF mientras este equipado.',
  iconEmoji: '\u{1F6E1}',
  statModifiers: {
    BattlerStat.defense: 2,
  },
);

const itemPresets = <Item>[
  ironSwordItem,
  guardShieldItem,
];
