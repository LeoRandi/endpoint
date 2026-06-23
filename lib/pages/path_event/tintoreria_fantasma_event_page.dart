import '_imports.dart';

class TintoreriaFantasmaEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final RunRandomizer randomizer;
  final PathEventService eventService;
  final int dayNumber;

  const TintoreriaFantasmaEventPage({
    super.key,
    required this.player,
    required this.node,
    required this.randomizer,
    required this.eventService,
    required this.dayNumber,
  });

  @override
  State<TintoreriaFantasmaEventPage> createState() =>
      _TintoreriaFantasmaEventPageState();
}

class _TintoreriaFantasmaEventPageState
    extends State<TintoreriaFantasmaEventPage> {
  late final List<Item> _offers;
  Item? _selectedItem;
  int _flavorPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _offers = widget.eventService.buildTintoreriaFantasmaOffers(
      player: widget.player,
      randomizer: widget.randomizer,
      dayNumber: widget.dayNumber,
    );
  }

  void _close() {
    Navigator.of(context).pop(
      PathEventVisitResult(
        player: widget.player,
        outcomeText: 'La bruma se cierra sin prestarte nada.',
      ),
    );
  }

  bool get _isFlavorIntroVisible {
    final flavorTexts = widget.node.flavorTexts;
    return flavorTexts.isNotEmpty && _flavorPageIndex < flavorTexts.length;
  }

  void _advanceFlavorIntro() {
    if (!_isFlavorIntroVisible) return;
    setState(() {
      _flavorPageIndex++;
    });
  }

  Future<void> _openItemDetails(Item item) async {
    final selectedItem = await showEndpointDialog<Item>(
      context: context,
      barrierLabel: 'Detalle de objeto fantasma',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return EndpointItemDetailsDialog(
          item: item.copyWith(isGhostly: true),
          accent: item.rarity.accent,
          price: widget.eventService.tintoreriaFantasmaPriceFor(item),
          priceLabel: 'FIJAR',
          statusText: 'Prestamo fantasma: dos combates.',
          actionLabel: 'Elegir',
          actionIcon: Icons.local_laundry_service_rounded,
          onPrimaryAction: () {
            Navigator.of(context).pop(item);
          },
          isActionEnabled: true,
          enabledActionTooltip: 'Tomar prestado este objeto',
        );
      },
    );
    if (!mounted || selectedItem == null) return;

    setState(() {
      _selectedItem = selectedItem;
    });
  }

  void _borrowSelectedItem() {
    final selectedItem = _selectedItem;
    if (selectedItem == null) return;

    Navigator.of(context).pop(
      widget.eventService.resolveTintoreriaFantasmaBorrow(
        player: widget.player,
        selectedItem: selectedItem,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EndpointCenterStageScene(
      showTitle: widget.node.showTitle,
      background: EndpointGradients.event(widget.node.accent),
      foregroundOverlay: _isFlavorIntroVisible
          ? EndpointEventFlavorIntroOverlay(
              pages: widget.node.flavorTexts,
              pageIndex: _flavorPageIndex,
              emoji: widget.node.flavorEmoji ?? widget.node.iconEmoji,
              accent: widget.node.accent,
              onAdvance: _advanceFlavorIntro,
            )
          : null,
      onClose: _close,
      closeTooltip: EndpointStrings.backToRoute,
      accent: widget.node.accent,
      emoji: widget.node.iconEmoji,
      title: widget.node.eventTitle,
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    final selectedItem = _selectedItem;
    final blockReason = selectedItem == null ? 'Elige una prenda' : null;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: EndpointPanel(
        accent: widget.node.accent,
        backgroundColor: EndpointPalette.panelBackgroundSoft,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EndpointText(
              widget.node.description,
              textAlign: TextAlign.center,
              maxLines: null,
              style: textSmallBold.copyWith(
                color: EndpointPalette.softForeground.withAlpha(214),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildOffers(),
            const SizedBox(height: 12),
            EndpointActionButton(
              label: selectedItem == null
                  ? 'Elige una prenda'
                  : 'Tomar ${selectedItem.displayName}',
              icon: Icons.local_laundry_service_rounded,
              onPressed: blockReason == null ? _borrowSelectedItem : null,
              tooltip: blockReason ?? 'Tomar el objeto prestado',
              accent: selectedItem?.rarity.accent ?? widget.node.accent,
              backgroundColor: EndpointPalette.blend(
                EndpointPalette.panelBackgroundGold,
                selectedItem?.rarity.accent ?? widget.node.accent,
                blockReason == null ? 0.24 : 0.08,
              ),
              foregroundColor: EndpointPalette.soften(
                selectedItem?.rarity.accent ?? widget.node.accent,
              ),
              expands: true,
              useMarquee: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffers() {
    if (_offers.isEmpty) {
      return EndpointText(
        'La barra esta vacia. La bruma no encuentra prendas compatibles.',
        textAlign: TextAlign.center,
        maxLines: null,
        style: textMediumBold.copyWith(
          color: EndpointPalette.softForeground.withAlpha(184),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < _offers.length; index++) ...[
            if (index > 0) const SizedBox(width: 10),
            SizedBox(
              width: 92,
              height: 110,
              child: EndpointInventoryItemTile(
                item: _offers[index].copyWith(isGhostly: true),
                accent: _selectedItem == _offers[index]
                    ? EndpointPalette.warningAccent
                    : _offers[index].rarity.accent,
                glowOpacity: _selectedItem == _offers[index] ? 0.18 : 0.04,
                onPressed: () => _openItemDetails(_offers[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
