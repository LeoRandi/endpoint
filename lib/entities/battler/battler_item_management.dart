part of 'battler.dart';

extension BattlerItemManagement on Battler {
  /// Comprueba si el battler posee exactamente esa instancia de item.
  bool ownsItem(Item item) {
    return inventoryItems.contains(item) || equippedItems.contains(item);
  }

  /// Comprueba si el battler posee algun item de ese tipo, equipado o en inventario.
  bool ownsItemOfType(ItemId itemId) {
    return _derivedState.inventoryItemsByType.containsKey(itemId) ||
        _derivedState.equippedItemsByType.containsKey(itemId);
  }

  /// Indica si recibir este item acabaria mejorando una copia ya poseida.
  bool wouldUpgradeItem(Item item) {
    return _upgradeableEquippedItemFor(item) != null ||
        _upgradeableInventoryItemFor(item) != null;
  }

  /// Indica si hay algun item equipado con hooks de efecto.
  bool get hasItemEffects => _derivedState.hasItemEffects;

  /// Explica por que un objeto no puede equiparse en el estado actual del battler.
  String? equipItemBlockReason(Item item) {
    if (!item.isEquippable) return 'Este objeto no se puede equipar';
    if (equippedItems.contains(item)) return 'El objeto ya esta equipado';
    if (!inventoryItems.contains(item)) {
      return 'El objeto ya no esta en tu inventario';
    }

    final nextCost = equippedItemCost + 1;
    if (nextCost > equipmentCapacity) {
      return 'Capacidad insuficiente: $nextCost/$equipmentCapacity';
    }

    return null;
  }

  /// Indica si el objeto cabe dentro de la capacidad de equipo disponible.
  bool canEquipItem(Item item) => equipItemBlockReason(item) == null;

  /// Indica si el inventario todavia admite un objeto nuevo.
  bool get hasInventorySpace =>
      inventoryItems.length < Battler.maxInventoryItems;

  /// Indica si recibir este item entraria en inventario o mejoraria una copia existente.
  bool canReceiveItem(Item item) => wouldUpgradeItem(item) || hasInventorySpace;

  /// Indica si recibir este item entraria en inventario, equipo o mejora.
  bool canReceiveItemInInventoryOrEquipment(Item item) {
    return canReceiveItem(item) ||
        (item.isEquippable && remainingEquipmentCapacity >= 1);
  }

  /// Devuelve solo los items equipados que declararon el hook pedido en su efecto.
  List<Item> equippedItemsForHook(ItemEffectHook hook) {
    return _derivedState.equippedItemsByHook[hook] ?? const <Item>[];
  }

  /// Anade un item nuevo o mejora la copia ya poseida si admite upgrades.
  Battler addItem(Item item) {
    if (!CodexDiscoveryHook.isSuppressed) {
      CodexDiscoveryHook.onItemAdded?.call(item.id);
    }
    final ownedEquippedItem = _upgradeableEquippedItemFor(item);
    if (ownedEquippedItem != null) {
      final updatedEquippedItems = List<Item>.from(equippedItems);
      final existingIndex = updatedEquippedItems.indexOf(ownedEquippedItem);
      updatedEquippedItems[existingIndex] = ownedEquippedItem.upgraded();
      return copyWith(
        equippedItems: List<Item>.unmodifiable(updatedEquippedItems),
      );
    }

    final ownedInventoryItem = _upgradeableInventoryItemFor(item);
    if (ownedInventoryItem != null) {
      final updatedInventoryItems = List<Item>.from(inventoryItems);
      final existingIndex = updatedInventoryItems.indexOf(ownedInventoryItem);
      updatedInventoryItems[existingIndex] = ownedInventoryItem.upgraded();
      return copyWith(
        inventoryItems: List<Item>.unmodifiable(updatedInventoryItems),
      );
    }

    if (!hasInventorySpace) return this;

    return copyWith(
      inventoryItems: List<Item>.unmodifiable([
        ...inventoryItems,
        item.toOwnedInstance(),
      ]),
    );
  }

