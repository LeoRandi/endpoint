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
  final BattlerEffectPipeline _effectPipeline;

  const BattleTurnEngine({
    BattlerEffectPipeline effectPipeline = const BattlerEffectPipeline(),
  }) : _effectPipeline = effectPipeline;

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
    updatedPlayer = _effectPipeline.applyStatusTurnStart(
      owner: updatedPlayer,
      opponent: updatedEnemy,
      isOwnerTurn: isPlayerTurn,
      randomizer: randomizer,
    );
    updatedEnemy = _effectPipeline.applyStatusTurnStart(
      owner: updatedEnemy,
      opponent: updatedPlayer,
      isOwnerTurn: !isPlayerTurn,
      randomizer: randomizer,
    );
    final playerAbilityResolution =
        _effectPipeline.applyAbilityTurnStartEffects(
      owner: updatedPlayer,
      opponent: updatedEnemy,
      isOwnerTurn: isPlayerTurn,
    );
    updatedPlayer = playerAbilityResolution.owner;
    updatedEnemy = playerAbilityResolution.opponent;
    final enemyAbilityResolution = _effectPipeline.applyAbilityTurnStartEffects(
      owner: updatedEnemy,
      opponent: updatedPlayer,
      isOwnerTurn: !isPlayerTurn,
    );
    updatedEnemy = enemyAbilityResolution.owner;
    updatedPlayer = enemyAbilityResolution.opponent;
    final playerItemResolution =
        _effectPipeline.applyEquippedItemTurnStartEffects(
      owner: updatedPlayer,
      opponent: updatedEnemy,
      isOwnerTurn: isPlayerTurn,
    );
    updatedPlayer = playerItemResolution.owner;
    updatedEnemy = playerItemResolution.opponent;
    final enemyItemResolution =
        _effectPipeline.applyEquippedItemTurnStartEffects(
      owner: updatedEnemy,
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
    var updatedPlayer = _effectPipeline.applyStatusTurnEnd(
      owner: player,
      opponent: enemy,
      isOwnerTurn: didPlayerAct,
      randomizer: randomizer,
    );
    var updatedEnemy = _effectPipeline.applyStatusTurnEnd(
      owner: enemy,
      opponent: updatedPlayer,
      isOwnerTurn: !didPlayerAct,
      randomizer: randomizer,
    );
    final playerAbilityResolution = _effectPipeline.applyAbilityTurnEndEffects(
      owner: updatedPlayer,
      opponent: updatedEnemy,
      isOwnerTurn: didPlayerAct,
    );
    updatedPlayer = playerAbilityResolution.owner;
    updatedEnemy = playerAbilityResolution.opponent;
    final enemyAbilityResolution = _effectPipeline.applyAbilityTurnEndEffects(
      owner: updatedEnemy,
      opponent: updatedPlayer,
      isOwnerTurn: !didPlayerAct,
    );
    updatedEnemy = enemyAbilityResolution.owner;
    updatedPlayer = enemyAbilityResolution.opponent;
    final playerItemResolution =
        _effectPipeline.applyEquippedItemTurnEndEffects(
      owner: updatedPlayer,
      opponent: updatedEnemy,
      isOwnerTurn: didPlayerAct,
    );
    updatedPlayer = playerItemResolution.owner;
    updatedEnemy = playerItemResolution.opponent;
    final enemyItemResolution = _effectPipeline.applyEquippedItemTurnEndEffects(
      owner: updatedEnemy,
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

  /// Decide el resultado del combate priorizando siempre la muerte del jugador.
  BattleCombatFinish? finishFor({
    required Battler player,
    required Battler enemy,
  }) {
    if (player.isDefeated && enemy.isDefeated) {
      return const BattleCombatFinish(
        resultType: BattleFlowResultType.defeat,
        resultText: 'La unidad y el objetivo han caido.',
      );
    }

    if (player.isDefeated) {
      return const BattleCombatFinish(
        resultType: BattleFlowResultType.defeat,
        resultText: 'La unidad ha caido.',
      );
    }

    if (enemy.isDefeated) {
      return const BattleCombatFinish(
        resultType: BattleFlowResultType.victory,
        resultText: 'Objetivo neutralizado.',
      );
    }

    return null;
  }
}
