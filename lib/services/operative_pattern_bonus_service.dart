import 'dart:math';

import '../entities/_exports.dart';

Map<String, OperativePatternBonus> buildOperativePatternBonusesByPointKey({
  required int playerLevel,
  required Iterable<String> occupiedPointKeys,
  int Function(int max)? nextInt,
  Random? random,
}) {
  final randomizer = random ?? Random();
  final randomNextInt = nextInt ?? randomizer.nextInt;
  final occupied = occupiedPointKeys.toSet();
  final maxAmount = max(Battler.initialLevel, playerLevel);

  return <String, OperativePatternBonus>{
    for (final point in operativePatternPoints)
      if (!occupied.contains(point.key))
        point.key: OperativePatternBonus(
          kind: randomNextInt(2) == 0
              ? OperativePatternBonusKind.attack
              : OperativePatternBonusKind.barrier,
          amount: 1 + randomNextInt(maxAmount),
        ),
  };
}
