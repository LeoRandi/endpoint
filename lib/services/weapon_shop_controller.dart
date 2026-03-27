import '_imports.dart';

class WeaponShopController extends ChangeNotifier {
  final double priceMultiplier;
  final List<Item> _stock;
  Battler _player;

  WeaponShopController({
    required Battler player,
    required ShopInventoryCriterion stockCriterion,
    required RunRandomizer randomizer,
    this.priceMultiplier = 1,
    WeaponShopStockService stockService = const WeaponShopStockService(),
  })  : _player = player.materializeOwnedItems(),
        _stock = List<Item>.from(
          stockService.buildInitialStock(
            criterion: stockCriterion,
            randomizer: randomizer,
          ),
        );

  Battler get player => _player;
  List<Item> get stock => List<Item>.unmodifiable(_stock);

  bool canBuy(Item item) =>
      _stock.contains(item) && _player.canAfford(purchasePriceFor(item));

  int purchasePriceFor(Item item) =>
      max(1, (item.cost * priceMultiplier).ceil());

  int sellPriceFor(Item item) => max(1, (item.cost / 2).ceil());

  String stockStatusLabelFor(Item item) {
    if (!_stock.contains(item)) return 'Agotado';
    if (canBuy(item)) return 'Disponible';
    final missingMoney = max(0, purchasePriceFor(item) - _player.money);
    return 'Te faltan ${missingMoney}C';
  }

  String stockActionLabelFor(Item item) {
    if (!_stock.contains(item)) return 'Agotado';
    if (canBuy(item)) return 'Comprar (${purchasePriceFor(item)}C)';
    return 'Sin fondos (${purchasePriceFor(item)}C)';
  }

  String inventoryStatusLabelFor(Item item) {
    if (!_player.inventoryItems.contains(item)) {
      return 'El objeto ya no esta en tu inventario.';
    }

    return 'Valor de venta en esta tienda: ${sellPriceFor(item)}C.';
  }

  String inventoryActionLabelFor(Item item) {
    return 'Vender: ${sellPriceFor(item)}C';
  }

  bool canSell(Item item) => _player.inventoryItems.contains(item);

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
