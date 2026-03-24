import '_imports.dart';

class PathNodeService {
  static const startStageIndex = 0;
  static const duskStageIndex = 5;
  static const sunriseStageIndex = 11;

  final Random _random;

  PathNodeService({
    int? seed,
  }) : _random = seed == null ? Random() : Random(seed);

  RunHourSnapshot buildHourSnapshot({
    required int stageIndex,
  }) {
    final clampedStageIndex = stageIndex.clamp(
      startStageIndex,
      sunriseStageIndex,
    );

    if (clampedStageIndex < duskStageIndex) {
      return RunHourSnapshot(
        stageIndex: clampedStageIndex,
        phase: RunHourPhase.day,
        title: 'HORA $clampedStageIndex',
        subtitle: 'Mercados y favores tensos antes del anochecer.',
        nodes: List<PathNode>.unmodifiable(_buildDayNodes()),
      );
    }

    if (clampedStageIndex == duskStageIndex) {
      return RunHourSnapshot(
        stageIndex: clampedStageIndex,
        phase: RunHourPhase.dusk,
        title: 'ANOCHECER',
        subtitle:
            'La ciudad se cierra. Tres enfrentamientos marcan la entrada en la noche.',
        nodes: List<PathNode>.unmodifiable(duskCombatNodes),
      );
    }

    if (clampedStageIndex < sunriseStageIndex) {
      return RunHourSnapshot(
        stageIndex: clampedStageIndex,
        phase: RunHourPhase.night,
        title: 'NOCHE ${clampedStageIndex - duskStageIndex}',
        subtitle: 'Más violencia, peores tratos y menos margen de error.',
        nodes: List<PathNode>.unmodifiable(_buildNightNodes()),
      );
    }

    return RunHourSnapshot(
      stageIndex: clampedStageIndex,
      phase: RunHourPhase.sunrise,
      title: 'SUNRISE',
      subtitle: 'Solo queda un combate. El peor de toda la run.',
      nodes: List<PathNode>.unmodifiable(sunriseCombatNodes.take(1)),
    );
  }

  List<PathNode> _buildDayNodes() {
    return List<PathNode>.generate(3, (_) {
      final roll = _random.nextDouble();
      if (roll < 0.06) return _pick(rareDayCombatNodes);
      if (roll < 0.28) return _pick(dayEventNodes);
      if (roll < 0.38) return dayCampNode;
      return _pick(dayShopNodes);
    });
  }

  List<PathNode> _buildNightNodes() {
    return List<PathNode>.generate(3, (_) {
      final roll = _random.nextDouble();
      if (roll < 0.58) return _pick(nightCombatNodes);
      if (roll < 0.8) return _pick(nightShopNodes);
      return _pick(nightEventNodes);
    });
  }

  T _pick<T>(List<T> values) {
    if (values.isEmpty) {
      throw StateError('Cannot pick from an empty node list.');
    }
    return values[_random.nextInt(values.length)];
  }
}
