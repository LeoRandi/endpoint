import 'dart:math';

import '../../entities/_exports.dart';
import '../run/run_hour_snapshot.dart';
import '../run/run_completion_type.dart';
import '../run/run_day_summary.dart';
import '../runtime/ghost_item_lease.dart';

enum EndpointGameMode {
  classic,
  pattern,
}

enum EndpointRunRulesMode {
  fullHeal,
  hard,
}

enum EndpointLanguage {
  spanish('es'),
  english('en');

  final String code;

  const EndpointLanguage(this.code);

  static EndpointLanguage fromJsonValue(Object? value) {
    const defaultLanguage = EndpointLanguage.spanish;
    if (value is! String) return defaultLanguage;

    return EndpointLanguage.values.firstWhere(
      (language) => language.name == value || language.code == value,
      orElse: () => defaultLanguage,
    );
  }
}

class EndpointSettingsSnapshot {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final int animationSpeed;
  final bool customAvatarEnabled;
  final bool customAvatarSelectionEnabled;
  final EndpointGameMode gameMode;
  final EndpointRunRulesMode runRulesMode;
  final EndpointLanguage language;

  const EndpointSettingsSnapshot({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.animationSpeed,
    required this.customAvatarEnabled,
    required this.customAvatarSelectionEnabled,
    required this.gameMode,
    required this.runRulesMode,
    required this.language,
  });

  const EndpointSettingsSnapshot.defaults()
      : soundEnabled = true,
        vibrationEnabled = true,
        animationSpeed = 2,
        customAvatarEnabled = false,
        customAvatarSelectionEnabled = false,
        gameMode = EndpointGameMode.pattern,
        runRulesMode = EndpointRunRulesMode.fullHeal,
        language = EndpointLanguage.spanish;

  EndpointSettingsSnapshot copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? animationSpeed,
    bool? customAvatarEnabled,
    bool? customAvatarSelectionEnabled,
    EndpointGameMode? gameMode,
    EndpointRunRulesMode? runRulesMode,
    EndpointLanguage? language,
  }) {
    return EndpointSettingsSnapshot(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      animationSpeed: (animationSpeed ?? this.animationSpeed).clamp(1, 3),
      customAvatarEnabled: customAvatarEnabled ?? this.customAvatarEnabled,
      customAvatarSelectionEnabled:
          customAvatarSelectionEnabled ?? this.customAvatarSelectionEnabled,
      gameMode: gameMode ?? this.gameMode,
      runRulesMode: runRulesMode ?? this.runRulesMode,
      language: language ?? this.language,
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
      'runRulesMode': runRulesMode.name,
      'language': language.code,
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
      runRulesMode:
          EndpointRunRulesMode.values.cast<EndpointRunRulesMode?>().firstWhere(
                (mode) => mode?.name == json['runRulesMode'],
                orElse: () => defaultSettings.runRulesMode,
              )!,
      language: EndpointLanguage.fromJsonValue(json['language']),
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
        other.gameMode == gameMode &&
        other.runRulesMode == runRulesMode &&
        other.language == language;
  }

  @override
  int get hashCode => Object.hash(
        soundEnabled,
        vibrationEnabled,
        animationSpeed,
        customAvatarEnabled,
        customAvatarSelectionEnabled,
        gameMode,
        runRulesMode,
        language,
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
  final RunDaySummary runSummary;
  final RunDaySummary currentDaySummary;
  final RunDaySummary? pendingDaySummary;
  final List<String> shownShopNodeIds;
  final List<String> shownEventNodeIds;
  final int shopRarityDayOffset;
  final int eventRarityDayOffset;
  final GhostItemLease? ghostItemLease;
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
    this.runSummary = const RunDaySummary.empty(),
    this.currentDaySummary = const RunDaySummary.empty(),
    this.pendingDaySummary,
    this.shownShopNodeIds = const <String>[],
    this.shownEventNodeIds = const <String>[],
    this.shopRarityDayOffset = 0,
    this.eventRarityDayOffset = 0,
    this.ghostItemLease,
    this.activeNode,
  });

  int get nodeCount => max(
        1,
        savedNodeCount > 0 ? savedNodeCount : visibleNodes.length,
      );

  bool get canContinue =>
      !isRunComplete &&
      completionType == null &&
      (visibleNodes.isNotEmpty ||
          pendingDaySummary != null ||
          ghostItemLease != null);
}
