import '_imports.dart';

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

enum _SuBastaYaEventStage {
  options,
  auction,
  stats,
  ability,
}

class _SuBastaYaEventPageState extends State<SuBastaYaEventPage> {
  late final RunRandomizer _eventRandomizer;
  late final List<Item> _eligibleItems;
  late final List<BattlerAbility> _eligibleAbilities;
  Item? _auctionItem;
  Item? _statItem;
  BattlerAbility? _swapAbility;
  SuBastaYaStatReward _selectedReward = SuBastaYaStatReward.health;
  _SuBastaYaEventStage _stage = _SuBastaYaEventStage.options;
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

  void _chooseStage(_SuBastaYaEventStage stage) {
    setState(() {
      _stage = stage;
    });
  }

  void _backToOptions() {
    setState(() {
      _stage = _SuBastaYaEventStage.options;
    });
  }

  void _selectAuctionItem(Item item) {
    setState(() {
      _auctionItem = item;
    });
  }

  void _selectStatItem(Item item) {
    setState(() {
      _statItem = item;
    });
  }

  void _selectSwapAbility(BattlerAbility ability) {
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
      emojiSize: 108,
      title: widget.node.eventTitle,
      content: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxPanelHeight = min(430.0, max(300.0, screenHeight - 270.0));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 700,
        maxHeight: maxPanelHeight,
      ),
      child: EndpointPanel(
        accent: widget.node.accent,
        backgroundColor: EndpointPalette.panelBackgroundSoft,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: SingleChildScrollView(
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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                reverseDuration: const Duration(milliseconds: 140),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(1.12, 0),
                    end: Offset.zero,
                  ).animate(animation);

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offset,
                      child: child,
                    ),
                  );
                },
                child: _buildStageContent(),
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
      ),
    );
  }

  Widget _buildStageContent() {
    switch (_stage) {
      case _SuBastaYaEventStage.options:
        return _buildOptionsStage();
      case _SuBastaYaEventStage.auction:
        return _buildAuctionStage();
      case _SuBastaYaEventStage.stats:
        return _buildStatsStage();
      case _SuBastaYaEventStage.ability:
        return _buildAbilityStage();
    }
  }

  Widget _buildOptionsStage() {
    final hasItems = _eligibleItems.isNotEmpty;
    final hasAbilities = _eligibleAbilities.isNotEmpty;

    return Column(
      key: const ValueKey<String>('su-basta-options'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _SuBastaYaOptionCard(
          title: 'SUBASTAR',
          icon: Icons.sell_rounded,
          accent: widget.node.accent,
          body: hasItems
              ? 'Vende un objeto por encima de su valor normal.'
              : 'No tienes objetos disponibles para subastar.',
          onPressed: _isResolving || !hasItems
              ? null
              : () => _chooseStage(_SuBastaYaEventStage.auction),
        ),
        const SizedBox(height: 8),
        _SuBastaYaOptionCard(
          title: 'RECICLAR',
          icon: Icons.auto_fix_high_rounded,
          accent: widget.node.accent,
          body: hasItems
              ? 'Sacrifica un objeto para ganar stats permanentes.'
              : 'No tienes objetos disponibles para reciclar.',
          onPressed: _isResolving || !hasItems
              ? null
              : () => _chooseStage(_SuBastaYaEventStage.stats),
        ),
        const SizedBox(height: 8),
        _SuBastaYaOptionCard(
          title: 'INTERCAMBIAR',
          icon: Icons.swap_horiz_rounded,
          accent: widget.node.accent,
          body: hasAbilities
              ? 'Entrega un aumento y recibe otro del mismo tier o superior.'
              : 'No tienes aumentos disponibles para intercambiar.',
          onPressed: _isResolving || !hasAbilities
              ? null
              : () => _chooseStage(_SuBastaYaEventStage.ability),
        ),
      ],
    );
  }

  Widget _buildAuctionStage() {
    final auctionItem = _auctionItem;

    return Column(
      key: const ValueKey<String>('su-basta-auction'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _SuBastaYaStageHeader(
          title: 'SUBASTAR',
          icon: Icons.sell_rounded,
          accent: auctionItem?.rarity.accent ?? widget.node.accent,
          onBack: _backToOptions,
        ),
        const SizedBox(height: 10),
        _buildItemPicker(
          selectedItem: auctionItem,
          onSelected: _selectAuctionItem,
        ),
        const SizedBox(height: 10),
        EndpointActionButton(
          label: auctionItem == null
              ? 'Elige un objeto'
              : 'Vender por ${widget.eventService.suBastaYaAuctionPriceFor(auctionItem)}C',
          icon: Icons.payments_rounded,
          onPressed:
              _isResolving || auctionItem == null ? null : _sellAuctionItem,
          tooltip: 'Subastar objeto',
          accent: auctionItem?.rarity.accent ?? widget.node.accent,
          backgroundColor: EndpointPalette.panelBackgroundMuted,
          foregroundColor: EndpointPalette.soften(
              auctionItem?.rarity.accent ?? widget.node.accent),
          expands: true,
          useMarquee: false,
        ),
      ],
    );
  }

  Widget _buildStatsStage() {
    final statItem = _statItem;

    return Column(
      key: const ValueKey<String>('su-basta-stats'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _SuBastaYaStageHeader(
          title: 'RECICLAR',
          icon: Icons.auto_fix_high_rounded,
          accent: statItem?.rarity.accent ?? widget.node.accent,
          onBack: _backToOptions,
        ),
        const SizedBox(height: 10),
        _buildItemPicker(
          selectedItem: statItem,
          onSelected: _selectStatItem,
        ),
        if (statItem != null) ...[
          const SizedBox(height: 10),
          _buildRewardSelector(statItem) ?? const SizedBox.shrink(),
          const SizedBox(height: 8),
          EndpointText(
            _statRewardText(statItem),
            textAlign: TextAlign.center,
            maxLines: null,
            style: textSmallBold.copyWith(
              color: EndpointPalette.softForeground.withAlpha(214),
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 10),
        EndpointActionButton(
          label: statItem == null ? 'Elige un objeto' : 'Reciclar',
          icon: Icons.trending_up_rounded,
          onPressed:
              _isResolving || statItem == null ? null : _sacrificeStatItem,
          tooltip: 'Reciclar objeto',
          accent: statItem?.rarity.accent ?? widget.node.accent,
          backgroundColor: EndpointPalette.panelBackgroundMuted,
          foregroundColor: EndpointPalette.soften(
              statItem?.rarity.accent ?? widget.node.accent),
          expands: true,
          useMarquee: false,
        ),
      ],
    );
  }

  Widget _buildAbilityStage() {
    final swapAbility = _swapAbility;

    return Column(
      key: const ValueKey<String>('su-basta-ability'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _SuBastaYaStageHeader(
          title: 'INTERCAMBIAR',
          icon: Icons.swap_horiz_rounded,
          accent: swapAbility?.accent ?? widget.node.accent,
          onBack: _backToOptions,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final ability in _eligibleAbilities)
              _SuBastaYaAbilityPickTile(
                ability: ability,
                isSelected: swapAbility?.id == ability.id,
                onPressed: () => _selectSwapAbility(ability),
              ),
          ],
        ),
        const SizedBox(height: 10),
        EndpointActionButton(
          label: swapAbility == null ? 'Elige un aumento' : 'Cambiar',
          icon: Icons.shuffle_rounded,
          onPressed:
              _isResolving || swapAbility == null ? null : _swapSelectedAbility,
          tooltip: 'Intercambiar aumento',
          accent: swapAbility?.accent ?? widget.node.accent,
          backgroundColor: EndpointPalette.panelBackgroundMuted,
          foregroundColor:
              EndpointPalette.soften(swapAbility?.accent ?? widget.node.accent),
          expands: true,
          useMarquee: false,
        ),
      ],
    );
  }

  Widget _buildItemPicker({
    required Item? selectedItem,
    required ValueChanged<Item> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final item in _eligibleItems)
          SizedBox(
            width: 82,
            height: 92,
            child: EndpointInventoryItemTile(
              item: item,
              onPressed: () => onSelected(item),
              backgroundColor: EndpointPalette.blend(
                EndpointPalette.panelBackgroundMuted,
                item.rarity.accent,
                selectedItem == item ? 0.22 : 0.04,
              ),
              borderRadius: 12,
              glowOpacity: selectedItem == item ? 0.18 : 0.08,
            ),
          ),
      ],
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

