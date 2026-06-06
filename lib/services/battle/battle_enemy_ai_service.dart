import 'dart:math';

import '../../entities/_exports.dart';
import '../run/run_randomizer.dart';

enum EnemyTurnAction {
  attack,
  defend,
}

enum EnemyAiDifficultyLevel {
  alpha,
  beta,
  omega,
}

/// Owns enemy turn-choice state so BattleController does not need to track AI
/// streaks, tier mapping, and probability rules alongside combat flow.
class BattleEnemyAiService {
  final EnemyAiDifficultyLevel difficulty;

  EnemyTurnAction? _lastResolvedAction;
  int _sameActionStreak = 0;

  BattleEnemyAiService({
    required this.difficulty,
  });

  factory BattleEnemyAiService.forEnemyTier(int enemyTier) {
    return BattleEnemyAiService(
      difficulty: difficultyForEnemyTier(enemyTier),
    );
  }

  /// Rolls the next enemy action, forcing variety on higher difficulties after
  /// long repeated streaks.
  EnemyTurnAction rollNextAction({
    required Battler enemy,
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    final forcedAction = _forcedActionForDifficulty();
    if (forcedAction != null) {
      return forcedAction;
    }

    return randomizer.chance(
      _attackChance(
        enemy: enemy,
        player: player,
      ),
    )
        ? EnemyTurnAction.attack
        : EnemyTurnAction.defend;
  }

  /// Records the resolved action so future rolls can react to repeated choices.
  void registerResolvedAction(EnemyTurnAction resolvedAction) {
    if (_lastResolvedAction == resolvedAction) {
      _sameActionStreak++;
      return;
    }

    _lastResolvedAction = resolvedAction;
    _sameActionStreak = 1;
  }

  EnemyTurnAction? _forcedActionForDifficulty() {
    if (difficulty == EnemyAiDifficultyLevel.alpha ||
        _lastResolvedAction == null ||
        _sameActionStreak < 2) {
      return null;
    }

    return _lastResolvedAction == EnemyTurnAction.attack
        ? EnemyTurnAction.defend
        : EnemyTurnAction.attack;
  }

  double _attackChance({
    required Battler enemy,
    required Battler player,
  }) {
    final hasOmegaPriorityCheck = difficulty == EnemyAiDifficultyLevel.omega &&
        enemy.health < player.health;
    if (hasOmegaPriorityCheck) {
      return 0.9;
    }

    final isAboveHalfHealth =
        enemy.maxHealth > 0 && (enemy.health * 2) > enemy.maxHealth;
    return isAboveHalfHealth ? 0.75 : 0.25;
  }

  static EnemyAiDifficultyLevel difficultyForEnemyTier(int enemyTier) {
    final normalizedTier = max(1, enemyTier);
    if (normalizedTier >= RarityTier.yellow.factor) {
      return EnemyAiDifficultyLevel.omega;
    }
    if (normalizedTier >= RarityTier.blue.factor) {
      return EnemyAiDifficultyLevel.beta;
    }
    return EnemyAiDifficultyLevel.alpha;
  }
}
