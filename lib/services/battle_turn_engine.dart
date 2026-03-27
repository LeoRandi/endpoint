import '_imports.dart';

class BattleCombatFinish {
  final BattleFlowResultType resultType;
  final String resultText;

  const BattleCombatFinish({
    required this.resultType,
    required this.resultText,
  });
}

class BattleTurnResolution {
  final Battler player;
  final Battler enemy;
  final BattleCombatFinish? finish;

  const BattleTurnResolution({
    required this.player,
    required this.enemy,
    this.finish,
  });
}

class BattleTurnEngine {
  const BattleTurnEngine();

  BattleTurnResolution beginTurn({
    required bool isPlayerTurn,
    required Battler player,
    required Battler enemy,
    RunRandomizer? randomizer,
  }) {
    var updatedPlayer = isPlayerTurn
        ? player.removeCombatFlag(Battler.manualAbilityActivatedThisTurnFlag)
        : player;
    var updatedEnemy = isPlayerTurn
        ? enemy
        : enemy.removeCombatFlag(Battler.manualAbilityActivatedThisTurnFlag);

    updatedPlayer = updatedPlayer.progressAbilityCooldownsOnTurnStart(
      isOwnerTurn: isPlayerTurn,
    );
    updatedEnemy = updatedEnemy.progressAbilityCooldownsOnTurnStart(
      isOwnerTurn: !isPlayerTurn,
    );
    updatedPlayer = updatedPlayer.applyStatusTurnStart(
      opponent: updatedEnemy,
      isOwnerTurn: isPlayerTurn,
      randomizer: randomizer,
    );
    updatedEnemy = updatedEnemy.applyStatusTurnStart(
      opponent: updatedPlayer,
      isOwnerTurn: !isPlayerTurn,
      randomizer: randomizer,
    );
    final playerAbilityResolution = updatedPlayer.applyAbilityTurnStartEffects(
      opponent: updatedEnemy,
      isOwnerTurn: isPlayerTurn,
    );
    updatedPlayer = playerAbilityResolution.owner;
    updatedEnemy = playerAbilityResolution.opponent;
    final enemyAbilityResolution = updatedEnemy.applyAbilityTurnStartEffects(
      opponent: updatedPlayer,
      isOwnerTurn: !isPlayerTurn,
    );
    updatedEnemy = enemyAbilityResolution.owner;
    updatedPlayer = enemyAbilityResolution.opponent;
    final playerItemResolution =
        updatedPlayer.applyEquippedItemTurnStartEffects(
      opponent: updatedEnemy,
      isOwnerTurn: isPlayerTurn,
    );
    updatedPlayer = playerItemResolution.owner;
    updatedEnemy = playerItemResolution.opponent;
    final enemyItemResolution = updatedEnemy.applyEquippedItemTurnStartEffects(
      opponent: updatedPlayer,
      isOwnerTurn: !isPlayerTurn,
    );
    updatedEnemy = enemyItemResolution.owner;
    updatedPlayer = enemyItemResolution.opponent;

    return BattleTurnResolution(
      player: updatedPlayer,
      enemy: updatedEnemy,
      finish: finishFor(
        player: updatedPlayer,
        enemy: updatedEnemy,
      ),
    );
  }

  BattleTurnResolution completeTurn({
    required bool didPlayerAct,
    required Battler player,
    required Battler enemy,
    RunRandomizer? randomizer,
  }) {
    var updatedPlayer = player.applyStatusTurnEnd(
      opponent: enemy,
      isOwnerTurn: didPlayerAct,
      randomizer: randomizer,
    );
    var updatedEnemy = enemy.applyStatusTurnEnd(
      opponent: updatedPlayer,
      isOwnerTurn: !didPlayerAct,
      randomizer: randomizer,
    );
    final playerAbilityResolution = updatedPlayer.applyAbilityTurnEndEffects(
      opponent: updatedEnemy,
      isOwnerTurn: didPlayerAct,
    );
    updatedPlayer = playerAbilityResolution.owner;
    updatedEnemy = playerAbilityResolution.opponent;
    final enemyAbilityResolution = updatedEnemy.applyAbilityTurnEndEffects(
      opponent: updatedPlayer,
      isOwnerTurn: !didPlayerAct,
    );
    updatedEnemy = enemyAbilityResolution.owner;
    updatedPlayer = enemyAbilityResolution.opponent;
    final playerItemResolution = updatedPlayer.applyEquippedItemTurnEndEffects(
      opponent: updatedEnemy,
      isOwnerTurn: didPlayerAct,
    );
    updatedPlayer = playerItemResolution.owner;
    updatedEnemy = playerItemResolution.opponent;
    final enemyItemResolution = updatedEnemy.applyEquippedItemTurnEndEffects(
      opponent: updatedPlayer,
      isOwnerTurn: !didPlayerAct,
    );
    updatedEnemy = enemyItemResolution.owner;
    updatedPlayer = enemyItemResolution.opponent;

    if (didPlayerAct) {
      updatedPlayer = updatedPlayer.decrementStatusDurations();
    } else {
      updatedEnemy = updatedEnemy.decrementStatusDurations();
    }

    return BattleTurnResolution(
      player: updatedPlayer,
      enemy: updatedEnemy,
      finish: finishFor(
        player: updatedPlayer,
        enemy: updatedEnemy,
      ),
    );
  }

  BattleCombatFinish? finishFor({
    required Battler player,
    required Battler enemy,
  }) {
    if (enemy.isDefeated) {
      return const BattleCombatFinish(
        resultType: BattleFlowResultType.victory,
        resultText: 'Objetivo neutralizado.',
      );
    }

    if (player.isDefeated) {
      return const BattleCombatFinish(
        resultType: BattleFlowResultType.defeat,
        resultText: 'La unidad ha caido.',
      );
    }

    return null;
  }
}
