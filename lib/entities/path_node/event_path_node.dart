import '../_imports.dart';

/// Identifica cada evento para que la logica pueda resolverlo sin depender del texto visible.
enum PathEventId {
  shadyTechnosurgeon,
  afterHoursTechnosurgeon,
  blackTechnoMarket,
  debtCollection,
}

/// Define un nodo de evento con su contenido base y el id que resuelve su efecto.
class EventPathNode extends PathNode {
  final PathEventId id;
  final String showTitle;
  final String eventTitle;
  final String description;
  final String outcomeText;

  /// Crea un evento de ruta con el texto visible y el id que usara la logica.
  const EventPathNode({
    required this.id,
    required String nodeId,
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
          nodeId: nodeId,
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: rarity,
          accent: accent,
          badgeLabel: badgeLabel,
        );
}
