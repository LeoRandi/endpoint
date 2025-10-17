import 'package:hive_flutter/hive_flutter.dart';
import '../data/save_data.dart';

class SaveService {
  static const _boxName = 'endpoint_save';

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SaveDataAdapter());
    }
    await Hive.openBox<SaveData>(_boxName);
  }

  static Box<SaveData> get _box => Hive.box<SaveData>(_boxName);

  static Future<void> save(SaveData data) async {
    await _box.put('slot_1', data);
  }

  static SaveData? load() {
    return _box.get('slot_1');
  }

  static Future<void> clear() async {
    await _box.delete('slot_1');
  }

  static bool hasSave() => _box.containsKey('slot_1');
}
