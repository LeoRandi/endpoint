import 'package:flutter_test/flutter_test.dart';

import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';
import 'test_battler_factory.dart';

void main() {
  test('rest zone heals the player to full health', () {
    final player = buildTestBattler(
      name: 'Player',
      attack: 3,
      defense: 1,
      health: 4,
      maxHealth: 10,
      statuses: const [
        QuemaduraStatus(remainingTurns: 2),
      ],
    );

    final result = CampSiteService(
      recoveryFactor: restZoneCampNode.recoveryFactor,
      removeRandomDebuff: restZoneCampNode.removeRandomDebuff,
    ).recover(player);

    expect(result.player.health, 10);
    expect(result.healedAmount, 6);
    expect(result.removedDebuff, isNull);
    expect(result.player.hasStatus('quemadura'), isTrue);
  });

  test('severe medication heals a third and removes one random debuff', () {
    final player = buildTestBattler(
      name: 'Player',
      attack: 3,
      defense: 1,
      health: 4,
      maxHealth: 12,
      statuses: const [
        CalentandoStatus(),
        QuemaduraStatus(remainingTurns: 2),
      ],
    );

    final result = CampSiteService(
      recoveryFactor: severeMedicationCampNode.recoveryFactor,
      removeRandomDebuff: severeMedicationCampNode.removeRandomDebuff,
    ).recover(player);

    expect(result.player.health, 8);
    expect(result.healedAmount, 4);
    expect(result.removedDebuff?.id, 'quemadura');
    expect(result.player.hasStatus('quemadura'), isFalse);
    expect(result.player.hasStatus('calentando'), isTrue);
  });
}
