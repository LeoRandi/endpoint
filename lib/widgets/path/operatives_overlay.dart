import '../_imports.dart';
import 'package:flutter/foundation.dart';

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
  late OperativesOverlayController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
  }

  /// Reconstruye el controlador cuando cambia el jugador visible o la lista de acompanantes.
  @override
  void didUpdateWidget(covariant OperativesOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player == widget.player &&
        listEquals(oldWidget.companions, widget.companions) &&
        oldWidget.onPlayerChanged == widget.onPlayerChanged) {
      return;
    }

    _controller.dispose();
    _controller = _buildController();
  }

  /// Crea el controlador que centraliza seleccion y equipo dentro del overlay.
  OperativesOverlayController _buildController() {
    return OperativesOverlayController(
      player: widget.player,
      companions: widget.companions,
      onPlayerChanged: widget.onPlayerChanged,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openItemDetails(Item item) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de objeto',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return EndpointItemDetailsDialog(
              item: item,
              accent: item.rarity.accent,
              price: item.cost,
              statusText: _controller.statusLabelFor(item),
              actionLabel: _controller.actionLabelFor(item),
              onPrimaryAction: _controller.isActionEnabled(item)
                  ? () {
                      _controller.handlePrimaryAction(item);
                    }
                  : null,
              isActionEnabled: _controller.isActionEnabled(item),
              enabledActionTooltip: _controller.enabledActionTooltipFor(item),
              disabledActionTooltip: _controller.disabledActionTooltipFor(item),
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
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final detailBattler = canUnequip ? _controller.player : owner;

            return EndpointItemDetailsDialog(
              item: item,
              accent: item.rarity.accent,
              price: item.cost,
              statusText: _controller.statusLabelForOwner(detailBattler, item),
              actionLabel: _controller.unequipActionLabelFor(
                detailBattler,
                item,
                canUnequip,
              ),
              onPrimaryAction: _controller.isUnequipEnabled(
                detailBattler,
                item,
                canUnequip,
              )
                      ? () {
                          _controller.handleUnequipItem(item);
                        }
                      : null,
              isActionEnabled: _controller.isUnequipEnabled(
                detailBattler,
                item,
                canUnequip,
              ),
              enabledActionTooltip: 'Quitar objeto del equipo activo',
              disabledActionTooltip: 'El objeto ya no esta equipado',
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final operatives = _controller.operatives;
        final selectedOperative = _controller.selectedOperative;
        final player = _controller.player;

        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
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
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
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
                                  index < operatives.length;
                                  index++) ...[
                                if (index > 0) const SizedBox(width: 8),
                                _OperativeIconCard(
                                  battler: operatives[index],
                                  isSelected: _controller.selectedIndex == index,
                                  isPlayer: index == 0,
                                  onPressed: () {
                                    _controller.selectOperative(index);
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _EquipmentRow(
                        battler: selectedOperative,
                        isPlayer: _controller.isPlayerSelected,
                        onItemPressed: (item) => _openEquippedItemDetails(
                          item,
                          owner: selectedOperative,
                          canUnequip: _controller.isPlayerSelected,
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
                            '${player.inventoryItems.length}',
                            style: textSmallBold.copyWith(
                              color: Colors.white.withOpacity(0.76),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: player.inventoryItems.isEmpty
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
                                    itemCount: player.inventoryItems.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: _operativeTileExtent,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      mainAxisExtent: _operativeTileHeight,
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = player.inventoryItems[index];
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
      },
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
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
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
                const SizedBox(height: 2),
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
