import 'item.dart';

class Armor extends Item {
  final int defenseBonus;
  const Armor({required super.id, required super.name, required this.defenseBonus});
}
