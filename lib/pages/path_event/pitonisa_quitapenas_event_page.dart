import '_imports.dart';

class PitonisaQuitapenasEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final PathEventService eventService;

  const PitonisaQuitapenasEventPage({
    super.key,
    required this.player,
    required this.node,
    this.eventService = const PathEventService(),
  });

  @override
  State<PitonisaQuitapenasEventPage> createState() =>
      _PitonisaQuitapenasEventPageState();
}

enum _PitonisaEventStage {
  options,
  purge,
  offering,
  presage,
}

class _PitonisaQuitapenasEventPageState
    extends State<PitonisaQuitapenasEventPage> {
  late final List<BattlerStatus> _debuffs;
  late final List<Item> _items;
  late final List<BattlerAbility> _cooldownAbilities;
  Item? _selectedItem;
  BattlerAbility? _selectedAbility;
  _PitonisaEventStage _stage = _PitonisaEventStage.options;
  int _flavorPageIndex = 0;
  bool _isResolving = false;

  bool get _isFlavorIntroVisible {
    final flavorTexts = widget.node.flavorTexts;
    return flavorTexts.isNotEmpty && _flavorPageIndex < flavorTexts.length;
  }

  @override
  void initState() {
    super.initState();
    _debuffs = widget.eventService.buildPitonisaPurgeableDebuffs(
      widget.player,
    );
    _items = widget.eventService.buildPitonisaItemOfferings(widget.player);
    _cooldownAbilities = widget.eventService.buildPitonisaCooldownAbilities(
      widget.player,
    );
  }

  int get _cooldownReductionCost {
    return widget.eventService.pitonisaCooldownReductionCost;
  }

  String? get _cooldownActionBlockReason {
    final selectedAbility = _selectedAbility;
    if (selectedAbility == null) return null;

    final missingCredits = _cooldownReductionCost - widget.player.money;
    if (missingCredits > 0) {
      return 'Te faltan $missingCredits creditos.';
    }

    return null;
  }

  void _close() {
    Navigator.of(context).pop(
      PathEventVisitResult(
        player: widget.player,
        outcomeText: 'La pitonisa te deja marchar con tus penas intactas.',
      ),
    );
  }

  void _advanceFlavorIntro() {
    if (!_isFlavorIntroVisible) return;
    setState(() {
      _flavorPageIndex++;
    });
  }

  void _chooseStage(_PitonisaEventStage stage) {
    setState(() {
      _stage = stage;
    });
  }

  void _backToOptions() {
    setState(() {
      _stage = _PitonisaEventStage.options;
    });
  }

  void _selectItem(Item item) {
    setState(() {
      _selectedItem = item;
    });
  }

  void _selectAbility(BattlerAbility ability) {
    setState(() {
      _selectedAbility = ability;
    });
  }

  void _resolve(PathEventVisitResult result) {
    if (_isResolving) return;
    setState(() {
      _isResolving = true;
    });
    Navigator.of(context).pop(result);
  }

  void _purgeDebuffs() {
    _resolve(
      widget.eventService.resolvePitonisaDebuffPurge(
        player: widget.player,
      ),
    );
  }

  void _offerItem() {
    final item = _selectedItem;
    if (item == null) return;

    _resolve(
      widget.eventService.resolvePitonisaItemHealing(
        player: widget.player,
        selectedItem: item,
      ),
    );
  }

  void _reduceCooldown() {
    final ability = _selectedAbility;
    if (ability == null) return;

    _resolve(
      widget.eventService.resolvePitonisaCooldownReduction(
        player: widget.player,
        selectedAbility: ability,
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
                label: 'Marcharse',
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
      case _PitonisaEventStage.options:
        return _buildOptionsStage();
      case _PitonisaEventStage.purge:
        return _buildPurgeStage();
      case _PitonisaEventStage.offering:
        return _buildOfferingStage();
      case _PitonisaEventStage.presage:
        return _buildPresageStage();
    }
  }

  Widget _buildOptionsStage() {
    final hasDebuffs = _debuffs.isNotEmpty;
    final hasItems = _items.isNotEmpty;
    final hasCooldownAbilities = _cooldownAbilities.isNotEmpty;
    final missingCredits = _cooldownReductionCost - widget.player.money;

    return Column(
      key: const ValueKey<String>('pitonisa-options'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _PitonisaOptionCard(
          title: 'PURGAR',
          icon: Icons.cleaning_services_rounded,
          accent: EndpointPalette.dangerAccent,
          body: hasDebuffs
              ? 'Elimina ${_debuffs.length} debuffs activos.'
              : 'No tienes debuffs purgables.',
          onPressed: _isResolving || !hasDebuffs
              ? null
              : () => _chooseStage(_PitonisaEventStage.purge),
        ),
        const SizedBox(height: 8),
        _PitonisaOptionCard(
          title: 'OFRENDA',
          icon: Icons.inventory_2_rounded,
          accent: widget.node.accent,
          body: hasItems
              ? 'Entrega un objeto y recupera toda tu vida.'
              : 'No tienes objetos disponibles como ofrenda.',
          onPressed: _isResolving || !hasItems
              ? null
              : () => _chooseStage(_PitonisaEventStage.offering),
        ),
        const SizedBox(height: 8),
        _PitonisaOptionCard(
          title: 'PRESAGIO',
          icon: Icons.av_timer_rounded,
          accent: widget.node.accent,
          body: !hasCooldownAbilities
              ? 'No tienes aumentos con recarga.'
              : missingCredits > 0
                  ? 'Te faltan $missingCredits creditos para reducir un cooldown.'
                  : 'Paga ${_cooldownReductionCost}C para reducir un cooldown permanente.',
          onPressed: _isResolving || !hasCooldownAbilities
              ? null
              : () => _chooseStage(_PitonisaEventStage.presage),
        ),
      ],
    );
  }

  Widget _buildPurgeStage() {
    return Column(
      key: const ValueKey<String>('pitonisa-purge'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _PitonisaStageHeader(
          title: 'PURGAR',
          icon: Icons.cleaning_services_rounded,
          accent: EndpointPalette.dangerAccent,
          onBack: _backToOptions,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final debuff in _debuffs)
              _PitonisaStatusChip(status: debuff, player: widget.player),
          ],
        ),
        const SizedBox(height: 10),
        EndpointActionButton(
          label: 'Quitar penas',
          icon: Icons.backspace_rounded,
          onPressed: _isResolving || _debuffs.isEmpty ? null : _purgeDebuffs,
          tooltip: 'Eliminar debuffs activos',
          accent: EndpointPalette.dangerAccent,
          backgroundColor: EndpointPalette.panelBackgroundMuted,
          foregroundColor: EndpointPalette.soften(EndpointPalette.dangerAccent),
          expands: true,
          useMarquee: false,
        ),
      ],
    );
  }

  Widget _buildOfferingStage() {
    final selectedItem = _selectedItem;

    return Column(
      key: const ValueKey<String>('pitonisa-offering'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _PitonisaStageHeader(
          title: 'OFRENDA',
          icon: Icons.inventory_2_rounded,
          accent: selectedItem?.rarity.accent ?? widget.node.accent,
          onBack: _backToOptions,
        ),
        const SizedBox(height: 10),
        _buildItemPicker(),
        if (selectedItem != null) ...[
          const SizedBox(height: 8),
          EndpointText(
            '${selectedItem.displayName}: curar al maximo',
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
          label: selectedItem == null ? 'Elige un objeto' : 'Entregar',
          icon: Icons.favorite_rounded,
          onPressed: _isResolving || selectedItem == null ? null : _offerItem,
          tooltip: 'Entregar ofrenda',
          accent: selectedItem?.rarity.accent ?? widget.node.accent,
          backgroundColor: EndpointPalette.panelBackgroundMuted,
          foregroundColor: EndpointPalette.soften(
            selectedItem?.rarity.accent ?? widget.node.accent,
          ),
          expands: true,
          useMarquee: false,
        ),
      ],
    );
  }

  Widget _buildPresageStage() {
    final selectedAbility = _selectedAbility;
    final cooldownBlockReason = _cooldownActionBlockReason;

    return Column(
      key: const ValueKey<String>('pitonisa-presage'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _PitonisaStageHeader(
          title: 'PRESAGIO',
          icon: Icons.av_timer_rounded,
          accent: selectedAbility?.accent ?? widget.node.accent,
          onBack: _backToOptions,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final ability in _cooldownAbilities)
              _PitonisaAbilityPickTile(
                ability: ability,
                isSelected: selectedAbility?.id == ability.id,
                onPressed: () => _selectAbility(ability),
              ),
          ],
        ),
        if (selectedAbility != null) ...[
          const SizedBox(height: 8),
          EndpointText(
            cooldownBlockReason ??
                '${selectedAbility.displayName}: ${selectedAbility.cooldownTurns} -> ${max(0, selectedAbility.cooldownTurns - 1)} turnos por ${_cooldownReductionCost}C',
            textAlign: TextAlign.center,
            maxLines: null,
            style: textSmallBold.copyWith(
              color: cooldownBlockReason == null
                  ? EndpointPalette.softForeground.withAlpha(214)
                  : EndpointPalette.dangerAccent,
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 10),
        EndpointActionButton(
          label:
              selectedAbility == null ? 'Elige un aumento' : 'Reducir cooldown',
          icon: Icons.update_rounded,
          onPressed: _isResolving ||
                  selectedAbility == null ||
                  cooldownBlockReason != null
              ? null
              : _reduceCooldown,
          tooltip: cooldownBlockReason ?? 'Reducir cooldown permanente',
          accent: selectedAbility?.accent ?? widget.node.accent,
          backgroundColor: EndpointPalette.panelBackgroundMuted,
          foregroundColor: EndpointPalette.soften(
            selectedAbility?.accent ?? widget.node.accent,
          ),
          expands: true,
          useMarquee: false,
        ),
      ],
    );
  }

  Widget _buildItemPicker() {
    final selectedItem = _selectedItem;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final item in _items)
          SizedBox(
            width: 82,
            height: 92,
            child: EndpointInventoryItemTile(
              item: item,
              onPressed: () => _selectItem(item),
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
}

class _PitonisaOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final String body;
  final VoidCallback? onPressed;

  const _PitonisaOptionCard({
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

class _PitonisaStageHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback onBack;

  const _PitonisaStageHeader({
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

class _PitonisaStatusChip extends StatelessWidget {
  final BattlerStatus status;
  final Battler player;

  const _PitonisaStatusChip({
    required this.status,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedStatus = status.resolved(player);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.panelBackgroundBattleOpaque,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: resolvedStatus.type.accent.withAlpha(156),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              resolvedStatus.icon,
              color: resolvedStatus.type.accent,
              size: 16,
            ),
            const SizedBox(width: 4),
            EndpointText(
              resolvedStatus.badgeLabelFor(player),
              style: textSmallBold.copyWith(
                color: EndpointPalette.softForeground,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PitonisaAbilityPickTile extends StatelessWidget {
  final BattlerAbility ability;
  final bool isSelected;
  final VoidCallback onPressed;

  const _PitonisaAbilityPickTile({
    required this.ability,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = ability.accent;

    return SizedBox(
      width: 94,
      height: 104,
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
                  const SizedBox(height: 3),
                  EndpointText(
                    '${ability.cooldownTurns} -> ${max(0, ability.cooldownTurns - 1)}',
                    textAlign: TextAlign.center,
                    style: textSmallNumericBold.copyWith(
                      color: EndpointPalette.warningAccent,
                      fontSize: 9,
                      letterSpacing: 0.8,
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
