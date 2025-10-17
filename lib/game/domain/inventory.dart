import 'item.dart';

class Inventory {
  final List<Item> items = [];
  void add(Item item) => items.add(item);
  bool remove(Item item) => items.remove(item);
}
