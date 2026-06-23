import '_imports.dart';

class WeaponShopController extends ChangeNotifier {
  static const defaultMaxRerolls = 1;

  final double priceMultiplier;
  final ShopInventoryCriterion _stockCriterion;
  final RunHourPhase _phase;
  final RunRandomizer _randomizer;
  final int _dayNumber;
  final List<Item> _stockPool;
  final WeaponShopStockService _stockService;
  final int maxRerolls;
  final RarityTier shopRarity;
  final List<Item> _stock;
  Battler _player;
  int _usedRerolls = 0;

  WeaponShopController({
    required Battler player,
    required ShopInventoryCriterion stockCriterion,
    required RunHourPhase phase,
    required RunRandomizer randomizer,
    required this.shopRarity,
    int dayNumber = 1,
    List<Item> stockPool = itemPresets,
    this.priceMultiplier = 1,
    this.maxRerolls = defaultMaxRerolls,
    WeaponShopStockService stockService = const WeaponShopStockService(),
  })  : _stockCriterion = stockCriterion,
        _phase = phase,
        _randomizer = randomizer,
        _dayNumber = dayNumber,
        _stockPool = stockPool,
        _stockService = stockService,
        _player = player.materializeOwnedItems(),
        _stock = List<Item>.from(
          stockService.buildInitialStock(
            criterion: stockCriterion,
            phase: phase,
            randomizer: randomizer,
            player: player,
            dayNumber: dayNumber,
            pool: stockPool,
          ),
        );

  Battler get player => _player;
  List<Item> get stock => List<Item>.unmodifiable(_stock);
  int get usedRerolls => _usedRerolls;
  int get rerollsRemaining => max(0, maxRerolls - _usedRerolls);
  int get rerollCost => 1 + shopRarity.factor;

  bool canBuy(Item item) =>
      _stock.contains(item) &&
      _player.canAfford(purchasePriceFor(item)) &&
      _player.canReceiveItem(item);

  bool get canRerollStock {
    if (rerollsRemaining <= 0 || !_player.canAfford(rerollCost)) {
      return false;
    }

    return _stockService.availableStockCount(
          criterion: _stockCriterion,
          phase: _phase,
          player: _player,
          dayNumber: _dayNumber,
          pool: _stockPool,
          excludedItemIds: _stock.map((item) => item.id).toSet(),
        ) >=
        WeaponShopStockService.defaultStockSize;
  }

  int purchasePriceFor(Item item) =>
      max(1, (item.cost * priceMultiplier).ceil());

  int sellPriceFor(Item item) => max(1, (purchasePriceFor(item) / 2).ceil());

  String stockStatusLabelFor(Item item) {
    if (!_stock.contains(item)) return 'Agotado';
    if (!_player.canReceiveItem(item)) return 'Inventario lleno';
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
    if (!_player.canReceiveItem(item)) {
      return 'Inventario lleno (${Battler.maxInventoryItems}/${Battler.maxInventoryItems})';
    }
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

    return 'Venta: ${sellPriceFor(item)}C.';
  }

  String inventoryActionLabelFor(Item item) {
    return 'Vender: ${sellPriceFor(item)}C';
  }

  bool canSell(Item item) => _player.ownsItem(item);

  String inventorySellTooltipFor(Item item) {
    if (!_player.ownsItem(item)) {
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

  bool canUnequip(Item item) =>
      _player.equippedItems.contains(item) && _player.hasInventorySpace;

  String inventorySecondaryActionTooltipFor(Item item) {
    final blockReason = _player.equipItemBlockReason(item);
    if (blockReason != null) {
      return blockReason;
    }

    final nextCost = _player.equippedItemCost + 1;
    return 'Equipar objeto al operativo ($nextCost/${_player.equipmentCapacity})';
  }

  String equippedSecondaryActionTooltipFor(Item item) {
    if (_player.inventoryItems.contains(item)) {
      return 'El objeto ya esta en tu inventario';
    }
    if (!_player.equippedItems.contains(item)) {
      return 'El objeto ya no esta equipado';
    }
    if (!_player.hasInventorySpace) {
      return 'Inventario lleno (${Battler.maxInventoryItems}/${Battler.maxInventoryItems})';
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

  bool rerollStock() {
    if (!canRerollStock) return false;

    final replacementStock = _buildRerollStock();
    if (replacementStock.length != WeaponShopStockService.defaultStockSize) {
      return false;
    }

    _player = _player.spendMoney(rerollCost);
    _stock
      ..clear()
      ..addAll(replacementStock);
    _usedRerolls++;
    notifyListeners();
    return true;
  }

  List<Item> _buildRerollStock() {
    return _stockService.buildInitialStock(
      criterion: _stockCriterion,
      phase: _phase,
      randomizer: _randomizer,
      player: _player,
      dayNumber: _dayNumber,
      pool: _stockPool,
      excludedItemIds: _stock.map((item) => item.id).toSet(),
    );
  }

  WeaponShopVisitResult buildResult() {
    return WeaponShopVisitResult(player: _player);
  }
}
