import '../../entities/_exports.dart';
import 'run_randomizer.dart';
import 'run_state.dart';

class RunSnapshotWriteRequest {
  final RunState state;
  final RunRandomizer randomizer;
  final bool isResolvingNode;
  final String trigger;
  final int nodeCount;
  final PathNode? activeNode;

  const RunSnapshotWriteRequest({
    required this.state,
    required this.randomizer,
    required this.isResolvingNode,
    required this.trigger,
    required this.nodeCount,
    this.activeNode,
  });
}

abstract interface class RunSnapshotRepository {
  Future<void> save(RunSnapshotWriteRequest request);
  Future<void> clear();
}

class NoopRunSnapshotRepository implements RunSnapshotRepository {
  const NoopRunSnapshotRepository();

  @override
  Future<void> save(RunSnapshotWriteRequest request) => Future<void>.value();

  @override
  Future<void> clear() => Future<void>.value();
}
