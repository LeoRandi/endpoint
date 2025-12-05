import "_imports.dart";

class BattlerClassSkill {
  final String name;
  final String description;
  final List<int> xpCosts;

  BattlerClassSkill({
    required this.name,
    required this.description,
    required this.xpCosts,
  });

  @override
  String toString() => name;
}