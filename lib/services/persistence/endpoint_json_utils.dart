abstract final class EndpointJsonUtils {
  static Map<String, dynamic>? asJsonMap(Object? rawValue) {
    if (rawValue is Map<String, dynamic>) return rawValue;
    if (rawValue is! Map) return null;

    return rawValue.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  static List<Map<String, dynamic>> readJsonMapList(Object? rawValue) {
    if (rawValue is! List) return const <Map<String, dynamic>>[];

    return rawValue
        .map<Map<String, dynamic>?>((entry) => asJsonMap(entry))
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  static Map<String, String> readStringMap(Object? rawValue) {
    final jsonMap = asJsonMap(rawValue);
    if (jsonMap == null) return const <String, String>{};

    return Map<String, String>.unmodifiable({
      for (final entry in jsonMap.entries)
        if (entry.value is String) entry.key: entry.value as String,
    });
  }

  static bool readBool(
    Object? rawValue, {
    required bool fallback,
  }) {
    return rawValue is bool ? rawValue : fallback;
  }

  static int readInt(
    Object? rawValue, {
    required int fallback,
  }) {
    return rawValue is int ? rawValue : fallback;
  }

  static double readDouble(
    Object? rawValue, {
    required double fallback,
  }) {
    if (rawValue is double) return rawValue;
    if (rawValue is int) return rawValue.toDouble();
    return fallback;
  }

  static String readString(
    Object? rawValue, {
    required String fallback,
  }) {
    return rawValue is String ? rawValue : fallback;
  }

  static String? readNullableString(Object? rawValue) {
    return rawValue is String && rawValue.isNotEmpty ? rawValue : null;
  }

  static int? readNullableInt(Object? rawValue) {
    return rawValue is int ? rawValue : null;
  }

  static T? parseEnumByName<T extends Enum>(List<T> values, Object? rawValue) {
    if (rawValue is! String) return null;

    for (final value in values) {
      if (value.name == rawValue) {
        return value;
      }
    }

    return null;
  }
}
