import '_imports.dart';

class SobreKarEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final RunRandomizer? randomizer;
  final PathEventService eventService;

  const SobreKarEventPage({
    super.key,
    required this.player,
    required this.node,
    this.randomizer,
    this.eventService = const PathEventService(),
  });

  @override
  State<SobreKarEventPage> createState() => _SobreKarEventPageState();
}

class _SobreKarEventPageState extends State<SobreKarEventPage> {
  late final RunRandomizer _eventRandomizer;
  late final List<Item> _eligibleEquippedItems;
  late final List<Item> _eligibleInventoryItems;
  Item? _selectedItem;
  bool _isResolvingUpgrade = false;
  int _flavorPageIndex = 0;

  List<Item> get _eligibleItems => [
        ..._eligibleEquippedItems,
        ..._eligibleInventoryItems,
      ];

  bool get _isFlavorIntroVisible {
    final flavorTexts = widget.node.flavorTexts;
    return flavorTexts.isNotEmpty && _flavorPageIndex < flavorTexts.length;
  }

  String? get _selectionBlockReason {
    if (_eligibleItems.isEmpty) {
      return 'No tienes objetos compatibles. SobreKar no acepta tier amarillo.';
    }

    final selectedItem = _selectedItem;
    if (selectedItem == null) return 'Selecciona un objeto';
    if (!_eligibleItems.contains(selectedItem)) {
      return 'El objeto seleccionado ya no esta disponible';
    }
    if (selectedItem.rarity == RarityTier.yellow) {
      return 'SobreKar no acepta objetos de tier amarillo';
    }
    if (!selectedItem.canUpgrade) {
      return 'Este objeto no puede mejorarse';
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _eventRandomizer = widget.randomizer ?? RunRandomizer();
    final eligibleItems = widget.eventService.buildSobreKarEligibleItems(
      widget.player,
    );
    _eligibleEquippedItems = eligibleItems
        .where((item) => widget.player.equippedItems.contains(item))
        .toList(growable: false);
    _eligibleInventoryItems = eligibleItems
        .where((item) => widget.player.inventoryItems.contains(item))
        .toList(growable: false);
  }

  void _close() {
    Navigator.of(context).pop(
      PathEventVisitResult(
        player: widget.player,
        outcomeText: 'SobreKar se queda esperando otra demostracion.',
      ),
    );
  }

  void _advanceFlavorIntro() {
    if (!_isFlavorIntroVisible) return;
    setState(() {
      _flavorPageIndex++;
    });
  }

  Future<void> _openItemSelection() async {
    if (_eligibleItems.isEmpty) return;

    final selectedItem = await showEndpointOverlay<Item>(
      context: context,
      barrierLabel: 'Seleccionar objeto',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (_) => _SobreKarItemSelectionOverlay(
        equippedItems: _eligibleEquippedItems,
        inventoryItems: _eligibleInventoryItems,
        accent: widget.node.accent,
      ),
    );
    if (!mounted || selectedItem == null) return;

    setState(() {
      _selectedItem = selectedItem;
    });
  }

  Future<void> _upgradeSelectedItem() async {
    final selectedItem = _selectedItem;
    if (_isResolvingUpgrade ||
        selectedItem == null ||
        _selectionBlockReason != null) {
      return;
    }

    setState(() {
      _isResolvingUpgrade = true;
    });

    final resolution = widget.eventService.resolveSobreKarUpgrade(
      player: widget.player,
      selectedItem: selectedItem,
      randomizer: _eventRandomizer,
    );
    if (resolution == null) {
      if (mounted) {
        setState(() {
          _isResolvingUpgrade = false;
        });
      }
      return;
    }

    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Resultado de SobreKar',
      barrierDismissible: false,
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return _SobreKarResultDialog(
          resolution: resolution,
          accent: widget.node.accent,
        );
      },
    );
    if (!mounted) return;

