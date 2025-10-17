import 'item.dart';

class Weapon extends Item {
  final int attackBonus;
  const Weapon({required super.id, required super.name, required this.attackBonus});
}
