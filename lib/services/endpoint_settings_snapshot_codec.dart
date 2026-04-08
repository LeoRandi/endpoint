import 'dart:convert';

import 'endpoint_json_utils.dart';
import 'endpoint_preferences_models.dart';

abstract final class EndpointSettingsSnapshotCodec {
  static const JsonEncoder _jsonEncoder = JsonEncoder.withIndent('  ');

  static String encode(EndpointSettingsSnapshot settings) {
    final payload = <String, Object?>{
      'schemaVersion': 1,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'settings': settings.toJson(),
    };

    return _jsonEncoder.convert(payload);
  }

  static EndpointSettingsSnapshot? decode(String rawValue) {
    final decoded = jsonDecode(rawValue);
    final rootJson = EndpointJsonUtils.asJsonMap(decoded);
    if (rootJson == null) return null;

    final settingsJson = EndpointJsonUtils.asJsonMap(rootJson['settings']);
    if (settingsJson == null) return null;

    return EndpointSettingsSnapshot.fromJson(settingsJson);
  }
}
