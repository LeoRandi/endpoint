import '_imports.dart';

enum BattlerEquipmentType {
  weapon,
  armor,
  accessory,
  consumable,
}

enum BattlerEquipmentLayout{
  humanlike(1),
  beastlike(2),
  ghostlike(3);
  
  final int id;
  
  const BattlerEquipmentLayout(this.id);
  
  List<BattlerEquipmentType> get layout {
    switch(id) {
      case 1:   // humanlike
        return [
          BattlerEquipmentType.weapon,  //mainhand
          BattlerEquipmentType.weapon,  //offhand
          BattlerEquipmentType.armor,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.consumable,
          BattlerEquipmentType.consumable,
        ];
      case 2:   // beastlike
        return [
          BattlerEquipmentType.weapon,
          BattlerEquipmentType.armor,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.consumable,
        ];
      case 3:   // ghostlike
        return [
          BattlerEquipmentType.weapon,  //mainhand
          BattlerEquipmentType.weapon,  //offhand
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.accessory,
          BattlerEquipmentType.consumable,
          BattlerEquipmentType.consumable,
        ];
      default:
        return [];
    }
  } 
}

class BattlerEquipment {
  final String name;
  final BattlerEquipmentType type;
  final Map<BattlerStatsType, int> bonus;
  final String description;
  bool isDisabled = false;  

  BattlerEquipment({
    required this.name,
    required this.type,
    required this.bonus,
    required this.description,
  });

  void disable(){
    isDisabled = true;
  }

  void repair(){
    isDisabled = false;
  }
}