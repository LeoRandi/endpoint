import '../_imports.dart';

class SWitchCabinEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final PathEventService eventService;

  const SWitchCabinEventPage({
    super.key,
    required this.player,
    required this.node,
    this.eventService = const PathEventService(),
  });

  @override
  State<SWitchCabinEventPage> createState() => _SWitchCabinEventPageState();
}

class _SWitchCabinEventPageState extends State<SWitchCabinEventPage> {
  late final List<Item> _eligibleItems;
  Item? _firstItem;
  Item? _secondItem;
  int _flavorPageIndex = 0;

  bool get _isFlavorIntroVisible =>
      widget.node.flavorTexts.isNotEmpty &&
      _flavorPageIndex < widget.node.flavorTexts.length;

  @override
  void initState() {
    super.initState();
    _eligibleItems = widget.eventService.buildSWitchCabinEligibleItems(
      widget.player,
    );
  }

  void _advanceFlavorIntro() {
    if (!_isFlavorIntroVisible) return;
    setState(() => _flavorPageIndex++);
  }

  void _close() {
    Navigator.of(context).pop(
      PathEventVisitResult(
        player: widget.player,
        outcomeText: 'Sales de la cabina sin cambiar nada.',
      ),
    );
  }

  void _selectItem(Item item) {
    setState(() {
      if (_firstItem == item) {
        _firstItem = null;
        return;
      }
      if (_secondItem == item) {
        _secondItem = null;
        return;
      }
      if (_firstItem == null) {
        _firstItem = item;
        return;
      }
      _secondItem = item;
    });
  }

  void _swap() {
    final firstItem = _firstItem;
    final secondItem = _secondItem;
    if (firstItem == null || secondItem == null) return;

    Navigator.of(context).pop(
      widget.eventService.resolveSWitchPatternSwap(
        player: widget.player,
        firstItem: firstItem,
        secondItem: secondItem,
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
    final canSwap = _firstItem != null && _secondItem != null;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: EndpointPanel(
        accent: widget.node.accent,
        backgroundColor: EndpointPalette.panelBackgroundSoft,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EndpointText(
              widget.node.description,
              textAlign: TextAlign.center,
              maxLines: null,
              style: textMedium.copyWith(
                color: EndpointPalette.softForeground.withAlpha(214),
              ),
            ),
            const SizedBox(height: 12),
            _buildItemGrid(),
            const SizedBox(height: 12),
            EndpointActionButton(
              label: canSwap ? 'Cambiar patrones' : 'Elige dos objetos',
              icon: Icons.swap_horiz_rounded,
              onPressed: canSwap ? _swap : null,
              tooltip: canSwap
                  ? 'Intercambiar bonus de Patron'
                  : 'Selecciona dos objetos con bonus de Patron',
              accent: widget.node.accent,
              expands: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemGrid() {
    if (_eligibleItems.length < 2) {
      return EndpointText(
        'La cabina necesita al menos dos objetos con bonus de Patron.',
        textAlign: TextAlign.center,
        maxLines: null,
        style: textSmallBold.copyWith(
          color: EndpointPalette.softForeground.withAlpha(184),
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final item in _eligibleItems)
              _SWitchItemChip(
                item: item,
                isSelected: item == _firstItem || item == _secondItem,
                orderLabel: item == _firstItem
                    ? '1'
                    : item == _secondItem
                        ? '2'
                        : null,
                onPressed: () => _selectItem(item),
              ),
          ],
        ),
      ),
    );
  }
}

class _SWitchItemChip extends StatelessWidget {
  final Item item;
  final bool isSelected;
  final String? orderLabel;
  final VoidCallback onPressed;

  const _SWitchItemChip({
    required this.item,
    required this.isSelected,
    required this.orderLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = item.rarity.accent;
    final patternKind = switch (item.patternBonusKind) {
      OperativePatternBonusKind.attack => 'ATK',
      OperativePatternBonusKind.barrier => 'BARR',
      OperativePatternBonusKind.health => 'HP',
    };
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 150,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: EndpointPalette.blend(
          EndpointPalette.panelBackgroundGold,
          accent,
          isSelected ? 0.24 : 0.1,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withAlpha(isSelected ? 235 : 120),
          width: isSelected ? 1.7 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EndpointText(
                item.iconEmoji,
                style: textMedium.copyWith(fontSize: 22),
              ),
              if (orderLabel != null) ...[
                const SizedBox(width: 6),
                EndpointText(
                  orderLabel!,
                  style: textSmallNumericBold.copyWith(
                    color: accent,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          EndpointText(
            item.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textSmallBold.copyWith(
              color: EndpointPalette.softForeground,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 5),
          EndpointText(
            '+${item.patternBonusAmount} $patternKind',
            style: textSmallBold.copyWith(
              color: accent,
              fontSize: 9,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }
}
