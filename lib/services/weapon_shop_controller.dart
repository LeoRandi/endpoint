import '_imports.dart';

class WeaponShopController extends ChangeNotifier {
  final double priceMultiplier;
  final List<Item> _stock;
  Battler _player;

  WeaponShopController({
    required Battler player,
    required ShopInventoryCriterion stockCriterion,
    required RunHourPhase phase,
    required RunRandomizer randomizer,
    List<Item> stockPool = itemPresets,
    this.priceMultiplier = 1,
    WeaponShopStockService stockService = const WeaponShopStockService(),
  })  : _player = player.materializeOwnedItems(),
        _stock = List<Item>.from(
          stockService.buildInitialStock(
            criterion: stockCriterion,
            phase: phase,
            randomizer: randomizer,
            pool: stockPool,
          ),
        );

  Battler get player => _player;
  List<Item> get stock => List<Item>.unmodifiable(_stock);

  bool canBuy(Item item) =>
      _stock.contains(item) && _player.canAfford(purchasePriceFor(item));

  int purchasePriceFor(Item item) =>
      max(1, (item.cost * priceMultiplier).ceil());

  int sellPriceFor(Item item) => item.sellValue;

  String stockStatusLabelFor(Item item) {
    if (!_stock.contains(item)) return 'Agotado';
    if (canBuy(item)) return 'Disponible';
    final missingMoney = max(0, purchasePriceFor(item) - _player.money);
    return 'Te faltan ${missingMoney}C';
  }

  String stockActionLabelFor(Item item) {
    if (!_stock.contains(item)) return 'Agotado';
    final verb = willUpgradeItem(item) ? 'Mejorar' : 'Comprar';
    return '$verb (${purchasePriceFor(item)}C)';
  }

  bool willUpgradeItem(Item item) => _player.wouldUpgradeItem(item);

  String stockPrimaryActionTooltipFor(Item item) {
    final price = purchasePriceFor(item);
    if (willUpgradeItem(item)) {
      return 'Mejorar objeto por $price creditos';
    }

    return 'Comprar objeto por $price creditos';
  }

  String inventoryStatusLabelFor(Item item) {
    if (_player.equippedItems.contains(item)) {
      return 'Estado actual: equipado. Para venderlo, primero desequipalo.';
    }
    if (!_player.inventoryItems.contains(item)) {
      return 'El objeto ya no esta en tu inventario.';
    }

    return 'Venta: ${sellPriceFor(item)}C. Coste de equipo: ${item.equipmentCost}.';
  }

  String inventoryActionLabelFor(Item item) {
    return 'Vender: ${sellPriceFor(item)}C';
  }

  bool canSell(Item item) => _player.inventoryItems.contains(item);

  String inventorySellTooltipFor(Item item) {
    if (_player.equippedItems.contains(item)) {
      return 'Desequipalo antes de venderlo';
    }
    if (!_player.inventoryItems.contains(item)) {
      return 'El objeto ya no esta disponible';
    }

    return 'Vender objeto en esta tienda';
  }

  String? inventorySecondaryActionLabelFor(Item item) {
    if (!canEquipFromInventory(item)) return null;
    return 'Equipar';
  }

  String equippedStatusLabelFor(Item item) {
    if (_player.equippedItems.contains(item)) {
      return 'Estado actual: equipado.';
    }
    if (_player.inventoryItems.contains(item)) {
      return 'Estado actual: en inventario.';
    }

    return 'El objeto ya no esta disponible.';
  }

  String? equippedSecondaryActionLabelFor(Item item) {
    if (!canUnequip(item)) return null;
    return 'Quitar';
  }

  bool canEquipFromInventory(Item item) {
    return _player.canEquipItem(item);
  }

  bool canUnequip(Item item) => _player.equippedItems.contains(item);

  String inventorySecondaryActionTooltipFor(Item item) {
    final blockReason = _player.equipItemBlockReason(item);
    if (blockReason != null) {
      return blockReason;
    }

    final nextCost = _player.equippedItemCost + item.equipmentCost;
    return 'Equipar objeto al operativo ($nextCost/${_player.equipmentCapacity})';
  }

  String equippedSecondaryActionTooltipFor(Item item) {
    if (_player.inventoryItems.contains(item)) {
      return 'El objeto ya esta en tu inventario';
    }
    if (!_player.equippedItems.contains(item)) {
      return 'El objeto ya no esta equipado';
    }

    return 'Quitar objeto del equipo activo';
  }

  void equipInventoryItem(Item item) {
    if (!canEquipFromInventory(item)) return;

    _player = _player.equipItem(item);
    notifyListeners();
  }

  void unequipItem(Item item) {
    if (!canUnequip(item)) return;

    _player = _player.unequipItem(item);
    notifyListeners();
  }

  void buyItem(Item item) {
    if (!canBuy(item)) return;

    _player = _player.spendMoney(purchasePriceFor(item)).addItem(item);
    _stock.remove(item);
    notifyListeners();
  }

  void sellItem(Item item) {
    if (!canSell(item)) return;

    _player = _player.earnMoney(sellPriceFor(item)).removeItem(item);
    _stock.add(item);
    notifyListeners();
  }

  WeaponShopVisitResult buildResult() {
    return WeaponShopVisitResult(player: _player);
  }
}
