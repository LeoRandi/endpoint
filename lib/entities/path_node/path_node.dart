import '_imports.dart';

/// Resume los tipos de escena que puede ofrecer un nodo de ruta.
///
/// El tipo decide que pagina abre el coordinador de ruta y que metodo de
/// `RunSessionController` debe cerrar la resolucion del nodo.
enum PathNodeType {
  archetype,
  encounter,
  shop,
  campSite,
  event,
}

/// Modelo base de un nodo visible en la seleccion de ruta.
///
/// Los subtipos agregan datos especificos de combate, tienda, evento o
/// arquetipo, pero la pagina de ruta puede renderizar todos los nodos con esta
/// superficie comun.
class PathNode {
  final PathNodeType type;
  final String nodeId;
  final String label;
  final String tooltip;
  final String iconEmoji;
  final RarityTier rarity;
  final Color accent;
  final String badgeLabel;
  final bool hasSignatureBorder;

  /// Devuelve el peso de aparicion del nodo a partir de su rareza.
  ///
  /// `PathNodeService` usa este valor para mezclar nodos de distinta rareza sin
  /// duplicar la tabla de pesos fuera de [RarityTier].
  double get rollWeight => rarity.rollWeight;

  /// Construye la forma mas generica de un nodo sin imponer un subtipo concreto.
  ///
  /// Los constructores de subclases deben llamar a este punto para mantener ids,
  /// rareza, color y copy visibles consistentes en toda la ruta.
  const PathNode.base({
    required this.type,
    required this.nodeId,
    required this.label,
    required this.tooltip,
    required this.iconEmoji,
    required this.rarity,
    required this.accent,
    required this.badgeLabel,
    this.hasSignatureBorder = false,
  });

  /// Construye un nodo simple de tienda reutilizable en casos ligeros.
  ///
  /// El coordinador lo resuelve como tienda generica cuando no hay un
  /// [ShopPathNode] completo, lo que permite previews o pools fallback sin crear
  /// stock especializado.
  const PathNode.shop({
    String nodeId = 'shop_preview',
    String label = 'Tienda',
    String tooltip = 'Tienda de armas',
    String iconEmoji = '\u{2694}',
    RarityTier rarity = RarityTier.gray,
    Color accent = const Color(0xFF9EA7B3),
    String badgeLabel = 'TIENDA',
  }) : this.base(
          type: PathNodeType.shop,
          nodeId: nodeId,
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: rarity,
          accent: accent,
          badgeLabel: badgeLabel,
          hasSignatureBorder: false,
        );

  /// Construye un nodo simple de descanso reutilizable en previews.
  ///
  /// Si no se aporta un [CampSitePathNode] completo, el coordinador usa los
  /// valores por defecto de descanso seguro.
  const PathNode.campSite({
    String nodeId = 'camp_site_preview',
    String label = 'Zona de Descanso',
    String tooltip = 'Recupera toda tu vida',
    String iconEmoji = '\u{1F6CF}',
  }) : this.base(
          type: PathNodeType.campSite,
          nodeId: nodeId,
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: RarityTier.green,
          accent: const Color(0xFF5AF78E),
          badgeLabel: 'DESCANSO',
          hasSignatureBorder: false,
        );
}
