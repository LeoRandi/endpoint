enum BattlerStatsType {
  defense,
  magicDefense,
  dodge,
  magicDodge,
  health,
  mana,
  strength,
  magic,
  sword,
  spear,
  axe,
  hammer,
  dagger,
  unarmed,
  shield,
  bow,
  speed,
  luck;

  String getStatIconPath(BattlerStatsType statType) {
    switch (statType) {
      case BattlerStatsType.defense:
        return "assets/images/icons/icon_defense.png";
      case BattlerStatsType.magicDefense:
        return "assets/images/icons/icon_magic_defense.png";
      case BattlerStatsType.dodge:
        return "assets/images/icons/icon_dodge.png";
      case BattlerStatsType.magicDodge:
        return "assets/images/icons/icon_magic_dodge.png";
      case BattlerStatsType.health:
        return "assets/images/icons/icon_health.png";
      case BattlerStatsType.mana:
        return "assets/images/icons/icon_mana.png";
      case BattlerStatsType.strength:
        return "assets/images/icons/icon_strength.png";
      case BattlerStatsType.magic:
        return "assets/images/icons/icon_magic.png";
      case BattlerStatsType.sword:
        return "assets/images/icons/icon_sword.png";
      case BattlerStatsType.spear:
        return "assets/images/icons/icon_spear.png";
      case BattlerStatsType.axe:
        return "assets/images/icons/icon_axe.png";
      case BattlerStatsType.hammer:
        return "assets/images/icons/icon_hammer.png";
      case BattlerStatsType.dagger:
        return "assets/images/icons/icon_dagger.png";
      case BattlerStatsType.unarmed:
        return "assets/images/icons/icon_unarmed.png";
      case BattlerStatsType.shield:
        return "assets/images/icons/icon_shield.png";
      case BattlerStatsType.bow:
        return "assets/images/icons/icon_bow.png";
      case BattlerStatsType.speed:
        return "assets/images/icons/icon_speed.png";
      case BattlerStatsType.luck:
        return "assets/images/icons/icon_luck.png";
      default:
        return "";
    }
  }
}

class BattlerStats {
  Map<BattlerStatsType, int> rawStats = {};
  Map<BattlerStatsType, int> get calculatedStats {
    // In the future, we can add equipment and buff calculations here
    return rawStats;
  }

  BattlerStats({
    required this.rawStats,
  });
}

extension BattlerStatsMap on Map<BattlerStatsType, int>{
  static Map<BattlerStatsType, int> baseStats(){
    return <BattlerStatsType, int>{
        BattlerStatsType.health: 0,
        BattlerStatsType.mana: 0,
        BattlerStatsType.strength: 0,
        BattlerStatsType.magic: 0,
        BattlerStatsType.luck: 0,
        BattlerStatsType.speed: 0,
        BattlerStatsType.defense: 0,
        BattlerStatsType.magicDefense: 0,
        BattlerStatsType.dodge: 0,
        BattlerStatsType.magicDodge: 0,
        BattlerStatsType.axe: 0,
        BattlerStatsType.bow: 0,
        BattlerStatsType.sword: 0,
        BattlerStatsType.dagger: 0,
        BattlerStatsType.hammer: 0,
        BattlerStatsType.unarmed: 0,
        BattlerStatsType.spear: 0,
        BattlerStatsType.shield: 0
      };
  }

  static Map<BattlerStatsType, int> baseHuman(){
    return <BattlerStatsType, int>{
        BattlerStatsType.health: 30,
        BattlerStatsType.mana: 20,
        BattlerStatsType.strength: 1,
        BattlerStatsType.magic: 1,
        BattlerStatsType.luck: 0,
        BattlerStatsType.speed: 3,
        BattlerStatsType.defense: 0,
        BattlerStatsType.magicDefense: 0,
        BattlerStatsType.dodge: 0,
        BattlerStatsType.magicDodge: 0,
        BattlerStatsType.axe: 0,
        BattlerStatsType.bow: 0,
        BattlerStatsType.sword: 0,
        BattlerStatsType.dagger: 0,
        BattlerStatsType.hammer: 0,
        BattlerStatsType.unarmed: 0,
        BattlerStatsType.spear: 0,
        BattlerStatsType.shield: 0
      };
  }

  static Map<BattlerStatsType, int> baseGoblin(){
    return <BattlerStatsType, int>{
        BattlerStatsType.health: 20,
        BattlerStatsType.mana: 10,
        BattlerStatsType.strength: 0,
        BattlerStatsType.magic: 0,
        BattlerStatsType.luck: 0,
        BattlerStatsType.speed: 4,
        BattlerStatsType.defense: 0,
        BattlerStatsType.magicDefense: 0,
        BattlerStatsType.dodge: 0,
        BattlerStatsType.magicDodge: 0,
        BattlerStatsType.axe: 0,
        BattlerStatsType.bow: 0,
        BattlerStatsType.sword: 0,
        BattlerStatsType.dagger: 1,
        BattlerStatsType.hammer: 0,
        BattlerStatsType.unarmed: 1,
        BattlerStatsType.spear: 0,
        BattlerStatsType.shield: 1
      };
  }
}