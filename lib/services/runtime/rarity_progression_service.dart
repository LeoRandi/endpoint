import '_imports.dart';

/// Shared rarity progression helpers for rewards, events, and stock services.
abstract final class RarityProgressionService {
  /// Returns [targetRarity] and every lower tier, highest tier first.
  static List<RarityTier> fallbackTiersFrom(RarityTier targetRarity) {
    return List<RarityTier>.unmodifiable(
      RarityTier.values
          .where((rarity) => rarity.isAtMost(targetRarity))
          .toList(growable: false)
          .reversed,
    );
  }

  /// Returns [minimumRarity] and every higher tier, lowest tier first.
  static List<RarityTier> tiersAtLeast(RarityTier minimumRarity) {
    return List<RarityTier>.unmodifiable(
      RarityTier.values
          .where((rarity) => rarity.isAtLeast(minimumRarity))
          .toList(growable: false),
    );
  }

  /// Rolls a tier from [minimumRarity] upward using each tier's roll weight.
  static RarityTier rollWeightedAtLeast({
    required RarityTier minimumRarity,
    required RunRandomizer randomizer,
  }) {
    final allowedTiers = tiersAtLeast(minimumRarity);
    final totalWeight = allowedTiers.fold<double>(
      0,
      (sum, tier) => sum + tier.rollWeight,
    );
    if (totalWeight <= 0) {
      return allowedTiers[randomizer.nextInt(allowedTiers.length)];
    }

    var roll = randomizer.nextDouble() * totalWeight;
    for (final tier in allowedTiers) {
      roll -= tier.rollWeight;
      if (roll <= 0) return tier;
    }

    return allowedTiers.last;
  }
}
