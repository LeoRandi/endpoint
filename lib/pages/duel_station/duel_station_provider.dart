import '_imports.dart';

class DuelStationProvider {
  final Map<DuelistSide, Hand> startingDecks;
  final Map<DuelistSide, Hand> duelingDecks;
  final DuelConfigurations dConfig;
  late Map<DuelistSide, List<Battler?>> fieldBattlers; // 5 slots per side
  late Map<DuelistSide, int> activeBattlerIndices; // Track which battler is active
  static const int ACTIVE_BATTLER_SLOT = 2; // Display position of active battler (slot 2)

  DuelStationProvider(this.startingDecks, this.dConfig)
      : duelingDecks = {
          DuelistSide.ally: List.from(startingDecks[DuelistSide.ally] ?? []),
          DuelistSide.enemy: List.from(startingDecks[DuelistSide.enemy] ?? []),
        } {
    fieldBattlers = {
      DuelistSide.ally: List<Battler?>.filled(5, null),
      DuelistSide.enemy: List<Battler?>.filled(5, null),
    };
    activeBattlerIndices = {
      DuelistSide.ally: 0,
      DuelistSide.enemy: 0,
    };
  }

  void init() {
    // Extract battlers from each deck and populate field
    for (final side in [DuelistSide.ally, DuelistSide.enemy]) {
      final deck = duelingDecks[side]!;
      final battlerCards = <BattleCardBattler>[];
      
      // Separate battler cards from regular cards
      deck.removeWhere((card) {
        if (card is BattleCardBattler) {
          battlerCards.add(card);
          return true; // Remove from deck
        }
        return false;
      });
      
      // Place battlers into field (up to 5)
      for (int i = 0; i < battlerCards.length && i < 5; i++) {
        fieldBattlers[side]![i] = battlerCards[i].battler;
      }
      
      // Shuffle remaining playable deck
      deck.shuffle();
    }
  }

  Hand getStartingHand(DuelistSide side) {
    return duelingDecks[side]!.sublist(0, dConfig.startingHandSize);
  }

  void placeBattlerOnField(BattleCard card, DuelistSide side, int slotIndex) {
    if (card is BattleCardBattler && slotIndex >= 0 && slotIndex < 5) {
      fieldBattlers[side]![slotIndex] = card.battler;
    }
  }

  void removeBattlerFromField(DuelistSide side, int slotIndex) {
    if (slotIndex >= 0 && slotIndex < 5) {
      fieldBattlers[side]![slotIndex] = null;
    }
  }

  List<Battler?> getFieldBattlers(DuelistSide side) {
    return fieldBattlers[side] ?? [];
  }

  Battler? getActiveBattler(DuelistSide side) {
    // Return the active battler based on current index
    final index = activeBattlerIndices[side] ?? 0;
    return fieldBattlers[side]?.isNotEmpty ?? false ? fieldBattlers[side]![index] : null;
  }

  // Get the slot index that corresponds to the active battler display position
  int getActiveBattlerSlotIndex(DuelistSide side) {
    return activeBattlerIndices[side] ?? 0;
  }

  // Rotate parties to show next battler (skip empty slots)
  // Returns true if rotation was successful, false if no valid battlers found
  bool rotateActiveBattler(DuelistSide side) {
    final battlers = fieldBattlers[side];
    if (battlers == null || battlers.isEmpty) return false;

    // Try to find the next non-null battler
    int currentIndex = activeBattlerIndices[side] ?? 0;
    int nextIndex = currentIndex;
    int attempts = 0;

    do {
      // Move to next slot (rotate clockwise for internal logic)
      nextIndex = (nextIndex + 1) % 5;
      attempts++;
    } while (battlers[nextIndex] == null && attempts < 5);

    // Only update if we found a valid battler
    if (battlers[nextIndex] != null) {
      activeBattlerIndices[side] = nextIndex;
      return true;
    }

    return false;
  }

  // Rotate both parties
  void rotateAllBattlers() {
    rotateActiveBattler(DuelistSide.enemy);
    rotateActiveBattler(DuelistSide.ally);
  }
}