import '_imports.dart';

class PathEventVisitResult {
  final Battler player;
  final String outcomeText;
  final Item? gainedItem;
  final BattlerAbility? gainedAbility;
  final PathNode? guaranteedNextNode;

  const PathEventVisitResult({
    required this.player,
    required this.outcomeText,
    this.gainedItem,
    this.gainedAbility,
    this.guaranteedNextNode,
  });
}
