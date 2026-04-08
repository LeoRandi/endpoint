import '../entities/_exports.dart';
import 'endpoint_current_run_snapshot_codec.dart';
import 'endpoint_preferences_models.dart';
import 'endpoint_preferences_store.dart';
import 'endpoint_settings_snapshot_codec.dart';
import 'run_randomizer.dart';
import 'run_state.dart';
import 'package:flutter/foundation.dart';

abstract final class EndpointPreferencesService {
  static const String currentRunPreferenceKey = 'endpoint.current_run';
  static const String settingsPreferenceKey = 'endpoint.settings';

  static Future<void> saveCurrentRunSnapshot({
    required RunState state,
    required RunRandomizer randomizer,
    required bool isResolvingNode,
    required String trigger,
    PathNode? activeNode,
  }) {
    return EndpointPreferencesStore.writeString(
      key: currentRunPreferenceKey,
      rawValue: EndpointCurrentRunSnapshotCodec.encode(
        state: state,
        randomizer: randomizer,
        isResolvingNode: isResolvingNode,
        trigger: trigger,
        activeNode: activeNode,
      ),
    );
  }

  static Future<EndpointCurrentRunSnapshot?> loadCurrentRunSnapshot() async {
    try {
      final rawValue = await EndpointPreferencesStore.readString(
        currentRunPreferenceKey,
      );
      if (rawValue == null || rawValue.trim().isEmpty) {
        return null;
      }

      final snapshot = EndpointCurrentRunSnapshotCodec.decode(rawValue);
      if (snapshot == null) return null;
      if (!snapshot.canContinue) {
        await clearCurrentRunSnapshot();
        return null;
      }

      return snapshot;
    } catch (error, stackTrace) {
      debugPrint(
        'No se pudo cargar la run local guardada: $error\n$stackTrace',
      );
      return null;
    }
  }

  static Future<void> clearCurrentRunSnapshot() {
    return EndpointPreferencesStore.remove(currentRunPreferenceKey);
  }

  static Future<void> saveSettingsSnapshot(
    EndpointSettingsSnapshot settings,
  ) {
    return EndpointPreferencesStore.writeString(
      key: settingsPreferenceKey,
      rawValue: EndpointSettingsSnapshotCodec.encode(settings),
    );
  }

  static Future<EndpointSettingsSnapshot> loadSettingsSnapshot() async {
    try {
      final rawValue = await EndpointPreferencesStore.readString(
        settingsPreferenceKey,
      );
      if (rawValue == null || rawValue.trim().isEmpty) {
        return const EndpointSettingsSnapshot.defaults();
      }

      return EndpointSettingsSnapshotCodec.decode(rawValue) ??
          const EndpointSettingsSnapshot.defaults();
    } catch (error, stackTrace) {
      debugPrint(
        'No se pudieron cargar los settings locales: $error\n$stackTrace',
      );
      return const EndpointSettingsSnapshot.defaults();
    }
  }
}
