import '../_imports.dart';

const _operativeTileExtent = 70.0;
const _operativeTileHeight = 84.0;

class OperativesOverlay extends StatefulWidget {
  final Battler player;
  final List<Battler> companions;
  final ValueChanged<Battler>? onPlayerChanged;

  const OperativesOverlay({
    super.key,
    required this.player,
    this.companions = const [],
    this.onPlayerChanged,
  });

  @override
  State<OperativesOverlay> createState() => _OperativesOverlayState();
}

class _OperativesOverlayState extends State<OperativesOverlay> {
  int _selectedIndex = 0;
  late Battler _player;

  @override
  void initState() {
    super.initState();
    _player = widget.player.materializeOwnedItems();
  }

  List<Battler> get _operatives => [_player, ...widget.companions];
  Battler get _selectedOperative => _operatives[_selectedIndex];
  bool get _isPlayerSelected => _selectedIndex == 0;

  Future<void> _openItemDetails(Item item) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de objeto',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return EndpointItemDetailsDialog(
              item: item,
              accent: item.rarity.accent,
              price: item.cost,
              statusText: _statusLabelFor(item),
              actionLabel: _actionLabelFor(item),
              onPrimaryAction: _isActionEnabled(item)
                  ? () {
                      _handlePrimaryAction(item);
                      setDialogState(() {});
                    }
                  : null,
              isActionEnabled: _isActionEnabled(item),
              enabledActionTooltip: _enabledActionTooltipFor(item),
              disabledActionTooltip: _disabledActionTooltipFor(item),
            );
          },
        );
      },
    );
  }

  Future<void> _openEquippedItemDetails(
    Item item, {
    required Battler owner,
    required bool canUnequip,
  }) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de objeto equipado',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final detailBattler = canUnequip ? _player : owner;

            return EndpointItemDetailsDialog(
              item: item,
              accent: item.rarity.accent,
              price: item.cost,
              statusText: _statusLabelForOwner(detailBattler, item),
              actionLabel:
                  _unequipActionLabelFor(detailBattler, item, canUnequip),
              onPrimaryAction:
                  _isUnequipEnabled(detailBattler, item, canUnequip)
                      ? () {
                          _handleUnequipItem(item);
                          setDialogState(() {});
                        }
                      : null,
              isActionEnabled:
                  _isUnequipEnabled(detailBattler, item, canUnequip),
              enabledActionTooltip: 'Quitar objeto del equipo activo',
              disabledActionTooltip: 'El objeto ya no esta equipado',
            );
          },
        );
      },
    );
  }

  String _statusLabelFor(Item item) {
    return _statusLabelForOwner(_player, item);
  }

  String? _actionLabelFor(Item item) {
    if (!item.isEquippable) return null;
    if (_player.equippedItems.contains(item)) return 'Quitar';
    if (_player.inventoryItems.contains(item)) return 'Equipar';
    return null;
  }

  bool _isActionEnabled(Item item) {
    return _actionLabelFor(item) != null;
  }

  String _enabledActionTooltipFor(Item item) {
    if (_player.equippedItems.contains(item)) {
      return 'Quitar objeto del equipo activo';
    }
    return 'Equipar objeto al jugador';
  }

  String _disabledActionTooltipFor(Item item) {
    if (!item.isEquippable) return 'Este objeto no se puede equipar';
    return 'El objeto ya no esta disponible';
  }

  String _statusLabelForOwner(Battler owner, Item item) {
    if (owner.equippedItems.contains(item)) {
      return 'Estado actual: equipado';
    }
    if (owner.inventoryItems.contains(item)) {
      return 'Estado actual: en inventario';
    }
    return 'Estado actual: no disponible';
  }

  String? _unequipActionLabelFor(
    Battler owner,
    Item item,
    bool canUnequip,
  ) {
    if (!canUnequip) return null;
    if (owner.equippedItems.contains(item)) return 'Quitar';
    return null;
  }

  bool _isUnequipEnabled(Battler owner, Item item, bool canUnequip) {
    return canUnequip && owner.equippedItems.contains(item);
  }

  void _handlePrimaryAction(Item item) {
    final updatedPlayer = _player.equippedItems.contains(item)
        ? _player.unequipItem(item)
        : _player.equipItem(item);

    setState(() {
      _player = updatedPlayer;
    });
    widget.onPlayerChanged?.call(updatedPlayer);
  }

  void _handleUnequipItem(Item item) {
    if (!_player.equippedItems.contains(item)) return;

    final updatedPlayer = _player.unequipItem(item);
    setState(() {
      _player = updatedPlayer;
    });
    widget.onPlayerChanged?.call(updatedPlayer);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: min(size.height - 28, 620),
            ),
            child: EndpointPanel(
              accent: EndpointPalette.primaryAccent,
              backgroundColor: EndpointPalette.panelBackgroundOpaque,
              borderRadius: 18,
              glowOpacity: 0.12,
              blurRadius: 22,
              spreadRadius: 2,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: EndpointText(
                          'OPERATIVOS',
                          style: textTitleMediumBold.copyWith(
                            color: EndpointPalette.softForeground,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                      EndpointSceneCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Cerrar operativos',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int index = 0;
                              index < _operatives.length;
                              index++) ...[
                            if (index > 0) const SizedBox(width: 8),
                            _OperativeIconCard(
                              battler: _operatives[index],
                              isSelected: _selectedIndex == index,
                              isPlayer: index == 0,
                              onPressed: () {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _EquipmentRow(
                    battler: _selectedOperative,
                    isPlayer: _isPlayerSelected,
                    onItemPressed: (item) => _openEquippedItemDetails(
                      item,
                      owner: _selectedOperative,
                      canUnequip: _isPlayerSelected,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      EndpointText(
                        'OBJETOS DEL JUGADOR',
                        style: textSmallBold.copyWith(
                          color: EndpointPalette.primaryAccent,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Spacer(),
                      EndpointText(
                        '${_player.inventoryItems.length}',
                        style: textSmallBold.copyWith(
                          color: Colors.white.withOpacity(0.76),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: _player.inventoryItems.isEmpty
                        ? Center(
                            child: EndpointText(
                              'No llevas ningun objeto.',
                              textAlign: TextAlign.center,
                              style: textSmallBold.copyWith(
                                color: Colors.white.withOpacity(0.72),
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              return GridView.builder(
                                itemCount: _player.inventoryItems.length,
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: _operativeTileExtent,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  mainAxisExtent: _operativeTileHeight,
                                ),
                                itemBuilder: (context, index) {
                                  final item = _player.inventoryItems[index];
                                  return EndpointInventoryItemTile(
                                    item: item,
                                    onPressed: () => _openItemDetails(item),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OperativeIconCard extends StatelessWidget {
  final Battler battler;
  final bool isSelected;
  final bool isPlayer;
  final VoidCallback onPressed;

  const _OperativeIconCard({
    required this.battler,
    required this.isSelected,
    required this.isPlayer,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isSelected
        ? EndpointPalette.primaryAccent
        : EndpointPalette.primaryAccent.withOpacity(0.4);

    return HoldTooltip(
      message: battler.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            width: 54,
            padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
            decoration: BoxDecoration(
              color: EndpointPalette.blend(
                EndpointPalette.panelBackgroundSoft,
                EndpointPalette.primaryAccent,
                0.08,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(isSelected ? 0.12 : 0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EndpointEmojiSprite(
                  emoji: isPlayer ? battler.iconEmoji : '\u{1F464}',
                  accent: EndpointPalette.primaryAccent,
                  size: 28,
                ),
                const SizedBox(height: 3),
                EndpointText(
                  isPlayer ? 'TU' : 'OP',
                  style: textSmallBold.copyWith(
                    color: EndpointPalette.softForeground,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EquipmentRow extends StatelessWidget {
  final Battler battler;
  final bool isPlayer;
  final ValueChanged<Item>? onItemPressed;

  const _EquipmentRow({
    required this.battler,
    required this.isPlayer,
    this.onItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      backgroundColor: EndpointPalette.panelBackgroundSoft,
      borderRadius: 14,
      glowOpacity: 0.05,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EndpointText(
            isPlayer ? 'EQUIPO ACTIVO' : 'EQUIPO DEL OPERATIVO',
            style: textSmallBold.copyWith(
              color: EndpointPalette.primaryAccent,
              fontSize: 15,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: EndpointEquipmentSlotsStrip(
              battler: battler,
              layout: EndpointEquipmentLayout.standard,
              onItemPressed: onItemPressed,
            ),
          ),
        ],
      ),
    );
  }
}
