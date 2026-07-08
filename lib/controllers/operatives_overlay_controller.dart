import '../entities/_exports.dart';
import 'controller_ui_text.dart';
import 'package:flutter/foundation.dart';

/// Orquesta la seleccion de operativos y el intercambio de equipo dentro del overlay de operativos.
class OperativesOverlayController extends ChangeNotifier {
  static const _playerOperativeIndex = 0;

  final List<Battler> _companions;
  final ValueChanged<Battler>? onPlayerChanged;
  int _selectedIndex = _playerOperativeIndex;
  Battler _player;

  /// Crea el controlador del overlay y materializa los items poseidos por el jugador.
  OperativesOverlayController({
    required Battler player,
    List<Battler> companions = const [],
    this.onPlayerChanged,
  })  : _player = player.materializeOwnedItems(),
        _companions = List<Battler>.unmodifiable(companions);

  /// Expone el jugador actual tras cualquier cambio de equipo.
  Battler get player => _player;

  /// Expone el indice seleccionado para que la vista pinte el operativo activo.
  int get selectedIndex => _selectedIndex;

  /// Devuelve la lista completa de operativos visibles, con el jugador siempre en primer lugar.
  List<Battler> get operatives => [_player, ..._companions];

  /// Devuelve el operativo actualmente seleccionado en el overlay.
  Battler get selectedOperative {
    if (_selectedIndex == _playerOperativeIndex) return _player;
    return _companions[_selectedIndex - 1];
  }

  /// Indica si el operativo seleccionado coincide con el jugador editable.
  bool get isPlayerSelected => _selectedIndex == _playerOperativeIndex;

  /// Devuelve el mayor indice seleccionable con la lista actual de operativos.
  int get _lastOperativeIndex => _companions.length;

  /// Actualiza la seleccion activa del overlay y notifica solo cuando cambia de verdad.
  void selectOperative(int index) {
    if (index < _playerOperativeIndex || index > _lastOperativeIndex) return;
    if (_selectedIndex == index) return;

    _selectedIndex = index;
    notifyListeners();
  }

  /// Devuelve el texto de estado visible para un item dentro del contexto actual del overlay.
  String statusLabelFor(Item item) {
    return statusLabelForOwner(_player, item);
  }

  /// Devuelve el texto de estado visible para un item perteneciente a un battler concreto.
  String statusLabelForOwner(Battler owner, Item item) {
    return ControllerUiText.itemStatusLabel(owner: owner, item: item);
  }

  /// Devuelve la accion primaria visible para un item del jugador dentro del overlay.
  String? actionLabelFor(Item item) {
    return actionPresentationFor(item).actionLabel;
  }

  /// Devuelve todas las decisiones visibles de la accion primaria del item.
  ControllerItemActionPresentation actionPresentationFor(Item item) {
    return ControllerUiText.itemToggleActionPresentation(
      owner: _player,
      item: item,
    );
  }

  /// Devuelve la accion de venta rapida disponible durante la seleccion de nodo.
  String? sellActionLabelFor(Item item) {
    if (!_player.inventoryItems.contains(item)) return null;
    return 'Sell (${quickSellValueFor(item)})';
  }

  /// Devuelve el pago reducido de venta rapida fuera de tienda.
  int quickSellValueFor(Item item) => item.sellValue;

  /// Indica si la accion primaria del dialogo del jugador esta disponible.
  bool isActionEnabled(Item item) {
    return actionPresentationFor(item).isActionEnabled;
  }

  /// Explica la accion primaria disponible para un item del jugador.
  String enabledActionTooltipFor(Item item) {
    return actionPresentationFor(item).enabledActionTooltip;
  }

  /// Explica por que un item del jugador no admite accion primaria.
  String disabledActionTooltipFor(Item item) {
    return actionPresentationFor(item).disabledActionTooltip;
  }

  /// Devuelve la etiqueta del boton de quitar cuando el item equipado puede volver al inventario.
  String? unequipActionLabelFor(
    Battler owner,
    Item item,
    bool canUnequip,
  ) {
    return unequipActionPresentationFor(owner, item, canUnequip).actionLabel;
  }

  /// Devuelve las decisiones visibles de quitar un item equipado.
  ControllerItemActionPresentation unequipActionPresentationFor(
    Battler owner,
    Item item,
    bool canUnequip,
  ) {
    return ControllerUiText.equippedItemActionPresentation(
      owner: owner,
      item: item,
      canUnequip: canUnequip,
    );
  }

  /// Indica si un item equipado puede quitarse desde el dialogo actual.
  bool isUnequipEnabled(
    Battler owner,
    Item item,
    bool canUnequip,
  ) {
    return unequipActionPresentationFor(
      owner,
      item,
      canUnequip,
    ).isActionEnabled;
  }

  /// Alterna equipar o quitar un item del jugador y propaga el cambio al consumidor externo.
  void handlePrimaryAction(Item item) {
    final updatedPlayer = _player.equippedItems.contains(item)
        ? _player.unequipItem(item)
        : _player.canEquipItem(item)
            ? _player.equipItem(item)
            : _player;

    _replacePlayer(updatedPlayer);
  }

  /// Equipa un item desde inventario y confirma si el estado ha cambiado.
  bool equipInventoryItem(Item item) {
    if (!_player.canEquipItem(item)) return false;

    _replacePlayer(_player.equipItem(item));
    return true;
  }

  /// Quita un item del jugador solo si sigue equipado en el estado actual.
  void handleUnequipItem(Item item) {
    unequipEquippedItem(item);
  }

  /// Devuelve un item equipado al inventario y confirma si el estado ha cambiado.
  bool unequipEquippedItem(Item item) {
    if (!_player.equippedItems.contains(item)) return false;

    _replacePlayer(_player.unequipItem(item));
    return true;
  }

  /// Vende permanentemente un item del inventario durante la seleccion de nodo.
  bool sellInventoryItem(Item item) {
    if (!_player.inventoryItems.contains(item)) return false;

    _replacePlayer(
      _player.removeItem(item).earnMoney(quickSellValueFor(item)),
    );
    return true;
  }

  /// Sustituye el jugador cuando un modo secundario necesita persistir estado propio.
  void replacePlayer(Battler updatedPlayer) {
    _replacePlayer(updatedPlayer);
  }

  /// Sustituye el jugador interno, conserva la seleccion valida y notifica el cambio una sola vez.
  void _replacePlayer(Battler updatedPlayer) {
    if (identical(_player, updatedPlayer)) return;

    _player = updatedPlayer;
    if (_selectedIndex > _lastOperativeIndex) {
      _selectedIndex = _lastOperativeIndex;
    }
    onPlayerChanged?.call(updatedPlayer);
    notifyListeners();
  }
}
