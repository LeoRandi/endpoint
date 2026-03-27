import 'package:flutter_test/flutter_test.dart';

import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';

void main() {
  test('opening hour always offers the three archetype nodes', () {
    final snapshot = PathNodeService(
      randomizer: RunRandomizer(seed: 1),
    ).buildHourSnapshot(
      stageIndex: PathNodeService.startStageIndex,
    );

    expect(snapshot.stageIndex, PathNodeService.startStageIndex);
    expect(
      snapshot.nodes.map((node) => node.label).toList(growable: false),
      ['Veloz', 'Inamovible', 'Imparable'],
    );
    expect(snapshot.nodes.every((node) => node.hasSignatureBorder), isTrue);
  });

  test('archetype selection equips the player and restores full health', () {
    final updatedPlayer = inamovibleArchetypeNode.applyTo(defaultPlayerBattler);

    expect(updatedPlayer.iconEmoji, shieldItem.iconEmoji);
    expect(updatedPlayer.health, updatedPlayer.maxHealth);
    expect(
      updatedPlayer.equippedItems.map((item) => item.id).toSet(),
      {ItemId.shield, ItemId.bulwarkAmulet},
    );
    expect(
      updatedPlayer.inventoryItems.map((item) => item.id).toSet(),
      containsAll({
        ItemId.crackedBattery,
        ItemId.impactGloves,
        ItemId.chemicalFilter,
        ItemId.billingModule,
        ItemId.portableOven,
        ItemId.parasiticCapacitor,
        ItemId.eclipseMantle,
        ItemId.operativeBlackBox,
      }),
    );
  });

  test('last hour before sunrise always offers the two recovery side nodes',
      () {
    final snapshot = PathNodeService(
      randomizer: RunRandomizer(seed: 7),
    ).buildHourSnapshot(
      stageIndex: PathNodeService.sunriseStageIndex - 1,
    );

    expect(snapshot.nodes, hasLength(3));
    expect(snapshot.nodes.first.label, restZoneCampNode.label);
    expect(snapshot.nodes.last.label, severeMedicationCampNode.label);
    expect(snapshot.nodes[1], isA<ShopPathNode>());
  });
}
