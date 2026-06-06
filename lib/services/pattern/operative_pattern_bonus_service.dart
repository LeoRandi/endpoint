import 'dart:math';

import '../../entities/_exports.dart';

Map<String, OperativePatternBonus> buildOperativePatternBonusesByPointKey({
  required int playerLevel,
  required Iterable<String> occupiedPointKeys,
  Iterable<String> adaptableOccupiedPointKeys = const <String>[],
  int maxAdaptableBonusAmount = 0,
  int Function(int max)? nextInt,
  Random? random,
}) {
  final randomizer = random ?? Random();
  final randomNextInt = nextInt ?? randomizer.nextInt;
  final occupied = occupiedPointKeys.toSet();
  final adaptableOccupied = adaptableOccupiedPointKeys.toSet();
  final maxAmount = max(Battler.initialLevel, playerLevel);
  final adaptationCap = max(0, maxAdaptableBonusAmount);

  return <String, OperativePatternBonus>{
    for (final point in operativePatternPoints) ...{
      if (!occupied.contains(point.key) ||
          adaptableOccupied.contains(point.key))
        point.key: _buildPatternBonus(
          maxAmount: maxAmount,
          randomNextInt: randomNextInt,
          maxBonusAmount: occupied.contains(point.key) ? adaptationCap : 0,
        ),
    },
  };
}

OperativePatternBonus _buildPatternBonus({
  required int maxAmount,
  required int Function(int max) randomNextInt,
  required int maxBonusAmount,
}) {
  final amount = 1 + randomNextInt(maxAmount);
  return OperativePatternBonus(
    kind: randomNextInt(2) == 0
        ? OperativePatternBonusKind.attack
        : OperativePatternBonusKind.barrier,
    amount: maxBonusAmount > 0 ? min(amount, maxBonusAmount) : amount,
  );
}
