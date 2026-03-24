import '_imports.dart';

enum CombatNodeTier {
  gray,
  green,
  blue,
  purple,
  yellow;

  RarityTier get rarity {
    switch (this) {
      case CombatNodeTier.gray:
        return RarityTier.gray;
      case CombatNodeTier.green:
        return RarityTier.green;
      case CombatNodeTier.blue:
        return RarityTier.blue;
      case CombatNodeTier.purple:
        return RarityTier.purple;
      case CombatNodeTier.yellow:
        return RarityTier.yellow;
    }
  }

  Color get accent => rarity.accent;
  String get badgeLabel => rarity.label;
  int get factor => rarity.factor;
}

class CombatPathNode extends PathNode {
  final Battler enemy;
  final CombatNodeTier tier;

  CombatPathNode({
    required this.enemy,
    required this.tier,
    required String label,
    String? tooltip,
    String iconEmoji = '\u{1F47E}',
  }) : super.base(
          type: PathNodeType.encounter,
          label: label,
          tooltip: tooltip ?? label,
          iconEmoji: iconEmoji,
          rarity: tier.rarity,
          accent: tier.accent,
          badgeLabel: tier.badgeLabel,
        );

  String get showTitle => label;
}
