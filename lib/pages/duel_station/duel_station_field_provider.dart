import '_imports.dart';

class DuelStationProvider {
  final Map<DuelistSide, Hand> startingDecks;
  final Map<DuelistSide, Hand> duelingDecks;
  final DuelConfigurations dConfig;

  DuelStationProvider(this.startingDecks, this.dConfig) : duelingDecks = {
          DuelistSide.ally: List.from(startingDecks[DuelistSide.ally] ?? []),
          DuelistSide.enemy: List.from(startingDecks[DuelistSide.enemy] ?? []),
        };

  void init() {
    duelingDecks.forEach((_, deck) {
      deck.shuffle();
    });
  }

  Hand getStartingHand(DuelistSide side) {
    return duelingDecks[side]!.sublist(0, dConfig.startingHandSize);
  }
}