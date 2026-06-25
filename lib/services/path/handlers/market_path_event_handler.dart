part of '../path_event_service.dart';

/// Purchase and negotiated-route use cases shared by market events.
extension MarketPathEventHandler on PathEventService {
  List<Augment> buildBlackTechnoMarketOffers({
    required Battler player,
    required RunRandomizer randomizer,
    int count = 3,
  }) {
    final eligibleCatalogEntries = augmentCatalog.where((augment) {
      final ownedAugment = player.augmentById(augment.id);
      return ownedAugment == null || ownedAugment.canUpgrade;
    }).toList(growable: false);
    if (count <= 0 || eligibleCatalogEntries.isEmpty) {
      return const <Augment>[];
    }

    final selectedCatalogEntries =
        randomizer.pickDistinct(eligibleCatalogEntries, count);
    return List<Augment>.unmodifiable(
      selectedCatalogEntries.map(
        (catalogEntry) => _rollBlackTechnoMarketOffer(
          catalogEntry: catalogEntry,
          player: player,
          randomizer: randomizer,
        ),
      ),
    );
  }

  int blackTechnoMarketPriceFor(Augment augment) {
    return max(0, augment.rarity.factor * 5);
  }

  PathEventVisitResult resolveBlackTechnoMarketPurchase({
    required Battler player,
    required Augment selectedAugment,
  }) {
    final price = blackTechnoMarketPriceFor(selectedAugment);
    if (!player.canAfford(price)) {
      return PathEventVisitResult(
        player: player,
        outcomeText:
            'No tienes creditos suficientes para comprar ${selectedAugment.displayName}.',
      );
    }

    final existingAugment = player.augmentById(selectedAugment.id);
    if (existingAugment != null && !existingAugment.canUpgrade) {
      return PathEventVisitResult(
        player: player,
        outcomeText:
            '${existingAugment.displayName} no puede mejorar mas ahora mismo.',
      );
    }

    final updatedPlayer = player
        .spendMoney(price)
        .addAugment(_runtimeService.runtimeAugment(selectedAugment));
    final resolvedAugment =
        updatedPlayer.augmentById(selectedAugment.id) ?? selectedAugment;
    final outcomeText = existingAugment == null
        ? 'Has comprado ${resolvedAugment.displayName} por ${price}C.'
        : 'Has comprado una copia de ${resolvedAugment.displayName} por ${price}C. Su tier actual es ${_rarityLabel(resolvedAugment.rarity)}.';

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText: outcomeText,
      gainedAugment: resolvedAugment,
    );
  }

  List<PathNode> buildSecretPassageOffers({
    required RunRandomizer randomizer,
    int count = 5,
  }) {
    final offerPool = allPathNodes
        .where(_isPasadizoSecretoOfferCandidate)
        .toList(growable: false);
    if (count <= 0 || offerPool.isEmpty) {
      return const <PathNode>[];
    }

    return List<PathNode>.unmodifiable(
      randomizer.pickDistinct(offerPool, count),
    );
  }

  int get pasadizoSecretoDealCost => 10;

  PathEventVisitResult resolvePasadizoSecretoDeal({
    required Battler player,
    required PathNode selectedNode,
  }) {
    if (!_isPasadizoSecretoOfferCandidate(selectedNode)) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'El trato no puede cerrarse con ese nodo.',
      );
    }

    final price = pasadizoSecretoDealCost;
    if (!player.canAfford(price)) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'No tienes creditos suficientes para cerrar el trato.',
      );
    }

    final updatedPlayer = player.spendMoney(price);
    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Pagas ${price}C. En la siguiente eleccion aparecera ${selectedNode.label}.',
      guaranteedNextNode: selectedNode,
    );
  }
}
