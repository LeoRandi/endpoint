part of '../path_event_service.dart';

/// Use cases owned by the Pitonisa Quitapenas event family.
extension PitonisaPathEventHandler on PathEventService {
  List<BattlerStatus> buildPitonisaPurgeableDebuffs(Battler player) {
    return List<BattlerStatus>.unmodifiable(
      player.statuses.where(
        (status) =>
            status.type == BattlerStatusType.debuff && status.isPurgeable,
      ),
    );
  }

  PathEventVisitResult resolvePitonisaDebuffPurge({
    required Battler player,
  }) {
    final debuffs = buildPitonisaPurgeableDebuffs(player);
    if (debuffs.isEmpty) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'La pitonisa no encuentra penas que quitar.',
      );
    }

    var updatedPlayer = player;
    for (final debuff in debuffs) {
      updatedPlayer = updatedPlayer.removeStatusInstance(debuff);
    }

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText: 'La pitonisa elimina ${debuffs.length} debuffs activos.',
    );
  }
}
