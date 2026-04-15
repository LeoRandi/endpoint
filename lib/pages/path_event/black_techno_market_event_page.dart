import '../_imports.dart';

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
  late final List<BattlerAbility> _offers;
  BattlerAbility? _selectedAbility;
  bool _isResolvingPurchase = false;

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
        outcomeText: 'No compras ninguna habilidad.',
      ),
    );
  }

  Future<void> _openOfferDetails(BattlerAbility ability) async {
    final price = widget.eventService.blackTechnoMarketPriceFor(ability);
    final selectedAbility = await showEndpointDialog<BattlerAbility>(
      context: context,
      barrierLabel: 'Detalle de habilidad',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return EndpointAbilityDetailsDialog(
          ability: ability,
          accent: ability.accent,
          statusText: ability.rarity.label,
          moneyCost: price,
          actionLabel: 'Seleccionar',
          onPrimaryAction: () {
            Navigator.of(context).pop(ability);
          },
          isActionEnabled: true,
          enabledActionTooltip: 'Seleccionar esta habilidad para comprarla',
        );
      },
    );
    if (!mounted || selectedAbility == null) return;

    _selectOffer(selectedAbility);
  }

  void _selectOffer(BattlerAbility ability) {
    setState(() {
      _selectedAbility = ability;
    });
  }

  Future<void> _buySelectedAbility() async {
    final selectedAbility = _selectedAbility;
    if (_isResolvingPurchase ||
        selectedAbility == null ||
        _selectionBlockReason != null) {
      return;
    }

    setState(() {
      _isResolvingPurchase = true;
    });

    final result = widget.eventService.resolveBlackTechnoMarketPurchase(
      player: widget.player,
      selectedAbility: selectedAbility,
    );
    final gainedAbility = result.gainedAbility;
    if (gainedAbility != null) {
      await showEndpointDialog<void>(
        context: context,
        barrierLabel: 'Habilidad comprada',
        barrierDismissible: false,
        barrierColor: EndpointPalette.overlayScrim,
        builder: (context) {
          return _BlackMarketPurchaseDialog(
            ability: gainedAbility,
            outcomeText: result.outcomeText,
            accent: gainedAbility.accent,
          );
        },
      );
    }
    if (!mounted) return;

    Navigator.of(context).pop(result);
  }

  int? get _selectedPrice {
    final selectedAbility = _selectedAbility;
    if (selectedAbility == null) return null;

    return widget.eventService.blackTechnoMarketPriceFor(selectedAbility);
  }

  String? get _selectionBlockReason {
    final selectedAbility = _selectedAbility;
    if (selectedAbility == null) return 'Elige una habilidad';

    final ownedAbility = widget.player.abilityById(selectedAbility.id);
    if (ownedAbility != null && !ownedAbility.canUpgrade) {
      return 'Esta habilidad no puede mejorar mas';
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
      onClose: _close,
      closeTooltip: EndpointStrings.backToRoute,
      accent: widget.node.accent,
      emoji: widget.node.iconEmoji,
      title: widget.node.eventTitle,
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    final selectedAbility = _selectedAbility;
    final selectedPrice = _selectedPrice;
    final blockReason = _selectionBlockReason;

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
              label: selectedAbility == null
                  ? 'Elige una habilidad'
                  : 'Comprar seleccion',
              icon: Icons.shopping_bag_rounded,
              onPressed: blockReason == null && !_isResolvingPurchase
                  ? _buySelectedAbility
                  : null,
              tooltip: blockReason ?? 'Comprar ${selectedAbility?.displayName}',
              accent: selectedAbility?.accent ?? widget.node.accent,
              backgroundColor: EndpointPalette.blend(
                EndpointPalette.panelBackgroundGold,
                selectedAbility?.accent ?? widget.node.accent,
                blockReason == null ? 0.24 : 0.08,
              ),
              foregroundColor: EndpointPalette.soften(
                selectedAbility?.accent ?? widget.node.accent,
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
        'No hay habilidades disponibles.',
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
              ability: _offers[index],
              offerNumber: index + 1,
              price: widget.eventService.blackTechnoMarketPriceFor(
                _offers[index],
              ),
              ownedAbility: widget.player.abilityById(_offers[index].id),
              isSelected: _selectedAbility?.id == _offers[index].id,
              onPressed: () => _openOfferDetails(_offers[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _BlackMarketOfferCard extends StatelessWidget {
  final BattlerAbility ability;
  final BattlerAbility? ownedAbility;
  final int offerNumber;
  final int price;
  final bool isSelected;
  final VoidCallback? onPressed;

  const _BlackMarketOfferCard({
    required this.ability,
    required this.ownedAbility,
    required this.offerNumber,
    required this.price,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ownedLabel = ownedAbility == null
        ? null
        : !ownedAbility!.canUpgrade
            ? 'NO MEJORA'
            : 'YA TIENES ${ownedAbility!.rarity.label}';
    final foreground = EndpointPalette.soften(ability.accent);
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 142,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: EndpointPalette.blend(
          EndpointPalette.panelBackgroundGold,
          ability.accent,
          isSelected ? 0.24 : 0.1,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ability.accent.withAlpha(isSelected ? 235 : 135),
          width: isSelected ? 1.7 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: ability.accent.withAlpha(isSelected ? 61 : 23),
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
              color: ability.accent,
              fontSize: 9,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          EndpointAbilityOrb(
            ability: ability,
            size: 64,
            enableTooltipLongPress: false,
          ),
          const SizedBox(height: 8),
          EndpointText(
            ability.displayName,
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
            ability.rarity.label,
            style: textSmallBold.copyWith(
              color: ability.accent,
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
  final BattlerAbility ability;
  final String outcomeText;
  final Color accent;

  const _BlackMarketPurchaseDialog({
    required this.ability,
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
                EndpointAbilityOrb(
                  ability: widget.ability,
                  accent: widget.accent,
                  size: 64,
                  enableTooltipLongPress: false,
                ),
                const SizedBox(height: 10),
                EndpointText(
                  'HABILIDAD COMPRADA',
                  textAlign: TextAlign.center,
                  style: textMediumBold.copyWith(
                    color: widget.accent,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                EndpointText(
                  widget.ability.displayName,
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
