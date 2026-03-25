import '_imports.dart';

class CampSitePathNode extends PathNode {
  final String showTitle;
  final String sceneTitle;
  final String description;
  final CampSiteService recoveryService;

  const CampSitePathNode({
    required String label,
    required String tooltip,
    required String iconEmoji,
    required RarityTier rarity,
    required Color accent,
    String badgeLabel = 'DESCANSO',
    required this.showTitle,
    required this.sceneTitle,
    required this.description,
    required this.recoveryService,
  }) : super.base(
          type: PathNodeType.campSite,
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: rarity,
          accent: accent,
          badgeLabel: badgeLabel,
        );
}
