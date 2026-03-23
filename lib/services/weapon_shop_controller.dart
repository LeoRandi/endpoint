import '_imports.dart';

class WeaponShopController extends ChangeNotifier {
  final List<Item> catalog;
  Battler _player;

  WeaponShopController({
    required Battler player,
    required List<Item> catalog,
  })  : _player = player,
        catalog = List<Item>.unmodifiable(catalog);

  Battler get player => _player;

  bool ownsItem(Item item) => _player.ownsItem(item);
  bool isItemEquipped(Item item) => _player.equippedItems.contains(item);
  bool isItemInInventory(Item item) => _player.inventoryItems.contains(item);

  String actionLabelFor(Item item) {
    if (!item.isEquippable) return ownsItem(item) ? 'Disponible' : 'Adquirir';
    if (isItemEquipped(item)) return 'Quitar';
    if (isItemInInventory(item)) return 'Equipar';
    return 'Adquirir';
  }

  bool isActionEnabled(Item item) {
    if (!item.isEquippable && ownsItem(item)) return false;
    return true;
  }

  void handlePrimaryAction(Item item) {
    if (!isActionEnabled(item)) return;

    if (!ownsItem(item)) {
      // TODO: Replace free acquisition with a real shop economy and rotating stock.
      _player = _player.addItem(item);
      notifyListeners();
      return;
    }

    if (item.isEquippable) {
      _player = isItemEquipped(item)
          ? _player.unequipItem(item)
          : _player.equipItem(item);
      notifyListeners();
    }
  }

  WeaponShopVisitResult buildResult() {
    return WeaponShopVisitResult(player: _player);
  }
}
