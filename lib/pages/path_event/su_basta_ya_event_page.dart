import '../_imports.dart';

class SuBastaYaEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final RunRandomizer? randomizer;
  final PathEventService eventService;

  const SuBastaYaEventPage({
    super.key,
    required this.player,
    required this.node,
    this.randomizer,
    this.eventService = const PathEventService(),
  });

  @override
  State<SuBastaYaEventPage> createState() => _SuBastaYaEventPageState();
}

class _SuBastaYaEventPageState extends State<SuBastaYaEventPage> {
  late final RunRandomizer _eventRandomizer;
  late final List<Item> _eligibleItems;
  late final List<BattlerAbility> _eligibleAbilities;
  Item? _auctionItem;
  Item? _statItem;
  BattlerAbility? _swapAbility;
  SuBastaYaStatReward _selectedReward = SuBastaYaStatReward.health;
  int _flavorPageIndex = 0;
  bool _isResolving = false;

  bool get _isFlavorIntroVisible {
    final flavorTexts = widget.node.flavorTexts;
    return flavorTexts.isNotEmpty && _flavorPageIndex < flavorTexts.length;
  }

  @override
  void initState() {
    super.initState();
    _eventRandomizer = widget.randomizer ?? RunRandomizer();
    _eligibleItems = widget.eventService.buildSuBastaYaEligibleItems(
      widget.player,
    );
    _eligibleAbilities = widget.eventService.buildSuBastaYaEligibleAbilities(
      widget.player,
    );
  }

  void _close() {
    Navigator.of(context).pop(
      PathEventVisitResult(
        player: widget.player,
        outcomeText: 'Sales de SU-Basta-Ya sin cerrar ningun trato.',
      ),
    );
  }

  void _advanceFlavorIntro() {
    if (!_isFlavorIntroVisible) return;
    setState(() {
      _flavorPageIndex++;
    });
  }

  Future<void> _selectAuctionItem() async {
    final item = await _selectItem('Selecciona un objeto para subastar');
    if (!mounted || item == null) return;
    setState(() {
      _auctionItem = item;
    });
  }

  Future<void> _selectStatItem() async {
    final item = await _selectItem('Selecciona un objeto para reciclar');
    if (!mounted || item == null) return;
    setState(() {
      _statItem = item;
    });
  }

  Future<Item?> _selectItem(String subtitle) {
    if (_eligibleItems.isEmpty) {
      return Future<Item?>.value();
    }

    return showEndpointOverlay<Item>(
      context: context,
      barrierLabel: 'Seleccionar objeto',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (_) => _SuBastaYaItemSelectionOverlay(
        items: _eligibleItems,
        subtitle: subtitle,
        accent: widget.node.accent,
      ),
    );
  }

  Future<void> _selectSwapAbility() async {
    if (_eligibleAbilities.isEmpty) return;

    final ability = await showEndpointOverlay<BattlerAbility>(
      context: context,
      barrierLabel: 'Seleccionar habilidad',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (_) => _SuBastaYaAbilitySelectionOverlay(
        abilities: _eligibleAbilities,
        accent: widget.node.accent,
      ),
    );
    if (!mounted || ability == null) return;
    setState(() {
      _swapAbility = ability;
    });
  }

  void _resolve(PathEventVisitResult result) {
    if (_isResolving) return;
    setState(() {
      _isResolving = true;
    });
    Navigator.of(context).pop(result);
  }

  void _sellAuctionItem() {
    final item = _auctionItem;
    if (item == null) return;

    _resolve(
      widget.eventService.resolveSuBastaYaAuctionSale(
        player: widget.player,
        selectedItem: item,
      ),
    );
  }

  void _sacrificeStatItem() {
    final item = _statItem;
    if (item == null) return;

    _resolve(
      widget.eventService.resolveSuBastaYaStatSacrifice(
        player: widget.player,
        selectedItem: item,
        selectedReward: _selectedReward,
      ),
    );
  }

