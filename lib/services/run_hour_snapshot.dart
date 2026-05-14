import '../entities/_exports.dart';

enum RunHourPhase {
  day,
  dusk,
  night,
  sunrise,
}

class RunHourSnapshot {
  final int stageIndex;
  final RunHourPhase phase;
  final String title;
  final String subtitle;
  final List<PathNode> nodes;

  const RunHourSnapshot({
    required this.stageIndex,
    required this.phase,
    required this.title,
    required this.subtitle,
    required this.nodes,
  });

  bool get isFinalStage => phase == RunHourPhase.sunrise;
}
