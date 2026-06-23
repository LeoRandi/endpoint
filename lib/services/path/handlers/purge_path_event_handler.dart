part of '../path_event_service.dart';

/// Doctrine selection owned by The Purgame event.
extension PurgePathEventHandler on PathEventService {
  PathEventVisitResult resolveThePurgameChoice({
    required Battler player,
    required PurgeDoctrine doctrine,
  }) {
    final doctrineText = switch (doctrine) {
      PurgeDoctrine.embrace =>
        'Abrazas la Purga. Llegara en la ronda 3 e infligira 6 daño por ronda hasta la ronda 10.',
      PurgeDoctrine.wayOut =>
        'Crees en una salida. La Purga llegara en la ronda 7 e infligira 4 daño por ronda hasta la ronda 10.',
    };

    return PathEventVisitResult(
      player: player.copyWith(purgeDoctrine: doctrine),
      outcomeText: doctrineText,
    );
  }
}
