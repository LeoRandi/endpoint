import 'dart:math';

import '../entities/_exports.dart';
import 'run_completion_type.dart';
import 'run_day_summary.dart';
import 'run_hour_snapshot.dart';

enum EndpointGameMode {
  classic,
  drawing,
}

class EndpointSettingsSnapshot {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final int animationSpeed;
  final bool customAvatarEnabled;
  final bool customAvatarSelectionEnabled;
  final EndpointGameMode gameMode;

  const EndpointSettingsSnapshot({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.animationSpeed,
    required this.customAvatarEnabled,
    required this.customAvatarSelectionEnabled,
    required this.gameMode,
  });

  const EndpointSettingsSnapshot.defaults()
      : soundEnabled = true,
        vibrationEnabled = true,
        animationSpeed = 2,
        customAvatarEnabled = false,
        customAvatarSelectionEnabled = false,
        gameMode = EndpointGameMode.drawing;

  EndpointSettingsSnapshot copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? animationSpeed,
    bool? customAvatarEnabled,
    bool? customAvatarSelectionEnabled,
    EndpointGameMode? gameMode,
  }) {
    return EndpointSettingsSnapshot(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      animationSpeed: (animationSpeed ?? this.animationSpeed).clamp(1, 3),
      customAvatarEnabled: customAvatarEnabled ?? this.customAvatarEnabled,
      customAvatarSelectionEnabled:
          customAvatarSelectionEnabled ?? this.customAvatarSelectionEnabled,
      gameMode: gameMode ?? this.gameMode,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'animationSpeed': animationSpeed,
      'customAvatarEnabled': customAvatarEnabled,
      'customAvatarSelectionEnabled': customAvatarSelectionEnabled,
      'gameMode': gameMode.name,
    };
  }

  factory EndpointSettingsSnapshot.fromJson(Map<String, dynamic> json) {
    const defaultSettings = EndpointSettingsSnapshot.defaults();

    return EndpointSettingsSnapshot(
      soundEnabled: json['soundEnabled'] is bool
          ? json['soundEnabled'] as bool
          : defaultSettings.soundEnabled,
      vibrationEnabled: json['vibrationEnabled'] is bool
          ? json['vibrationEnabled'] as bool
          : defaultSettings.vibrationEnabled,
      animationSpeed: (json['animationSpeed'] is int
              ? json['animationSpeed'] as int
              : defaultSettings.animationSpeed)
          .clamp(1, 3),
      customAvatarEnabled: json['customAvatarEnabled'] is bool
          ? json['customAvatarEnabled'] as bool
          : defaultSettings.customAvatarEnabled,
      customAvatarSelectionEnabled: json['customAvatarSelectionEnabled'] is bool
          ? json['customAvatarSelectionEnabled'] as bool
          : defaultSettings.customAvatarSelectionEnabled,
      gameMode: EndpointGameMode.values.cast<EndpointGameMode?>().firstWhere(
            (mode) => mode?.name == json['gameMode'],
            orElse: () => defaultSettings.gameMode,
          )!,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EndpointSettingsSnapshot &&
        other.soundEnabled == soundEnabled &&
        other.vibrationEnabled == vibrationEnabled &&
        other.animationSpeed == animationSpeed &&
        other.customAvatarEnabled == customAvatarEnabled &&
        other.customAvatarSelectionEnabled == customAvatarSelectionEnabled &&
        other.gameMode == gameMode;
  }

  @override
  int get hashCode => Object.hash(
        soundEnabled,
        vibrationEnabled,
        animationSpeed,
        customAvatarEnabled,
        customAvatarSelectionEnabled,
        gameMode,
      );
}

class EndpointCurrentRunSnapshot {
  final Battler player;
  final RunHourSnapshot currentHour;
  final List<PathNode> visibleNodes;
  final int stageIndex;
  final bool isResolvingNode;
  final bool isRunComplete;
  final RunCompletionType? completionType;
  final int savedNodeCount;
  final int randomSeed;
  final int randomState;
  final Duration battleEnemyTurnDelay;
  final Duration battleCombatEndDelay;
  final RunDaySummary currentDaySummary;
  final RunDaySummary? pendingDaySummary;
  final PathNode? activeNode;

  const EndpointCurrentRunSnapshot({
    required this.player,
    required this.currentHour,
    required this.visibleNodes,
    required this.stageIndex,
    required this.isResolvingNode,
    required this.isRunComplete,
    required this.completionType,
    this.savedNodeCount = 0,
    required this.randomSeed,
    required this.randomState,
    required this.battleEnemyTurnDelay,
    required this.battleCombatEndDelay,
    this.currentDaySummary = const RunDaySummary.empty(),
    this.pendingDaySummary,
    this.activeNode,
  });

  int get nodeCount => max(
        1,
        savedNodeCount > 0 ? savedNodeCount : visibleNodes.length,
      );

  bool get canContinue =>
      !isRunComplete &&
      completionType == null &&
      (visibleNodes.isNotEmpty || pendingDaySummary != null);
}
