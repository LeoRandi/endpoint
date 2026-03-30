import '../_imports.dart';

/// Define una escena de descanso con su texto y sus reglas de recuperacion.
class CampSitePathNode extends PathNode {
  final String showTitle;
  final String sceneTitle;
  final String description;
  final double recoveryFactor;
  final bool removeRandomDebuff;

  /// Crea una escena de descanso con el texto y los efectos que usara el servicio.
  const CampSitePathNode({
    required String nodeId,
    required String label,
    required String tooltip,
    required String iconEmoji,
    required RarityTier rarity,
    required Color accent,
    String badgeLabel = 'DESCANSO',
    required this.showTitle,
    required this.sceneTitle,
    required this.description,
    this.recoveryFactor = 1,
    this.removeRandomDebuff = false,
  }) : super.base(
          type: PathNodeType.campSite,
          nodeId: nodeId,
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: rarity,
          accent: accent,
          badgeLabel: badgeLabel,
        );
}
