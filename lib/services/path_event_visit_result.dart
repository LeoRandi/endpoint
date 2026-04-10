import '_imports.dart';

class PathEventVisitResult {
  final Battler player;
  final String outcomeText;
  final BattlerAbility? gainedAbility;

  const PathEventVisitResult({
    required this.player,
    required this.outcomeText,
    this.gainedAbility,
  });
}
