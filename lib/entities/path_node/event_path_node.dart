import '_imports.dart';

class EventPathNode extends PathNode {
  final String showTitle;
  final String eventTitle;
  final String description;
  final String outcomeText;

  const EventPathNode({
    required String label,
    required String tooltip,
    required String iconEmoji,
    required RarityTier rarity,
    required Color accent,
    required String badgeLabel,
    required this.showTitle,
    required this.eventTitle,
    required this.description,
    required this.outcomeText,
  }) : super.base(
          type: PathNodeType.event,
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: rarity,
          accent: accent,
          badgeLabel: badgeLabel,
        );
}
