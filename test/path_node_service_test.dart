import 'package:flutter_test/flutter_test.dart';

import 'package:endpoint/_imports.dart';

void main() {
  test('opening hour always offers the three archetype nodes', () {
    final snapshot = PathNodeService(seed: 1).buildHourSnapshot(
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
  });
}