  /// Anade un item nuevo, usando equipo libre si no queda inventario.
  Battler addItemToInventoryOrEquipment(Item item) {
    if (canReceiveItem(item)) return addItem(item);

    if (!item.isEquippable || remainingEquipmentCapacity < 1) return this;
    if (!CodexDiscoveryHook.isSuppressed) {
      CodexDiscoveryHook.onItemAdded?.call(item.id);
    }

    return copyWith(
      equippedItems: List<Item>.unmodifiable([
        ...equippedItems,
        item.toOwnedInstance(),
      ]),
    );
  }

  Item? _upgradeableEquippedItemFor(Item receivedItem) {
    for (final ownedItem in equippedItems) {
      if (_canUpgradeOwnedItemWith(
        ownedItem: ownedItem,
        receivedItem: receivedItem,
      )) {
        return ownedItem;
      }
    }

    return null;
  }

  Item? _upgradeableInventoryItemFor(Item receivedItem) {
    for (final ownedItem in inventoryItems) {
      if (_canUpgradeOwnedItemWith(
        ownedItem: ownedItem,
        receivedItem: receivedItem,
      )) {
        return ownedItem;
      }
    }

    return null;
  }

  bool _canUpgradeOwnedItemWith({
    required Item ownedItem,
    required Item receivedItem,
  }) {
    return ownedItem.id == receivedItem.id &&
        ownedItem.rarity == receivedItem.rarity &&
        ownedItem.canUpgrade;
  }

  /// Elimina un item del battler, desequipandolo antes si hace falta.
  Battler removeItem(Item item) {
    if (equippedItems.contains(item)) {
      return unequipItem(item).removeItem(item);
    }
    if (!inventoryItems.contains(item)) return this;

    final updatedInventoryItems = List<Item>.from(inventoryItems)..remove(item);
    return copyWith(
      inventoryItems: List<Item>.unmodifiable(updatedInventoryItems),
    );
  }

  /// Busca en inventario el primer item de un tipo concreto.
  Item? inventoryItemOfType(ItemId itemId) {
    return _derivedState.inventoryItemsByType[itemId];
  }

  /// Busca entre los items equipados el primero de un tipo concreto.
  Item? equippedItemOfType(ItemId itemId) {
    return _derivedState.equippedItemsByType[itemId];
  }

  /// Convierte todos los items poseidos en instancias propias para poder diferenciarlos.
  Battler materializeOwnedItems() {
    final hasOnlyInstancedItems =
        inventoryItems.every((item) => item.isInstanced) &&
            equippedItems.every((item) => item.isInstanced);
    if (hasOnlyInstancedItems) return this;

    return copyWith(
      inventoryItems: inventoryItems
          .map((item) => item.toOwnedInstance())
          .toList(growable: false),
      equippedItems: equippedItems
          .map((item) => item.toOwnedInstance())
          .toList(growable: false),
    );
  }

  /// Equipa un item del inventario si cabe dentro de la capacidad disponible.
  Battler equipItem(Item item) {
    if (!canEquipItem(item)) return this;

    final updatedInventoryItems = List<Item>.from(inventoryItems)..remove(item);
    final updatedEquippedItems = List<Item>.from(equippedItems);
    updatedEquippedItems.add(item);

    return copyWith(
      inventoryItems: List<Item>.unmodifiable(updatedInventoryItems),
      equippedItems: List<Item>.unmodifiable(updatedEquippedItems),
    );
  }

  /// Devuelve un item equipado al inventario sin alterar el resto del equipo.
  Battler unequipItem(Item item) {
    if (!equippedItems.contains(item)) return this;
    if (!hasInventorySpace) return this;

    final updatedEquippedItems = List<Item>.from(equippedItems)..remove(item);
    final updatedInventoryItems = List<Item>.from(inventoryItems)..add(item);

    return copyWith(
      inventoryItems: List<Item>.unmodifiable(updatedInventoryItems),
      equippedItems: List<Item>.unmodifiable(updatedEquippedItems),
    );
  }
}
