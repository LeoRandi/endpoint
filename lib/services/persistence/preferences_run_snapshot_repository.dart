import '../run/run_snapshot_repository.dart';
import 'endpoint_preferences_service.dart';

class PreferencesRunSnapshotRepository implements RunSnapshotRepository {
  const PreferencesRunSnapshotRepository();

  @override
  Future<void> save(RunSnapshotWriteRequest request) {
    return EndpointPreferencesService.saveCurrentRunSnapshot(
      state: request.state,
      randomizer: request.randomizer,
      isResolvingNode: request.isResolvingNode,
      trigger: request.trigger,
      nodeCount: request.nodeCount,
      activeNode: request.activeNode,
    );
  }

  @override
  Future<void> clear() {
    return EndpointPreferencesService.clearCurrentRunSnapshot();
  }
}
