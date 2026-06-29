import '../random_source.dart';
import 'operative_pattern_point.dart';

class BattlePatternMatchContext {
  final List<OperativePatternPoint> patternPoints;
  final int attackBonus;
  final int barrierBonus;
  final int otherArchetypeItemCount;
  final List<String> usedItemPointKeys;
  final Set<String> repeatedItemPointKeys;
  final String? firstRepeatedItemPointKey;
  final bool firstUsedItemHasAttackBonus;
  final int activatedItemEffectCount;
  final RandomSource? randomSource;

  const BattlePatternMatchContext({
    required this.patternPoints,
    required this.attackBonus,
    required this.barrierBonus,
    this.otherArchetypeItemCount = 0,
    this.usedItemPointKeys = const <String>[],
    this.repeatedItemPointKeys = const <String>{},
    this.firstRepeatedItemPointKey,
    this.firstUsedItemHasAttackBonus = false,
    this.activatedItemEffectCount = 0,
    this.randomSource,
  });

  BattlePatternMatchContext withRandomSource(RandomSource randomSource) {
    return BattlePatternMatchContext(
      patternPoints: patternPoints,
      attackBonus: attackBonus,
      barrierBonus: barrierBonus,
      otherArchetypeItemCount: otherArchetypeItemCount,
      usedItemPointKeys: usedItemPointKeys,
      repeatedItemPointKeys: repeatedItemPointKeys,
      firstRepeatedItemPointKey: firstRepeatedItemPointKey,
      firstUsedItemHasAttackBonus: firstUsedItemHasAttackBonus,
      activatedItemEffectCount: activatedItemEffectCount,
      randomSource: randomSource,
    );
  }
}
