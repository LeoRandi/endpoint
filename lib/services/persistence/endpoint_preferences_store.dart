import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class EndpointPreferencesStore {
  static Future<void> _writeQueue = Future<void>.value();

  static Future<String?> readString(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  static Future<void> writeString({
    required String key,
    required String rawValue,
  }) {
    final pendingWrite = _writeQueue.then((_) async {
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(key, rawValue);
      } catch (error, stackTrace) {
        debugPrint(
          'No se pudo guardar la preferencia local "$key": '
          '$error\n$stackTrace',
        );
      }
    });
    _writeQueue = pendingWrite;
    return pendingWrite;
  }

  static Future<void> remove(String key) {
    final pendingRemove = _writeQueue.then((_) async {
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove(key);
      } catch (error, stackTrace) {
        debugPrint(
          'No se pudo borrar la preferencia local "$key": '
          '$error\n$stackTrace',
        );
      }
    });
    _writeQueue = pendingRemove;
    return pendingRemove;
  }
}
