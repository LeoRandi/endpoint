import '_imports.dart';

const _operativeTileExtent = 70.0;
const _operativeTileHeight = 84.0;
const _operativeTileEmojiSize = 18.0;

class OperativesOverlay extends StatefulWidget {
  final Battler player;
  final List<Battler> companions;

  const OperativesOverlay({
    super.key,
    required this.player,
    this.companions = const [],
  });

  @override
  State<OperativesOverlay> createState() => _OperativesOverlayState();
}

class _OperativesOverlayState extends State<OperativesOverlay> {
  int _selectedIndex = 0;

  List<Battler> get _operatives => [widget.player, ...widget.companions];
  Battler get _selectedOperative => _operatives[_selectedIndex];
  bool get _isPlayerSelected => _selectedIndex == 0;

  Future<void> _openItemDetails(Item item) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Detalle de objeto',
      barrierColor: Colors.black.withOpacity(0.62),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return EndpointItemDetailsDialog(
          item: item,
          player: widget.player,
          accent: item.rarity.accent,
          price: item.cost,
          statusText: _statusLabelFor(item),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  String _statusLabelFor(Item item) {
    if (widget.player.equippedItems.contains(item)) {
      return 'Estado actual: equipado';
    }
    return 'Estado actual: en inventario';
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
              accent: const Color(0xFF5AF78E),
              backgroundColor: const Color(0xF107120D),
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
                          style: textMediumBold.copyWith(
                            color: const Color(0xFFE6FFF0),
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
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      EndpointText(
                        'OBJETOS DEL JUGADOR',
                        style: textSmallBold.copyWith(
                          color: const Color(0xFF5AF78E),
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Spacer(),
                      EndpointText(
                        '${widget.player.inventoryItems.length}',
                        style: textSmallBold.copyWith(
                          color: Colors.white.withOpacity(0.76),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: widget.player.inventoryItems.isEmpty
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
                                itemCount: widget.player.inventoryItems.length,
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: _operativeTileExtent,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  mainAxisExtent: _operativeTileHeight,
                                ),
                                itemBuilder: (context, index) {
                                  final item =
                                      widget.player.inventoryItems[index];
                                  return _InventoryItemTile(
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
    final accent =
        isSelected ? const Color(0xFF5AF78E) : const Color(0x665AF78E);

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
              color: const Color(0xCC0A1710),
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
                  emoji: isPlayer ? '\u{1F916}' : '\u{1F464}',
                  accent: const Color(0xFF5AF78E),
                  size: 28,
                ),
                const SizedBox(height: 3),
                EndpointText(
                  isPlayer ? 'TU' : 'OP',
                  style: textSmallBold.copyWith(
                    color: const Color(0xFFE6FFF0),
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

  const _EquipmentRow({
    required this.battler,
    required this.isPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      backgroundColor: const Color(0xCC07120D),
      borderRadius: 14,
      glowOpacity: 0.05,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EndpointText(
            isPlayer ? 'EQUIPO ACTIVO' : 'EQUIPO DEL OPERATIVO',
            style: textSmallBold.copyWith(
              color: const Color(0xFF5AF78E),
              fontSize: 15,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: EndpointEquipmentSlotsStrip(
              battler: battler,
              layout: isPlayer
                  ? EndpointEquipmentLayout.standard
                  : EndpointEquipmentLayout.generic,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryItemTile extends StatelessWidget {
  final Item item;
  final VoidCallback onPressed;

  const _InventoryItemTile({
    required this.item,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return HoldTooltip(
      message: item.description,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: EndpointPanel(
            backgroundColor: const Color(0xCC07120D),
            borderRadius: 12,
            glowOpacity: 0.03,
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/slots/equipment_slot_base.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                      ),
                      Center(
                        child: EndpointText(
                          item.iconEmoji,
                          style: const TextStyle(
                            fontSize: _operativeTileEmojiSize,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                EndpointText(
                  item.name,
                  textAlign: TextAlign.center,
                  style: textSmallBold.copyWith(
                    color: const Color(0xFFE6FFF0),
                    fontSize: 12,
                    letterSpacing: 0.5,
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
