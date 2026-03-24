import '_imports.dart';

class WeaponShopController extends ChangeNotifier {
  final List<Item> catalog;
  final double priceMultiplier;
  Battler _player;

  WeaponShopController({
    required Battler player,
    required List<Item> catalog,
    this.priceMultiplier = 1,
  })  : _player = player,
        catalog = List<Item>.unmodifiable(catalog);

  Battler get player => _player;

  bool ownsItem(Item item) => _player.ownsItem(item);
  bool isItemEquipped(Item item) => _player.equippedItems.contains(item);
  bool isItemInInventory(Item item) => _player.inventoryItems.contains(item);
  int costFor(Item item) => max(1, (item.cost * priceMultiplier).round());
  bool canAfford(Item item) => _player.canAfford(costFor(item));

  String availabilityLabelFor(Item item) {
    if (isItemEquipped(item)) return 'Equipado';
    if (isItemInInventory(item)) return 'Inventario';
    if (canAfford(item)) return 'Disponible';
    return 'Sin fondos';
  }

  String detailStatusLabelFor(Item item) {
    if (isItemEquipped(item)) return 'Estado actual: equipado';
    if (isItemInInventory(item)) return 'Estado actual: en inventario';
    if (canAfford(item)) return 'Credito suficiente para comprar';
    final missingMoney = max(0, costFor(item) - _player.money);
    return 'Te faltan ${missingMoney}C';
  }

  String actionLabelFor(Item item) {
    if (!ownsItem(item)) return canAfford(item) ? 'Comprar' : 'Sin fondos';
    if (!item.isEquippable) return 'Disponible';
    if (isItemEquipped(item)) return 'Quitar';
    if (isItemInInventory(item)) return 'Equipar';
    return 'Comprar';
  }

  bool isActionEnabled(Item item) {
    if (!ownsItem(item)) return canAfford(item);
    if (!item.isEquippable && ownsItem(item)) return false;
    return true;
  }

  void handlePrimaryAction(Item item) {
    if (!isActionEnabled(item)) return;

    if (!ownsItem(item)) {
      _player = _player.spendMoney(costFor(item)).addItem(item);
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
