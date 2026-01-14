import '_imports.dart';

extension BattleCardFactories on BattleCard {
  static BattleCard createSampleCard(String name) {
    return BattleCard(
      id: UniqueKey().toString(),
      name: name,
      might: 1,
      description: 'This is a sample battle card named $name.',
      tags: [],
    );
  }

  static BattleCardBattler createSampleBattlerCard(String name, Battler battler) {
    return BattleCardBattler(
      id: UniqueKey().toString(),
      name: name,
      might: battler.stats.rawStats[BattlerStatsType.strength] ?? 1,
      description: 'This is a sample battler card named $name.',
      tags: [BattleCardTag.creature],
      battler: battler,
    );
  }

  static BattleCardEffect createSampleEffectCard(String name, String effectType) {
    return BattleCardEffect(
      id: UniqueKey().toString(),
      name: name,
      might: 1,
      description: 'This is a sample effect card named $name.',
      tags: [],
      effectType: effectType,
    );
  }
}

extension DeckFactories on Hand {
  static Hand createSamplePlayerDeck(int deckSize) {
    Hand deck = [
      BattleCardFactories.createSampleBattlerCard('Warrior', BattlerFactories.hero()),
      BattleCardFactories.createSampleBattlerCard('Warrior', BattlerFactories.heroMage()),
      BattleCardFactories.createSampleBattlerCard('Warrior', BattlerFactories.heroCleric()),
      BattleCardFactories.createSampleBattlerCard('Warrior', BattlerFactories.heroRogue()),
    ];

    for (int i = deck.length; i < deckSize; i++) {
      deck.add(
      BattleCardFactories.createSampleCard('Sword Strike'),);
    }

    return deck;
  }

  static Hand createSampleEnemyDeck(int deckSize) {
    Hand deck = [
      BattleCardFactories.createSampleBattlerCard('Goblin', BattlerFactories.goblin()),
      BattleCardFactories.createSampleBattlerCard('Goblin Tank', BattlerFactories.goblinTank()),
      BattleCardFactories.createSampleBattlerCard('Goblin Archer', BattlerFactories.goblinArcher()),
      BattleCardFactories.createSampleBattlerCard('Trash Goblin', BattlerFactories.trashGoblin()),
    ];

    for (int i = deck.length; i < deckSize; i++) {
      deck.add(
      BattleCardFactories.createSampleCard('Dagger Shank'),);
    }

    return deck;
  }
}