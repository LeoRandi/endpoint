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
  final Color accent;
  final String badgeLabel;

  const PathNode.base({
    required this.type,
    required this.label,
    required this.tooltip,
    required this.iconEmoji,
    required this.accent,
    required this.badgeLabel,
  });

  const PathNode.shop({
    String label = 'Tienda',
    String tooltip = 'Tienda de armas',
    String iconEmoji = '\u{2694}',
    Color accent = const Color(0xFFDBB95A),
    String badgeLabel = 'TIENDA',
  }) : this.base(
          type: PathNodeType.shop,
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          accent: accent,
          badgeLabel: badgeLabel,
        );

  const PathNode.weaponShop({
    String label = 'Tienda',
    String tooltip = 'Tienda de armas',
    String iconEmoji = '\u{2694}',
    Color accent = const Color(0xFFDBB95A),
    String badgeLabel = 'TIENDA',
  }) : this.shop(
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
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
          accent: const Color(0xFF5AF78E),
          badgeLabel: 'DESCANSO',
        );
}