  void _swapSelectedAbility() {
    final ability = _swapAbility;
    if (ability == null) return;

    _resolve(
      widget.eventService.resolveSuBastaYaAbilitySwap(
        player: widget.player,
        selectedAbility: ability,
        randomizer: _eventRandomizer,
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
    final auctionItem = _auctionItem;
    final statItem = _statItem;
    final swapAbility = _swapAbility;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: EndpointPanel(
        accent: widget.node.accent,
        backgroundColor: EndpointPalette.panelBackgroundSoft,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _SuBastaYaDealCard(
                  title: 'SUBASTAR',
                  icon: Icons.sell_rounded,
                  accent: auctionItem?.rarity.accent ?? widget.node.accent,
                  body: auctionItem == null
                      ? 'Vende un objeto por encima de su valor normal.'
                      : '${auctionItem.displayName}: ${widget.eventService.suBastaYaAuctionPriceFor(auctionItem)}C',
                  actionLabel: auctionItem == null ? 'Elegir objeto' : 'Vender',
                  actionIcon: auctionItem == null
                      ? Icons.inventory_2_rounded
                      : Icons.payments_rounded,
                  onPressed: _isResolving
                      ? null
                      : auctionItem == null
                          ? _selectAuctionItem
                          : _sellAuctionItem,
                ),
                _SuBastaYaDealCard(
                  title: 'RECICLAR',
                  icon: Icons.auto_fix_high_rounded,
                  accent: statItem?.rarity.accent ?? widget.node.accent,
                  body: statItem == null
                      ? 'Sacrifica un objeto para ganar stats permanentes.'
                      : _statRewardText(statItem),
                  extra: _buildRewardSelector(statItem),
                  actionLabel: statItem == null ? 'Elegir objeto' : 'Reciclar',
                  actionIcon: statItem == null
                      ? Icons.inventory_rounded
                      : Icons.trending_up_rounded,
                  onPressed: _isResolving
                      ? null
                      : statItem == null
                          ? _selectStatItem
                          : _sacrificeStatItem,
                ),
                _SuBastaYaDealCard(
                  title: 'INTERCAMBIAR',
                  icon: Icons.swap_horiz_rounded,
                  accent: swapAbility?.accent ?? widget.node.accent,
                  body: swapAbility == null
                      ? 'Entrega una habilidad y recibe otra del mismo tier o superior.'
                      : swapAbility.displayName,
                  actionLabel:
                      swapAbility == null ? 'Elegir habilidad' : 'Cambiar',
                  actionIcon: swapAbility == null
                      ? Icons.bubble_chart_rounded
                      : Icons.shuffle_rounded,
                  onPressed: _isResolving
                      ? null
                      : swapAbility == null
                          ? _selectSwapAbility
                          : _swapSelectedAbility,
                ),
              ],
            ),
            const SizedBox(height: 12),
            EndpointActionButton(
              label: 'Rechazar todo',
              icon: Icons.close_rounded,
              onPressed: _isResolving ? null : _close,
              tooltip: 'Salir del evento sin cambios',
              accent: EndpointPalette.softForeground.withAlpha(190),
              backgroundColor: EndpointPalette.panelBackgroundMuted,
              foregroundColor: EndpointPalette.softForeground,
              expands: true,
              useMarquee: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildRewardSelector(Item? item) {
    if (item == null || item.rarity == RarityTier.yellow) return null;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final reward in SuBastaYaStatReward.values)
          ChoiceChip(
            label: Text(reward.label),
            selected: _selectedReward == reward,
            onSelected: (_) {
              setState(() {
                _selectedReward = reward;
              });
            },
            selectedColor: reward.stat.accent.withAlpha(72),
            backgroundColor: EndpointPalette.panelBackgroundMuted,
            labelStyle: textSmallBold.copyWith(
              color: _selectedReward == reward
                  ? EndpointPalette.soften(reward.stat.accent)
                  : EndpointPalette.softForeground.withAlpha(190),
              fontSize: 10,
            ),
            side: BorderSide(
              color: reward.stat.accent.withAlpha(
                _selectedReward == reward ? 220 : 90,
              ),
            ),
          ),
      ],
    );
  }

