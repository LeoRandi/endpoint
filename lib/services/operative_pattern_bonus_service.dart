import 'dart:math';

import '../entities/_exports.dart';

Map<String, OperativePatternBonus> buildOperativePatternBonusesByPointKey({
  required int playerLevel,
  required Iterable<String> occupiedPointKeys,
  Random? random,
}) {
  final randomizer = random ?? Random();
  final occupied = occupiedPointKeys.toSet();
  final maxAmount = max(Battler.initialLevel, playerLevel);

  return <String, OperativePatternBonus>{
    for (final point in operativePatternPoints)
      if (!occupied.contains(point.key))
        point.key: OperativePatternBonus(
          kind: randomizer.nextBool()
              ? OperativePatternBonusKind.attack
              : OperativePatternBonusKind.barrier,
          amount: 1 + randomizer.nextInt(maxAmount),
        ),
  };
}
