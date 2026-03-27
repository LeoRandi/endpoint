import '../_imports.dart';

/// Resume los tipos de escena que puede ofrecer un nodo de ruta.
enum PathNodeType {
  archetype,
  encounter,
  shop,
  campSite,
  event,
}

/// Modelo base de un nodo visible en la seleccion de ruta.
class PathNode {
  final PathNodeType type;
  final String label;
  final String tooltip;
  final String iconEmoji;
  final RarityTier rarity;
  final Color accent;
  final String badgeLabel;
  final bool hasSignatureBorder;

  /// Devuelve el peso de aparicion del nodo a partir de su rareza.
  double get rollWeight => rarity.rollWeight;

  /// Construye la forma mas generica de un nodo sin imponer un subtipo concreto.
  const PathNode.base({
    required this.type,
    required this.label,
    required this.tooltip,
    required this.iconEmoji,
    required this.rarity,
    required this.accent,
    required this.badgeLabel,
    this.hasSignatureBorder = false,
  });

  /// Construye un nodo simple de tienda reutilizable en tests y casos ligeros.
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
          hasSignatureBorder: false,
        );

  /// Construye un nodo simple de descanso reutilizable en tests y previews.
  const PathNode.campSite({
    String label = 'Zona de Descanso',
    String tooltip = 'Recupera toda tu vida',
    String iconEmoji = '\u{1F6CF}',
  }) : this.base(
          type: PathNodeType.campSite,
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: RarityTier.green,
          accent: const Color(0xFF5AF78E),
          badgeLabel: 'DESCANSO',
          hasSignatureBorder: false,
        );
}
