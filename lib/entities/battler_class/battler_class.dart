import "_imports.dart";

class BattlerClass {
  final String name;
  final Map<BattlerStatsType, int> statModifiers = {};
  final String description;
  final String iconPath;

  BattlerClass({
    required this.name,
    required this.description,
    required this.iconPath,
  });

  @override
  String toString() => name;
}

extension BattlerClassMap on Map<BattlerClass, int> {
  int get totalExp {
    return values.fold(0, (sum, exp) => sum + exp);
  }
}