class _SuBastaYaOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final String body;
  final VoidCallback? onPressed;

  const _SuBastaYaOptionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.body,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: EndpointPalette.blend(
              EndpointPalette.panelBackgroundGold,
              accent,
              isEnabled ? 0.12 : 0.04,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withAlpha(isEnabled ? 156 : 64),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: EndpointPalette.panelBackgroundBattleOpaque,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withAlpha(128)),
                    ),
                    child: Icon(
                      icon,
                      color: isEnabled
                          ? EndpointPalette.soften(accent)
                          : EndpointPalette.softForeground.withAlpha(112),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EndpointText(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textSmallBold.copyWith(
                          color: isEnabled
                              ? accent
                              : EndpointPalette.softForeground.withAlpha(120),
                          fontSize: 11,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      EndpointText(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textSmallBold.copyWith(
                          color: EndpointPalette.softForeground.withAlpha(
                            isEnabled ? 210 : 128,
                          ),
                          fontSize: 10,
                          letterSpacing: 0.45,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isEnabled
                      ? EndpointPalette.soften(accent)
                      : EndpointPalette.softForeground.withAlpha(96),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuBastaYaStageHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback onBack;

  const _SuBastaYaStageHeader({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HoldTooltip(
          message: 'Elegir otro trato',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 40,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: EndpointPalette.panelBackgroundMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: EndpointPalette.soften(accent),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: EndpointPalette.soften(accent), size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: EndpointText(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textMediumBold.copyWith(
              color: accent,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _SuBastaYaAbilityPickTile extends StatelessWidget {
  final BattlerAbility ability;
  final bool isSelected;
  final VoidCallback onPressed;

  const _SuBastaYaAbilityPickTile({
    required this.ability,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = ability.accent;

    return SizedBox(
      width: 94,
      height: 96,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: EndpointPalette.blend(
                EndpointPalette.panelBackgroundMuted,
                accent,
                isSelected ? 0.24 : 0.06,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withAlpha(isSelected ? 210 : 82),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 7, 6, 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EndpointAbilityOrb(
                    ability: ability,
                    size: 54,
                    enableTooltipLongPress: false,
                  ),
                  const SizedBox(height: 5),
                  EndpointText(
                    ability.displayName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textSmallBold.copyWith(
                      color: EndpointPalette.soften(accent),
                      fontSize: 9,
                      letterSpacing: 0.5,
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
