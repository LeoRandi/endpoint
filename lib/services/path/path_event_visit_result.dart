import '_imports.dart';

class PathEventVisitResult {
  final Battler player;
  final String outcomeText;
  final Item? gainedItem;
  final Augment? gainedAugment;
  final PathNode? guaranteedNextNode;
  final int nextShopRarityDayOffset;
  final int nextEventRarityDayOffset;
  final bool defeatedEnemy;
  final Battler? defeatedEnemyBattler;
  final RarityTier? defeatedEnemyRarity;
  final GhostItemLease? ghostItemLease;

  const PathEventVisitResult({
    required this.player,
    required this.outcomeText,
    this.gainedItem,
    this.gainedAugment,
    this.guaranteedNextNode,
    this.nextShopRarityDayOffset = 0,
    this.nextEventRarityDayOffset = 0,
    this.defeatedEnemy = false,
    this.defeatedEnemyBattler,
    this.defeatedEnemyRarity,
    this.ghostItemLease,
  });
}
