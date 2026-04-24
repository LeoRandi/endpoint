import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LevelUpRewardService', () {
    const service = LevelUpRewardService();

    test('uses the configured level reward sequence', () {
      expect(
        LevelUpRewardService.rewardTypeForNextLevel(2),
        BattlerLevelRewardChoiceType.ability,
      );
      expect(
        LevelUpRewardService.rewardTypeForNextLevel(3),
        BattlerLevelRewardChoiceType.item,
      );
      expect(
        LevelUpRewardService.rewardTypeForNextLevel(4),
        BattlerLevelRewardChoiceType.stat,
      );
      expect(
        LevelUpRewardService.rewardTypeForNextLevel(5),
        BattlerLevelRewardChoiceType.ability,
      );
      expect(
        LevelUpRewardService.rewardTypeForNextLevel(6),
        BattlerLevelRewardChoiceType.item,
      );
      expect(
        LevelUpRewardService.rewardTypeForNextLevel(7),
        BattlerLevelRewardChoiceType.stat,
      );
    });

    test('first level-up offers three green abilities for the archetype pool',
        () {
      final player = _levelReadyPlayer(archetypeId: ArchetypeId.veloz);
      final offer = service.buildOffer(
        player: player,
        randomizer: RunRandomizer(seed: 1),
      );

      expect(offer.type, BattlerLevelRewardChoiceType.ability);
      expect(offer.rarity, RarityTier.green);
      expect(offer.choices, hasLength(3));
      for (final choice in offer.choices) {
        final ability = choice.ability;
        expect(ability, isNotNull);
        expect(ability!.rarity, RarityTier.green);
        expect(
          ability.hasAnyArchetypeAffinity(
            const [
              BattlerAbilityArchetypeAffinity.general,
              BattlerAbilityArchetypeAffinity.veloz,
            ],
          ),
          isTrue,
        );
      }
    });

    test('second level-up offers blue items', () {
      final player = _levelReadyPlayer(
        level: 2,
        archetypeId: ArchetypeId.inamovible,
      );
      final offer = service.buildOffer(
        player: player,
        randomizer: RunRandomizer(seed: 2),
      );

      expect(offer.type, BattlerLevelRewardChoiceType.item);
      expect(offer.rarity, RarityTier.blue);
      expect(offer.choices, hasLength(3));
      for (final choice in offer.choices) {
        final item = choice.item;
        expect(item, isNotNull);
        expect(item!.rarity, RarityTier.blue);
      }
    });

    test('ability and item choices apply while keeping base level stats', () {
      final abilityPlayer = _levelReadyPlayer(archetypeId: ArchetypeId.veloz);
      final abilityOffer = service.buildOffer(
        player: abilityPlayer,
        randomizer: RunRandomizer(seed: 3),
      );
      final abilityChoice = abilityOffer.choices.first;
      final abilityResult = abilityPlayer.applyLevelReward(abilityChoice);

      expect(abilityResult.level, 2);
      expect(abilityResult.attack, abilityPlayer.attack + 1);
      expect(abilityResult.maxHealth, abilityPlayer.maxHealth + 10);
      expect(
          abilityResult.equipmentCapacity, abilityPlayer.equipmentCapacity + 1);
      expect(abilityResult.hasAbility(abilityChoice.ability!), isTrue);

      final itemPlayer = _levelReadyPlayer(
        level: 2,
        archetypeId: ArchetypeId.inamovible,
      );
      final itemOffer = service.buildOffer(
        player: itemPlayer,
        randomizer: RunRandomizer(seed: 4),
      );
      final itemChoice = itemOffer.choices.first;
      final itemResult = itemPlayer.applyLevelReward(itemChoice);
      final ownedItem = itemResult.inventoryItemOfType(itemChoice.item!.id);

      expect(itemResult.level, 3);
      expect(itemResult.attack, itemPlayer.attack + 1);
      expect(itemResult.maxHealth, itemPlayer.maxHealth + 10);
      expect(ownedItem, isNotNull);
      expect(ownedItem!.rarity, RarityTier.blue);
    });
  });

  group('Item sell value', () {
    test('increases when an item instance upgrades to the next tier', () {
      final item = cyberWhipsItem.toOwnedInstance();
      final upgradedItem = item.upgraded();

      expect(item.rarity, RarityTier.green);
      expect(item.sellValue, 2);
      expect(upgradedItem.rarity, RarityTier.blue);
      expect(upgradedItem.sellValue, 3);
      expect(upgradedItem.sellValue, greaterThan(item.sellValue));
    });

    test('updates the owned instance sell value when addItem upgrades it', () {
      var player = defaultPlayerBattler.addItem(cyberWhipsItem);
      final ownedBefore = player.inventoryItemOfType(ItemId.cyberWhips);

      expect(ownedBefore, isNotNull);
      expect(ownedBefore!.sellValue, 2);

      player = player.addItem(cyberWhipsItem);
      final ownedAfter = player.inventoryItemOfType(ItemId.cyberWhips);

      expect(ownedAfter, isNotNull);
      expect(ownedAfter!.instanceId, ownedBefore.instanceId);
      expect(ownedAfter.rarity, RarityTier.blue);
      expect(ownedAfter.sellValue, 3);
      expect(ownedAfter.sellValue, greaterThan(ownedBefore.sellValue));
    });
  });
}

Battler _levelReadyPlayer({
  int level = 1,
  ArchetypeId? archetypeId,
}) {
  final player = defaultPlayerBattler.copyWith(
    archetypeId: archetypeId,
    level: level,
  );

  return player.copyWith(experience: player.experienceToNextLevel);
}