    Navigator.of(context).pop(resolution.visitResult);
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
    final blockReason = _selectionBlockReason;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
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
            _SobreKarItemSlot(
              item: selectedItem,
              accent: selectedItem?.rarity.accent ?? widget.node.accent,
              onPressed: _eligibleItems.isEmpty ? null : _openItemSelection,
            ),
            const SizedBox(height: 8),
            EndpointText(
              'Solo objetos no amarillos',
              textAlign: TextAlign.center,
              style: textSmallBold.copyWith(
                color: EndpointPalette.warningAccent,
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            EndpointActionButton(
              label: 'MEJORAR',
              icon: Icons.upgrade_rounded,
              onPressed: blockReason == null && !_isResolvingUpgrade
                  ? _upgradeSelectedItem
                  : null,
              tooltip: blockReason ?? 'Aplicar mejora y resolver efecto',
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
}

class _SobreKarItemSlot extends StatelessWidget {
  final Item? item;
  final Color accent;
  final VoidCallback? onPressed;

  const _SobreKarItemSlot({
    required this.item,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final selectedItem = item;
    final slot = EndpointPanel(
      accent: accent,
      backgroundColor: EndpointPalette.blend(
        EndpointPalette.panelBackgroundGold,
        accent,
        0.16,
      ),
      borderRadius: 16,
      glowOpacity: 0.1,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: SizedBox(
        width: 132,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/slots/equipment_slot_base.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                  ),
                  Center(
                    child: selectedItem == null
                        ? Icon(
                            Icons.add_rounded,
                            color: EndpointPalette.soften(accent),
                            size: 32,
                          )
                        : EndpointText(
                            selectedItem.iconEmoji,
                            style: const TextStyle(fontSize: 32, height: 1),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            EndpointText(
              selectedItem?.displayName ?? 'Seleccionar objeto',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textSmallBold.copyWith(
                color: selectedItem?.rarity.accent ??
                    EndpointPalette.softForeground.withAlpha(220),
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );

    if (onPressed == null) return slot;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: slot,
      ),
    );
  }
}

class _SobreKarItemSelectionOverlay extends StatelessWidget {
  final List<Item> equippedItems;
  final List<Item> inventoryItems;
  final Color accent;

  const _SobreKarItemSelectionOverlay({
    required this.equippedItems,
    required this.inventoryItems,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnyItems = equippedItems.isNotEmpty || inventoryItems.isNotEmpty;
    return EndpointOverlayScaffold(
      title: 'SobreKar',
      subtitle: 'Selecciona un objeto para mejorar',
      sectionLabel: 'OBJETOS',
      sectionValue: '${equippedItems.length + inventoryItems.length}',
      closeTooltip: 'Cerrar seleccion',
      accent: accent,
      bottomInset: 108,
      maxWidth: 440,
      maxHeight: 420,
      child: !hasAnyItems
          ? Center(
              child: EndpointText(
                'No hay objetos compatibles.',
                textAlign: TextAlign.center,
                style: textSmallBold.copyWith(
                  color: EndpointPalette.softForeground.withAlpha(184),
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (equippedItems.isNotEmpty) ...[
                    _SobreKarSelectionSection(
                      label: 'EQUIPADOS',
                      accent: accent,
                      items: equippedItems,
                      onPressed: (item) => Navigator.of(context).pop(item),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (inventoryItems.isNotEmpty)
                    _SobreKarSelectionSection(
                      label: 'INVENTARIO',
                      accent: accent,
                      items: inventoryItems,
                      onPressed: (item) => Navigator.of(context).pop(item),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SobreKarSelectionSection extends StatelessWidget {
  final String label;
  final Color accent;
  final List<Item> items;
  final void Function(Item item) onPressed;

  const _SobreKarSelectionSection({
    required this.label,
    required this.accent,
    required this.items,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EndpointText(
          label,
          style: textSmallBold.copyWith(
            color: accent,
            fontSize: 10,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              SizedBox(
                width: 82,
                height: 92,
                child: EndpointInventoryItemTile(
                  item: item,
                  onPressed: () => onPressed(item),
                  backgroundColor: EndpointPalette.panelBackgroundMuted,
                  borderRadius: 12,
                  glowOpacity: 0.08,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SobreKarResultDialog extends StatefulWidget {
  final SobreKarUpgradeResolution resolution;
  final Color accent;

  const _SobreKarResultDialog({
    required this.resolution,
    required this.accent,
  });

  @override
  State<_SobreKarResultDialog> createState() => _SobreKarResultDialogState();
}

class _SobreKarResultDialogState extends State<_SobreKarResultDialog> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(
      const Duration(milliseconds: 1050),
      () {
        if (!mounted) return;
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final upgradedItem = widget.resolution.upgradedItem;
    final debuff = widget.resolution.appliedDebuff;
    final upgradedAccent = upgradedItem.rarity.accent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 370),
          child: EndpointPanel(
            accent: widget.accent,
            backgroundColor: EndpointPalette.panelBackgroundGold,
            borderRadius: 18,
            glowOpacity: 0.18,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EndpointText(
                  'MEJORA COMPLETADA',
                  textAlign: TextAlign.center,
                  style: textMediumBold.copyWith(
                    color: EndpointPalette.soften(widget.accent),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SobreKarResultOrb(
                      emoji: upgradedItem.iconEmoji,
                      accent: upgradedAccent,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: EndpointPalette.warningAccent,
                      ),
                    ),
                    _SobreKarResultOrb(
                      icon: debuff.icon,
                      accent: debuff.type.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                EndpointText(
                  widget.resolution.visitResult.outcomeText,
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

class _SobreKarResultOrb extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final Color accent;

  const _SobreKarResultOrb({
    this.emoji,
    this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      accent: accent,
      backgroundColor: EndpointPalette.blend(
        EndpointPalette.panelBackgroundStrong,
        accent,
        0.12,
      ),
      borderRadius: 12,
      glowOpacity: 0.08,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: icon != null
          ? Icon(
              icon,
              color: EndpointPalette.soften(accent),
              size: 24,
            )
          : EndpointText(
              emoji ?? '\u26A0',
              style: const TextStyle(fontSize: 24, height: 1),
            ),
    );
  }
}
