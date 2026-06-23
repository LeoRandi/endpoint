part of '../path_event_service.dart';

/// Timeline and operative-pattern mutation event use cases.
extension PatternPathEventHandler on PathEventService {
  PathEventVisitResult resolveTempografoChoice({
    required Battler player,
    required bool preferShops,
  }) {
    return PathEventVisitResult(
      player: player,
      outcomeText: preferShops
          ? 'El Tempografo adelanta las tiendas y retrasa los eventos hasta que termine el dia.'
          : 'El Tempografo adelanta los eventos y retrasa las tiendas hasta que termine el dia.',
      nextShopRarityDayOffset: preferShops ? 1 : -1,
      nextEventRarityDayOffset: preferShops ? -1 : 1,
    );
  }

  List<Item> buildSWitchCabinEligibleItems(Battler player) {
    return List<Item>.unmodifiable(
      buildOwnedItems(player).where((item) => item.hasPatternBonus),
    );
  }

  PathEventVisitResult resolveSWitchPatternSwap({
    required Battler player,
    required Item firstItem,
    required Item secondItem,
  }) {
    if (firstItem == secondItem ||
        !_ownsItem(player, firstItem) ||
        !_ownsItem(player, secondItem) ||
        !firstItem.hasPatternBonus ||
        !secondItem.hasPatternBonus) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'La cabina no encuentra dos patrones compatibles.',
      );
    }

    final updatedFirst = firstItem.copyWith(
      patternBonusKindOverride: secondItem.patternBonusKind,
      patternBonusAmountOverride: secondItem.patternBonusAmount,
      patternRequirementOverride: secondItem.patternRequirement,
    );
    final updatedSecond = secondItem.copyWith(
      patternBonusKindOverride: firstItem.patternBonusKind,
      patternBonusAmountOverride: firstItem.patternBonusAmount,
      patternRequirementOverride: firstItem.patternRequirement,
    );
    final updatedPlayer = _replaceOwnedItems(
      player: player,
      replacements: {
        firstItem: updatedFirst,
        secondItem: updatedSecond,
      },
    );

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          '${firstItem.displayName} y ${secondItem.displayName} intercambian sus bonus de Patron.',
    );
  }
}
