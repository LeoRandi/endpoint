import '_imports.dart';

/// Item catalog, intentionally empty while the new item set is designed.
const List<Item> itemPresets = <Item>[];

/// Stable catalog lookup populated alongside [itemPresets].
final Map<String, Item> itemPresetRegistry = Map<String, Item>.unmodifiable({
  for (final item in itemPresets) item.catalogKey: item,
});
