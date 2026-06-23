import '_imports.dart';

class SecretPassageEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final RunRandomizer? randomizer;
  final PathEventService eventService;

  const SecretPassageEventPage({
    super.key,
    required this.player,
    required this.node,
    this.randomizer,
    this.eventService = const PathEventService(),
  });

  @override
  State<SecretPassageEventPage> createState() => _SecretPassageEventPageState();
}

class _SecretPassageEventPageState extends State<SecretPassageEventPage> {
  late final List<PathNode> _offers;
  PathNode? _selectedNode;
  bool _isResolvingDeal = false;
  int _flavorPageIndex = 0;

  bool get _isFlavorIntroVisible {
    final flavorTexts = widget.node.flavorTexts;
    return flavorTexts.isNotEmpty && _flavorPageIndex < flavorTexts.length;
  }

  @override
  void initState() {
    super.initState();
    _offers = widget.eventService.buildSecretPassageOffers(
      randomizer: widget.randomizer ?? RunRandomizer(),
    );
  }

  void _close() {
    Navigator.of(context).pop(
      PathEventVisitResult(
        player: widget.player,
        outcomeText: 'Ignoras la propuesta y sigues tu ruta.',
      ),
    );
  }

  void _advanceFlavorIntro() {
    if (!_isFlavorIntroVisible) return;
    setState(() {
      _flavorPageIndex++;
    });
  }

  void _selectNode(PathNode node) {
    setState(() {
      _selectedNode = node;
    });
  }

  String? get _selectionBlockReason {
    if (_offers.isEmpty) {
      return 'No hay nodos disponibles para negociar.';
    }

    final selectedNode = _selectedNode;
    if (selectedNode == null) return 'Selecciona un nodo';
    final isCurrentSelectionValid = _offers.any(
      (offer) => offer.nodeId == selectedNode.nodeId,
    );
    if (!isCurrentSelectionValid) {
      return 'La oferta seleccionada ya no esta disponible';
    }

    final dealCost = widget.eventService.pasadizoSecretoDealCost;
    if (!widget.player.canAfford(dealCost)) {
      return 'Te faltan ${dealCost - widget.player.money} créditos';
    }

    return null;
  }

  Future<void> _sealDeal() async {
    final selectedNode = _selectedNode;
    if (_isResolvingDeal ||
        selectedNode == null ||
        _selectionBlockReason != null) {
      return;
    }

    setState(() {
      _isResolvingDeal = true;
    });

    final result = widget.eventService.resolvePasadizoSecretoDeal(
      player: widget.player,
      selectedNode: selectedNode,
    );
    if (!mounted) return;

    Navigator.of(context).pop(result);
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
    final selectedNode = _selectedNode;
    final blockReason = _selectionBlockReason;
    final dealCost = widget.eventService.pasadizoSecretoDealCost;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: EndpointPanel(
        accent: widget.node.accent,
        backgroundColor: EndpointPalette.panelBackgroundSoft,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                EndpointText(
                  'CRÉDITOS',
                  style: textSmallBold.copyWith(
                    color: widget.node.accent,
                    letterSpacing: 1.4,
                  ),
                ),
                const Spacer(),
                EndpointCurrencyInline(
                  value: widget.player.money,
                  iconColor: EndpointPalette.warningAccent,
                  textColor: EndpointPalette.softForeground,
                  iconSize: 15,
                  spacing: 4,
                  textStyle: textMediumNumericBold.copyWith(
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            EndpointText(
              widget.node.description,
              textAlign: TextAlign.center,
              maxLines: null,
              style: textSmallBold.copyWith(
                color: EndpointPalette.softForeground.withAlpha(214),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),
            _buildOffersStrip(),
            const SizedBox(height: 10),
            EndpointCurrencyInline(
              value: dealCost,
              iconColor: EndpointPalette.warningAccent,
              textColor: EndpointPalette.softForegroundWarm,
              iconSize: 14,
              spacing: 4,
              textStyle: textSmallNumericBold.copyWith(
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            if (selectedNode != null) ...[
              const SizedBox(height: 8),
              EndpointText(
                'Nodo asegurado: ${selectedNode.label}',
                textAlign: TextAlign.center,
                maxLines: null,
                style: textSmallBold.copyWith(
                  color: selectedNode.accent,
                  fontSize: 10,
                  letterSpacing: 0.9,
                ),
              ),
            ],
            const SizedBox(height: 10),
            EndpointActionButton(
              label: selectedNode == null ? 'Elige una oferta' : 'Cerrar trato',
              icon: Icons.lock_rounded,
              onPressed:
                  blockReason == null && !_isResolvingDeal ? _sealDeal : null,
              tooltip: blockReason ??
                  'Pagar ${dealCost}C para asegurar ${selectedNode?.label ?? 'el nodo'} en la siguiente eleccion',
              accent: selectedNode?.accent ?? widget.node.accent,
              backgroundColor: EndpointPalette.blend(
                EndpointPalette.panelBackgroundGold,
                selectedNode?.accent ?? widget.node.accent,
                blockReason == null ? 0.24 : 0.08,
              ),
              foregroundColor: EndpointPalette.soften(
                selectedNode?.accent ?? widget.node.accent,
              ),
              expands: true,
              useMarquee: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersStrip() {
    if (_offers.isEmpty) {
      return EndpointText(
        'No hay ofertas disponibles.',
        textAlign: TextAlign.center,
        style: textMediumBold.copyWith(
          color: EndpointPalette.softForeground.withAlpha(184),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < _offers.length; index++) ...[
            if (index > 0) const SizedBox(width: 10),
            _PasadizoSecretoOfferCard(
              node: _offers[index],
              offerNumber: index + 1,
              isSelected: _selectedNode?.nodeId == _offers[index].nodeId,
              onPressed: () => _selectNode(_offers[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _PasadizoSecretoOfferCard extends StatelessWidget {
  final PathNode node;
  final int offerNumber;
  final bool isSelected;
  final VoidCallback? onPressed;

  const _PasadizoSecretoOfferCard({
    required this.node,
    required this.offerNumber,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = node.accent;
    final typeLabel = node.type == PathNodeType.shop ? 'TIENDA' : 'EVENTO';
    final foreground = EndpointPalette.soften(accent);
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 142,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: EndpointPalette.blend(
          EndpointPalette.panelBackgroundGold,
          accent,
          isSelected ? 0.24 : 0.1,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withAlpha(isSelected ? 235 : 135),
          width: isSelected ? 1.7 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(isSelected ? 61 : 23),
            blurRadius: isSelected ? 16 : 8,
            spreadRadius: isSelected ? 2 : 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EndpointText(
            'OFERTA $offerNumber',
            style: textSmallBold.copyWith(
              color: accent,
              fontSize: 9,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          EndpointEmojiSprite(
            emoji: node.iconEmoji,
            accent: accent,
            size: 64,
          ),
          const SizedBox(height: 8),
          EndpointText(
            node.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textSmallBold.copyWith(
              color: foreground,
              fontSize: 10,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          EndpointText(
            typeLabel,
            style: textSmallBold.copyWith(
              color: accent,
              fontSize: 9,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          EndpointText(
            node.rarity.label,
            style: textSmallBold.copyWith(
              color: EndpointPalette.softForegroundWarm,
              fontSize: 9,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          EndpointText(
            node.localizedBadgeLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textSmallBold.copyWith(
              color: EndpointPalette.softForeground.withAlpha(184),
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );

    if (onPressed == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}
