import '_imports.dart';

class PathNodeService {
  final Random _random;

  PathNodeService({
    int? seed,
  }) : _random = seed == null ? Random() : Random(seed);

  List<PathNode> rollNodes({
    required List<PathNode> availableNodes,
    required int nodeCount,
  }) {
    if (availableNodes.isEmpty) {
      throw StateError('PathNodeService requires at least one available node.');
    }
    if (nodeCount <= 0) {
      throw ArgumentError.value(nodeCount, 'nodeCount', 'nodeCount must be positive.');
    }

    // TODO: Add weighted rolls and progression-aware pools if routes become chapter based.
    return List<PathNode>.generate(
      nodeCount,
      (_) => availableNodes[_random.nextInt(availableNodes.length)],
    );
  }
}