  String _statRewardText(Item item) {
    final rewards = widget.eventService.suBastaYaStatRewardFor(
      item: item,
      selectedReward: _selectedReward,
    );
    final parts = <String>[];
    final hp = rewards[BattlerStat.health] ?? 0;
    if (hp > 0) parts.add('+$hp HP');
    final atk = rewards[BattlerStat.attack] ?? 0;
    if (atk > 0) parts.add('+$atk ATK');
    final barrier = rewards[BattlerStat.barrier] ?? 0;
    if (barrier > 0) parts.add('+$barrier Barrera');
    return '${item.displayName}: ${parts.join(', ')}';
  }
}

class _SuBastaYaDealCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final String body;
  final Widget? extra;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback? onPressed;

  const _SuBastaYaDealCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.body,
    this.extra,
    required this.actionLabel,
    required this.actionIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 206,
      child: EndpointPanel(
        accent: accent,
        backgroundColor: EndpointPalette.blend(
          EndpointPalette.panelBackgroundGold,
          accent,
          0.1,
        ),
        borderRadius: 12,
        glowOpacity: 0.08,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: EndpointPalette.soften(accent), size: 24),
            const SizedBox(height: 6),
            EndpointText(
              title,
              textAlign: TextAlign.center,
              style: textSmallBold.copyWith(
                color: accent,
                fontSize: 10,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            EndpointText(
              body,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: textSmallBold.copyWith(
                color: EndpointPalette.softForeground.withAlpha(210),
                fontSize: 10,
                letterSpacing: 0.6,
              ),
            ),
            if (extra != null) ...[
              const SizedBox(height: 8),
              extra!,
            ],
            const SizedBox(height: 10),
            EndpointActionButton(
              label: actionLabel,
              icon: actionIcon,
              onPressed: onPressed,
              tooltip: actionLabel,
              accent: accent,
              backgroundColor: EndpointPalette.panelBackgroundMuted,
              foregroundColor: EndpointPalette.soften(accent),
              expands: true,
              useMarquee: false,
              labelMaxLines: 1,
              textStyle: textSmallBold,
              iconSize: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuBastaYaItemSelectionOverlay extends StatelessWidget {
  final List<Item> items;
  final String subtitle;
  final Color accent;

  const _SuBastaYaItemSelectionOverlay({
    required this.items,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointOverlayScaffold(
      title: 'SU-Basta-Ya',
      subtitle: subtitle,
      sectionLabel: 'OBJETOS',
      sectionValue: '${items.length}',
      closeTooltip: 'Cerrar seleccion',
      accent: accent,
      bottomInset: 108,
      maxWidth: 460,
      maxHeight: 420,
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              SizedBox(
                width: 86,
                height: 96,
                child: EndpointInventoryItemTile(
                  item: item,
                  onPressed: () => Navigator.of(context).pop(item),
                  backgroundColor: EndpointPalette.panelBackgroundMuted,
                  borderRadius: 12,
                  glowOpacity: 0.08,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuBastaYaAbilitySelectionOverlay extends StatelessWidget {
  final List<BattlerAbility> abilities;
  final Color accent;

  const _SuBastaYaAbilitySelectionOverlay({
    required this.abilities,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointOverlayScaffold(
      title: 'SU-Basta-Ya',
      subtitle: 'Selecciona una habilidad para intercambiar',
      sectionLabel: 'HABILIDADES',
      sectionValue: '${abilities.length}',
      closeTooltip: 'Cerrar seleccion',
      accent: accent,
      bottomInset: 104,
      maxWidth: 420,
      maxHeight: 360,
      child: GridView.builder(
        itemCount: abilities.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 104,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 96,
        ),
        itemBuilder: (context, index) {
          final ability = abilities[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(ability),
              borderRadius: BorderRadius.circular(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EndpointAbilityOrb(
                    ability: ability,
                    size: 58,
                    enableTooltipLongPress: false,
                  ),
                  const SizedBox(height: 6),
                  EndpointText(
                    ability.displayName,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: textSmallBold.copyWith(
                      color: ability.accent,
                      fontSize: 9,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
