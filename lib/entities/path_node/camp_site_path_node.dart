import '_imports.dart';

class CampSitePathNode extends PathNode {
  final String showTitle;
  final String sceneTitle;
  final String description;
  final double recoveryFactor;
  final bool removeRandomDebuff;

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
    this.recoveryFactor = 1,
    this.removeRandomDebuff = false,
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
