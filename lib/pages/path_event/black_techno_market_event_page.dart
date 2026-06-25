import '_imports.dart';

class BlackTechnoMarketEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final RunRandomizer? randomizer;
  final PathEventService eventService;

  const BlackTechnoMarketEventPage({
    super.key,
    required this.player,
    required this.node,
    this.randomizer,
    this.eventService = const PathEventService(),
  });

  @override
  State<BlackTechnoMarketEventPage> createState() =>
      _BlackTechnoMarketEventPageState();
}

class _BlackTechnoMarketEventPageState
    extends State<BlackTechnoMarketEventPage> {
  late final List<Augment> _offers;
  Augment? _selectedAugment;
  bool _isResolvingPurchase = false;
  int _flavorPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _offers = widget.eventService.buildBlackTechnoMarketOffers(
      player: widget.player,
      randomizer: widget.randomizer ?? RunRandomizer(),
    );
  }

  void _close() {
    Navigator.of(context).pop(
      PathEventVisitResult(
        player: widget.player,
        outcomeText: 'No compras ningun aumento.',
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

  Future<void> _openOfferDetails(Augment augment) async {
    final price = widget.eventService.blackTechnoMarketPriceFor(augment);
    final selectedAugment = await showEndpointDialog<Augment>(
      context: context,
      barrierLabel: 'Detalle de aumento',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return EndpointDetailsDialogScaffold(
          accent: augment.accent,
          backgroundColor: EndpointPalette.panelBackgroundGold,
          foregroundColor: EndpointPalette.softForeground,
          closeBackgroundColor: EndpointPalette.closeButtonBackground,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EndpointAugmentOrb(
                augment: augment,
                size: 70,
              ),
              const SizedBox(height: 10),
              EndpointText(
                augment.displayName,
                textAlign: TextAlign.center,
                maxLines: null,
                style: textLargeBold.copyWith(
                  color: EndpointPalette.soften(augment.accent),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              EndpointHighlightedValueText(
                augment.displayDescription,
                tags: augment.tags,
                textAlign: TextAlign.center,
                maxLines: null,
                style: textSmallBold.copyWith(
                  color: EndpointPalette.softForeground.withAlpha(210),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              EndpointCurrencyInline(
                value: price,
                iconColor: EndpointPalette.warningAccent,
                textColor: EndpointPalette.softForeground,
              ),
              const SizedBox(height: 12),
              EndpointActionButton(
                label: 'Seleccionar',
                icon: Icons.check_rounded,
                onPressed: () => Navigator.of(context).pop(augment),
                tooltip: 'Seleccionar este aumento para comprarlo',
                accent: augment.accent,
                expands: true,
                useMarquee: false,
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || selectedAugment == null) return;

    _selectOffer(selectedAugment);
  }

  void _selectOffer(Augment augment) {
    setState(() {
      _selectedAugment = augment;
    });
  }

  Future<void> _buySelectedAugment() async {
    final selectedAugment = _selectedAugment;
    if (_isResolvingPurchase ||
        selectedAugment == null ||
        _selectionBlockReason != null) {
      return;
    }

    setState(() {
      _isResolvingPurchase = true;
    });

    final result = widget.eventService.resolveBlackTechnoMarketPurchase(
      player: widget.player,
      selectedAugment: selectedAugment,
    );
    final gainedAugment = result.gainedAugment;
    if (gainedAugment != null) {
      await showEndpointDialog<void>(
        context: context,
        barrierLabel: 'Aumento comprado',
        barrierDismissible: false,
        barrierColor: EndpointPalette.overlayScrim,
        builder: (context) {
          return _BlackMarketPurchaseDialog(
            augment: gainedAugment,
            outcomeText: result.outcomeText,
            accent: gainedAugment.accent,
          );
        },
      );
    }
    if (!mounted) return;

    Navigator.of(context).pop(result);
  }

  int? get _selectedPrice {
    final selectedAugment = _selectedAugment;
    if (selectedAugment == null) return null;

    return widget.eventService.blackTechnoMarketPriceFor(selectedAugment);
  }

  String? get _selectionBlockReason {
    final selectedAugment = _selectedAugment;
    if (selectedAugment == null) return 'Elige un aumento';

    final ownedAugment = widget.player.augmentById(selectedAugment.id);
    if (ownedAugment != null && !ownedAugment.canUpgrade) {
      return 'Este aumento no puede mejorar mas';
    }

    final price = _selectedPrice ?? 0;
    if (!widget.player.canAfford(price)) {
      return 'Te faltan ${price - widget.player.money} creditos';
    }

    return null;
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
    final selectedAugment = _selectedAugment;
    final selectedPrice = _selectedPrice;
    final blockReason = _selectionBlockReason;
    final willUpgradeSelectedAugment = selectedAugment != null &&
        widget.player.wouldUpgradeAugment(selectedAugment);
    final actionTooltip = blockReason ??
        (selectedAugment == null
            ? 'Elige un aumento'
            : willUpgradeSelectedAugment
                ? 'Mejorar ${selectedAugment.displayName}'
                : 'Comprar ${selectedAugment.displayName}');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
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
                  'CREDITOS',
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
            const SizedBox(height: 12),
            if (selectedPrice != null) ...[
              EndpointCurrencyInline(
                value: selectedPrice,
                iconColor: EndpointPalette.warningAccent,
                textColor: EndpointPalette.softForegroundWarm,
                iconSize: 14,
                spacing: 4,
                textStyle: textSmallNumericBold.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
            ],
            EndpointActionButton(
              label: selectedAugment == null
                  ? 'Elige un aumento'
                  : willUpgradeSelectedAugment
                      ? 'Mejorar seleccion'
                      : 'Comprar seleccion',
              icon: Icons.shopping_bag_rounded,
              onPressed: blockReason == null && !_isResolvingPurchase
                  ? _buySelectedAugment
                  : null,
              tooltip: actionTooltip,
              accent: selectedAugment?.accent ?? widget.node.accent,
              backgroundColor: EndpointPalette.blend(
                EndpointPalette.panelBackgroundGold,
                selectedAugment?.accent ?? widget.node.accent,
                blockReason == null ? 0.24 : 0.08,
              ),
              foregroundColor: EndpointPalette.soften(
                selectedAugment?.accent ?? widget.node.accent,
              ),
              expands: true,
              useMarquee: false,
              showUpgradeIndicator: willUpgradeSelectedAugment,
              upgradeIndicatorColor: endpointUpgradeIndicatorNeonYellow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersStrip() {
    if (_offers.isEmpty) {
      return EndpointText(
        'No hay aumentos disponibles.',
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
            _BlackMarketOfferCard(
              augment: _offers[index],
              offerNumber: index + 1,
              price: widget.eventService.blackTechnoMarketPriceFor(
                _offers[index],
              ),
              ownedAugment: widget.player.augmentById(_offers[index].id),
              isSelected: _selectedAugment?.id == _offers[index].id,
              onPressed: () => _openOfferDetails(_offers[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _BlackMarketOfferCard extends StatelessWidget {
  final Augment augment;
  final Augment? ownedAugment;
  final int offerNumber;
  final int price;
  final bool isSelected;
  final VoidCallback? onPressed;

  const _BlackMarketOfferCard({
    required this.augment,
    required this.ownedAugment,
    required this.offerNumber,
    required this.price,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ownedLabel = ownedAugment == null
        ? null
        : !ownedAugment!.canUpgrade
            ? 'NO MEJORA'
            : 'YA TIENES ${ownedAugment!.rarity.label}';
    final foreground = EndpointPalette.soften(augment.accent);
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 142,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: EndpointPalette.blend(
          EndpointPalette.panelBackgroundGold,
          augment.accent,
          isSelected ? 0.24 : 0.1,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: augment.accent.withAlpha(isSelected ? 235 : 135),
          width: isSelected ? 1.7 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: augment.accent.withAlpha(isSelected ? 61 : 23),
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
              color: augment.accent,
              fontSize: 9,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          EndpointAugmentOrb(
            augment: augment,
            size: 64,
          ),
          const SizedBox(height: 8),
          EndpointText(
            augment.displayName,
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
            augment.rarity.label,
            style: textSmallBold.copyWith(
              color: augment.accent,
              fontSize: 9,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          EndpointText(
            'PRECIO',
            style: textSmallBold.copyWith(
              color: EndpointPalette.warningAccent,
              fontSize: 9,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          EndpointCurrencyInline(
            value: price,
            iconColor: EndpointPalette.warningAccent,
            textColor: EndpointPalette.softForeground,
            iconSize: 13,
            spacing: 3,
            textStyle: textMediumNumericBold.copyWith(
              fontSize: 13,
              letterSpacing: 1.1,
            ),
          ),
          if (ownedLabel != null) ...[
            const SizedBox(height: 5),
            EndpointText(
              ownedLabel,
              textAlign: TextAlign.center,
              style: textSmallBold.copyWith(
                color: EndpointPalette.softForeground.withAlpha(188),
                fontSize: 8,
                letterSpacing: 1,
              ),
            ),
          ],
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

class _BlackMarketPurchaseDialog extends StatefulWidget {
  final Augment augment;
  final String outcomeText;
  final Color accent;

  const _BlackMarketPurchaseDialog({
    required this.augment,
    required this.outcomeText,
    required this.accent,
  });

  @override
  State<_BlackMarketPurchaseDialog> createState() =>
      _BlackMarketPurchaseDialogState();
}

class _BlackMarketPurchaseDialogState
    extends State<_BlackMarketPurchaseDialog> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(
      const Duration(milliseconds: 950),
      () {
        if (!mounted) return;

        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: EndpointPanel(
            accent: widget.accent,
            backgroundColor: EndpointPalette.panelBackgroundGold,
            borderRadius: 18,
            glowOpacity: 0.18,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EndpointAugmentOrb(
                  augment: widget.augment,
                  accent: widget.accent,
                  size: 64,
                ),
                const SizedBox(height: 10),
                EndpointText(
                  'AUMENTO COMPRADO',
                  textAlign: TextAlign.center,
                  style: textMediumBold.copyWith(
                    color: widget.accent,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                EndpointText(
                  widget.augment.displayName,
                  textAlign: TextAlign.center,
                  maxLines: null,
                  style: textLargeBold.copyWith(
                    color: EndpointPalette.soften(widget.accent),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                EndpointText(
                  widget.outcomeText,
                  textAlign: TextAlign.center,
                  maxLines: null,
                  style: textSmallBold.copyWith(
                    color: EndpointPalette.softForeground.withAlpha(210),
                    fontSize: 10,
                    letterSpacing: 0.7,
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
