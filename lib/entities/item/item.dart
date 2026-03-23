import '_imports.dart';

class Item {
  final String id;
  final String name;
  final String description;
  final String iconEmoji;
  final Map<BattlerStat, int> statModifiers;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    this.iconEmoji = '\u{1F9F0}',
    this.statModifiers = const {},
  });

  int modifier(BattlerStat stat) {
    return statModifiers[stat] ?? 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
