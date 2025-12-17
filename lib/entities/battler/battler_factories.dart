import "_imports.dart";

extension BattlerFactories on Battler{
  static Battler hero() {
    final hero = Battler(
      imagePath: 'assets/sprites/base_dude.png',
      name: "Hero",
      side: BattlerSide.ally,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(
        rawStats: BattlerStatsMap.baseHuman(),
      ),
    );

    hero.addEquipment(BattlerEquipment(
        name: "placeholder axe",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.axe: 1},
        description: "A basic axe for testing.",
        imagePath: 'assets/images/icons/icon_axe.png'));

    return hero;
  }

  static Battler heroMage() {
    final hero = Battler(
      imagePath: 'assets/sprites/base_dude.png',
      name: "Hero Mage",
      side: BattlerSide.ally,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(
        rawStats: BattlerStatsMap.baseHuman().copyWith(changes: [
          (BattlerStatsType.magic, 3),
          (BattlerStatsType.magicDefense, 2)
        ]),
      ),
    );

    hero.addEquipment(BattlerEquipment(
        name: "placeholder magic hand",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.magic: 1},
        description: "A basic magic hand for testing.",
        imagePath: 'assets/images/icons/icon_unarmed.png'));
    return hero;
  }

  static Battler heroRogue() {
    final hero = Battler(
      imagePath: 'assets/sprites/base_dude.png',
      name: "Hero Rogue",
      side: BattlerSide.ally,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(
        rawStats: BattlerStatsMap.baseHuman().copyWith(changes: [
          (BattlerStatsType.speed, 4),
          (BattlerStatsType.dodge, 10),
          (BattlerStatsType.dagger, 2)
        ]),
      ),
    );

    hero.addEquipment(BattlerEquipment(
        name: "placeholder dagger",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.dagger: 1},
        description: "A basic dagger for testing.",
        imagePath: 'assets/images/icons/icon_dagger.png'));

    return hero;
  }

  static Battler heroCleric() {
    final hero = Battler(
      imagePath: 'assets/sprites/base_dude.png',
      name: "Hero Cleric",
      side: BattlerSide.ally,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(
        rawStats: BattlerStatsMap.baseHuman().copyWith(changes: [
          (BattlerStatsType.magic, 2),
          (BattlerStatsType.magicDefense, 1),
          (BattlerStatsType.defense, 1)
        ]),
      ),
    );

    hero.addEquipment(BattlerEquipment(
        name: "placeholder hammer",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.hammer: 1},
        description: "A basic hammer for testing.",
        imagePath: 'assets/images/icons/icon_hammer.png'));

    return hero;
  }

  static Battler goblin() {
    final goblin = Battler(
      imagePath: 'assets/sprites/base_green_dude.png',
      name: "Goblin",
      side: BattlerSide.enemy,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(rawStats: BattlerStatsMap.baseGoblin()),
    );

    goblin.addEquipment(BattlerEquipment(
        name: "placeholder dagger",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.dagger: 1},
        description: "A basic dagger for testing.",
        imagePath: 'assets/images/icons/icon_dagger.png'));

    return goblin;
  }

  static Battler goblinTank() {
    final goblin = Battler(
      imagePath: 'assets/sprites/base_green_dude.png',
      name: "Goblin Tank",
      side: BattlerSide.enemy,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(rawStats: BattlerStatsMap.baseGoblin()),
    );

    goblin.addEquipment(BattlerEquipment(
        name: "placeholder dagger",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.dagger: 1},
        description: "A basic dagger for testing.",
        imagePath: 'assets/images/icons/icon_dagger.png'));

    goblin.addEquipment(BattlerEquipment(
        name: "placeholder armor",
        type: BattlerEquipmentType.armor,
        bonus: {BattlerStatsType.defense: 1},
        description: "A basic armor for testing.",
        imagePath: 'assets/images/icons/icon_dodge.png'));

    goblin.addEquipment(BattlerEquipment(
        name: "placeholder shield",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.dodge: 3},
        description: "A basic shield for testing.",
        imagePath: 'assets/images/icons/icon_shield.png'));

    return goblin;
  }

  static Battler goblinArcher() {
    final goblin = Battler(
      imagePath: 'assets/sprites/base_green_dude.png',
      name: "Goblin Archer",
      side: BattlerSide.enemy,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(rawStats: BattlerStatsMap.baseGoblin()),
    );

    goblin.addEquipment(BattlerEquipment(
        name: "placeholder bow",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.bow: 1},
        description: "A basic bow for testing.",
        imagePath: 'assets/images/icons/icon_bow.png'));

    goblin.addEquipment(
        BattlerEquipment(
            name: "placeholder dagger",
            type: BattlerEquipmentType.weapon,
            bonus: {BattlerStatsType.dagger: 1},
            description: "A basic dagger for testing.",
            imagePath: 'assets/images/icons/icon_dagger.png'),
        slot: 7);

    return goblin;
  }

  static Battler trashGoblin() {
    final goblin = Battler(
      imagePath: 'assets/sprites/base_green_dude.png',
      name: "Trash Goblin",
      side: BattlerSide.enemy,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(rawStats: BattlerStatsMap.baseGoblin()),
    );

    goblin.fillEquipment(BattlerEquipment(
        name: "placeholder trash",
        type: BattlerEquipmentType.consumable,
        bonus: {},
        description: "A basic trash for testing.",
        imagePath: 'assets/images/icons/icon_luck.png'));

    return goblin;
  }

  static Battler voidBattler() {
    return Battler(
      imagePath: 'assets/images/void.png',
      name: "",
      side: BattlerSide.unkown,
      equipmentLayout: BattlerEquipmentLayout.unkown,
      stats: BattlerStats(rawStats: BattlerStatsMap.baseStats()),
    );
  }
}