import '_imports.dart';

enum BattlerEquipmentType {
  weapon,
  armor,
  accessory,
  consumable,
}

class BattlerEquipment {
  final String name;
  final BattlerEquipmentType type;
  final Map<BattlerStatsType, int> bonus;
  final String description;

  BattlerEquipment({
    required this.name,
    required this.type,
    required this.bonus,
    required this.description,
  });
}