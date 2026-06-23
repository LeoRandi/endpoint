part of '../path_event_service.dart';

/// Purchase and negotiated-route use cases shared by market events.
extension MarketPathEventHandler on PathEventService {
  List<BattlerAbility> buildBlackTechnoMarketOffers({
    required Battler player,
    required RunRandomizer randomizer,
    int count = 3,
  }) {
    final eligiblePresets = abilityPresets.where((ability) {
      final ownedAbility = player.abilityById(ability.id);
      return ownedAbility == null || ownedAbility.canUpgrade;
    }).toList(growable: false);
    if (count <= 0 || eligiblePresets.isEmpty) {
      return const <BattlerAbility>[];
    }

    final selectedPresets = randomizer.pickDistinct(eligiblePresets, count);
    return List<BattlerAbility>.unmodifiable(
      selectedPresets.map(
        (preset) => _rollBlackTechnoMarketOffer(
          preset: preset,
          player: player,
          randomizer: randomizer,
        ),
      ),
    );
  }

  int blackTechnoMarketPriceFor(BattlerAbility ability) {
    return max(0, ability.rarity.factor * 5);
  }

  PathEventVisitResult resolveBlackTechnoMarketPurchase({
    required Battler player,
    required BattlerAbility selectedAbility,
  }) {
    final price = blackTechnoMarketPriceFor(selectedAbility);
    if (!player.canAfford(price)) {
      return PathEventVisitResult(
        player: player,
        outcomeText:
            'No tienes creditos suficientes para comprar ${selectedAbility.displayName}.',
      );
    }

    final existingAbility = player.abilityById(selectedAbility.id);
    if (existingAbility != null && !existingAbility.canUpgrade) {
      return PathEventVisitResult(
        player: player,
        outcomeText:
            '${existingAbility.displayName} no puede mejorar mas ahora mismo.',
      );
    }

    final updatedPlayer = player
        .spendMoney(price)
        .addAbility(_runtimeService.runtimeAbility(selectedAbility));
    final resolvedAbility =
        updatedPlayer.abilityById(selectedAbility.id) ?? selectedAbility;
    final outcomeText = existingAbility == null
        ? 'Has comprado ${resolvedAbility.displayName} por ${price}C.'
        : 'Has comprado una copia de ${resolvedAbility.displayName} por ${price}C. Su tier actual es ${_rarityLabel(resolvedAbility.rarity)}.';

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText: outcomeText,
      gainedAbility: resolvedAbility,
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
