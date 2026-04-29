import '../_imports.dart';

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

class _PitonisaQuitapenasEventPageState
    extends State<PitonisaQuitapenasEventPage> {
  late final List<BattlerStatus> _debuffs;
  late final List<Item> _items;
  late final List<BattlerAbility> _cooldownAbilities;
  Item? _selectedItem;
  BattlerAbility? _selectedAbility;
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
    if (_cooldownAbilities.isEmpty) {
      return 'No tienes habilidades manuales con cooldown.';
    }
    if (_selectedAbility == null) {
      return null;
    }

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

  Future<void> _selectItem() async {
    if (_items.isEmpty) return;

    final item = await showEndpointOverlay<Item>(
      context: context,
      barrierLabel: 'Seleccionar ofrenda',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (_) => _PitonisaItemSelectionOverlay(
        items: _items,
        accent: widget.node.accent,
      ),
    );
    if (!mounted || item == null) return;
    setState(() {
      _selectedItem = item;
    });
  }

  Future<void> _selectAbility() async {
    if (_cooldownAbilities.isEmpty) return;

    final ability = await showEndpointOverlay<BattlerAbility>(
      context: context,
      barrierLabel: 'Seleccionar habilidad',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (_) => _PitonisaAbilitySelectionOverlay(
        abilities: _cooldownAbilities,
        accent: widget.node.accent,
      ),
    );
    if (!mounted || ability == null) return;
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
      title: widget.node.eventTitle,
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    final selectedItem = _selectedItem;
    final selectedAbility = _selectedAbility;
    final cooldownCost = _cooldownReductionCost;
    final cooldownBlockReason = _cooldownActionBlockReason;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 660),
      child: EndpointPanel(
        accent: widget.node.accent,
        backgroundColor: EndpointPalette.panelBackgroundSoft,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _PitonisaDealCard(
                  title: 'PURGAR',
                  icon: Icons.cleaning_services_rounded,
                  accent: EndpointPalette.dangerAccent,
                  body: _debuffs.isEmpty
                      ? 'No tienes debuffs purgables.'
                      : 'Elimina ${_debuffs.length} debuffs activos.',
                  actionLabel: 'Quitar penas',
                  actionIcon: Icons.backspace_rounded,
                  onPressed:
                      _isResolving || _debuffs.isEmpty ? null : _purgeDebuffs,
                ),
                _PitonisaDealCard(
                  title: 'OFRENDA',
                  icon: Icons.inventory_2_rounded,
                  accent: selectedItem?.rarity.accent ?? widget.node.accent,
                  body: selectedItem == null
                      ? 'Entrega un objeto y recupera toda tu vida.'
                      : '${selectedItem.displayName}: curar al maximo',
                  actionLabel:
                      selectedItem == null ? 'Elegir objeto' : 'Entregar',
                  actionIcon: selectedItem == null
                      ? Icons.inventory_rounded
                      : Icons.favorite_rounded,
                  onPressed: _isResolving
                      ? null
                      : selectedItem == null
                          ? _selectItem
                          : _offerItem,
                ),
                _PitonisaDealCard(
                  title: 'PRESAGIO',
                  icon: Icons.av_timer_rounded,
                  accent: selectedAbility?.accent ?? widget.node.accent,
                  body: selectedAbility == null
                      ? _cooldownAbilities.isEmpty
                          ? 'No tienes habilidades manuales con cooldown.'
                          : 'Paga ${cooldownCost}C para reducir en 1 el cooldown permanente de una habilidad manual.'
                      : cooldownBlockReason ??
                          '${selectedAbility.displayName}: ${selectedAbility.cooldownTurns} -> ${max(0, selectedAbility.cooldownTurns - 1)} turnos por ${cooldownCost}C',
                  actionLabel: selectedAbility == null
                      ? 'Elegir habilidad'
                      : 'Reducir cooldown',
                  actionIcon: selectedAbility == null
                      ? Icons.bubble_chart_rounded
                      : Icons.update_rounded,
                  tooltip: cooldownBlockReason ?? 'Reducir cooldown permanente',
                  onPressed: _isResolving || cooldownBlockReason != null
                      ? null
                      : selectedAbility == null
                          ? _selectAbility
                          : _reduceCooldown,
                ),
              ],
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
    );
  }
}

class _PitonisaDealCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final String body;
  final String actionLabel;
  final IconData actionIcon;
  final String? tooltip;
  final VoidCallback? onPressed;

  const _PitonisaDealCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.body,
    required this.actionLabel,
    required this.actionIcon,
    this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 202,
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
            const SizedBox(height: 10),
            EndpointActionButton(
              label: actionLabel,
              icon: actionIcon,
              onPressed: onPressed,
              tooltip: tooltip ?? actionLabel,
              accent: accent,
              backgroundColor: EndpointPalette.panelBackgroundMuted,
              foregroundColor: EndpointPalette.soften(accent),
              expands: true,
              useMarquee: false,
              textStyle: textSmallBold,
              iconSize: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _PitonisaItemSelectionOverlay extends StatelessWidget {
  final List<Item> items;
  final Color accent;

  const _PitonisaItemSelectionOverlay({
    required this.items,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointOverlayScaffold(
      title: 'Pitonisa Quitapenas',
      subtitle: 'Selecciona una ofrenda',
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

class _PitonisaAbilitySelectionOverlay extends StatelessWidget {
  final List<BattlerAbility> abilities;
  final Color accent;

  const _PitonisaAbilitySelectionOverlay({
    required this.abilities,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointOverlayScaffold(
      title: 'Pitonisa Quitapenas',
      subtitle: 'Selecciona una habilidad manual',
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
          mainAxisExtent: 102,
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
          );
        },
      ),
    );
  }
}
