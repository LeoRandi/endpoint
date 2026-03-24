import '_imports.dart';

enum PathNodeType {
  encounter,
  shop,
  campSite,
  event,
}

class PathNode {
  final PathNodeType type;
  final String label;
  final String tooltip;
  final String iconEmoji;
  final RarityTier rarity;
  final Color accent;
  final String badgeLabel;
  double get rollWeight => rarity.rollWeight;

  const PathNode.base({
    required this.type,
    required this.label,
    required this.tooltip,
    required this.iconEmoji,
    required this.rarity,
    required this.accent,
    required this.badgeLabel,
  });

  const PathNode.shop({
    String label = 'Tienda',
    String tooltip = 'Tienda de armas',
    String iconEmoji = '\u{2694}',
    RarityTier rarity = RarityTier.gray,
    Color accent = const Color(0xFF9EA7B3),
    String badgeLabel = 'TIENDA',
  }) : this.base(
          type: PathNodeType.shop,
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: rarity,
          accent: accent,
          badgeLabel: badgeLabel,
        );

  const PathNode.weaponShop({
    String label = 'Tienda',
    String tooltip = 'Tienda de armas',
    String iconEmoji = '\u{2694}',
    RarityTier rarity = RarityTier.gray,
    Color accent = const Color(0xFF9EA7B3),
    String badgeLabel = 'TIENDA',
  }) : this.shop(
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: rarity,
          accent: accent,
          badgeLabel: badgeLabel,
        );

  const PathNode.campSite({
    String label = 'Acampada',
    String tooltip = 'Zona de acampada',
    String iconEmoji = '\u{26FA}',
  }) : this.base(
          type: PathNodeType.campSite,
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: RarityTier.green,
          accent: const Color(0xFF5AF78E),
          badgeLabel: 'DESCANSO',
        );
}
