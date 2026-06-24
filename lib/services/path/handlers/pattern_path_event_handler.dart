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
      buildOwnedItems(player).where((item) => item.patternEffects.isNotEmpty),
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
        firstItem.patternEffects.isEmpty ||
        secondItem.patternEffects.isEmpty) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'La cabina no encuentra dos patrones compatibles.',
      );
    }

    final firstPatternEntries = firstItem.effects.entries
        .where((entry) => entry.key is PatternEffect)
        .toList(growable: false);
    final secondPatternEntries = secondItem.effects.entries
        .where((entry) => entry.key is PatternEffect)
        .toList(growable: false);
    final updatedFirst = firstItem.copyWith(effects: <Effect, int>{
      for (final entry in firstItem.effects.entries)
        if (entry.key is! PatternEffect) entry.key: entry.value,
      for (final entry in secondPatternEntries) entry.key: entry.value,
    });
    final updatedSecond = secondItem.copyWith(effects: <Effect, int>{
      for (final entry in secondItem.effects.entries)
        if (entry.key is! PatternEffect) entry.key: entry.value,
      for (final entry in firstPatternEntries) entry.key: entry.value,
    });
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
