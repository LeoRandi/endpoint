import '_imports.dart';

enum BattlerEquipmentType {
  weapon,
  armor,
  accessory,
  consumable;

  String get slotImage {
    switch (this) {
      case BattlerEquipmentType.weapon:
        return "assets/images/slots/equipment_slot_weapon.png";
      case BattlerEquipmentType.armor:
        return "assets/images/slots/equipment_slot_chest.png";
      case BattlerEquipmentType.accessory:
        return "assets/images/slots/equipment_slot_accessory.png";
      case BattlerEquipmentType.consumable:
        return "assets/images/slots/equipment_slot_base.png";
    }
  }
}

enum BattlerEquipmentLayout {
  humanlike(1),
  beastlike(2),
  ghostlike(3),
  fourArms(4),
  unkown(-1);

  final int id;

  const BattlerEquipmentLayout(this.id);

  List<BattlerEquipmentType> get layout {
    switch (id) {
      case 1: // humanlike
        return [
          BattlerEquipmentType.weapon, //mainhand
          BattlerEquipmentType.weapon, //offhand
          BattlerEquipmentType.armor,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.consumable,
          BattlerEquipmentType.consumable,
          BattlerEquipmentType.consumable,
        ];
      case 2: // beastlike
        return [
          BattlerEquipmentType.weapon,
          BattlerEquipmentType.weapon, //offhand
          BattlerEquipmentType.armor,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.consumable,
        ];
      case 3: // ghostlike
        return [
          BattlerEquipmentType.weapon, //mainhand
          BattlerEquipmentType.weapon, //offhand
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.consumable,
          BattlerEquipmentType.consumable,
          BattlerEquipmentType.consumable,
        ];
      case 4: // 4-arms
        return [
          BattlerEquipmentType.weapon, //mainhand
          BattlerEquipmentType.weapon, //offhand
          BattlerEquipmentType.weapon, //offhand
          BattlerEquipmentType.weapon, //offhand
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.accessory,
        ];
      default:
        return [];
    }
  }

  bool isValidAtSlot(int index, BattlerEquipment equipment) {
    final layout = this.layout;
    if (index < 0 || index >= layout.length) return false;
    return layout[index] == equipment.type;
  }
}

class BattlerEquipment {
  final String name;
  final BattlerEquipmentType type;
  final Map<BattlerStatsType, int> bonus;
  final String description;
  final String imagePath;
  bool isDisabled = false;

  BattlerEquipment({
    required this.name,
    required this.type,
    required this.bonus,
    required this.description,
    this.imagePath = "assets/images/void.png",
  });

  static BattlerEquipment empty() {
    return BattlerEquipment(
      name: "",
      type: BattlerEquipmentType.weapon,
      bonus: {},
      description: "",
      imagePath: "assets/images/void.png",
    );
  }

  void disable() {
    isDisabled = true;
  }

  void repair() {
    isDisabled = false;
  }
}
