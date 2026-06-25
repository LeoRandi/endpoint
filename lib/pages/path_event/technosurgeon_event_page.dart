import '_imports.dart';

class TechnosurgeonEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final RunRandomizer? randomizer;
  final PathEventService eventService;

  const TechnosurgeonEventPage({
    super.key,
    required this.player,
    required this.node,
    this.randomizer,
    this.eventService = const PathEventService(),
  });

  @override
  State<TechnosurgeonEventPage> createState() => _TechnosurgeonEventPageState();
}

class _TechnosurgeonEventPageState extends State<TechnosurgeonEventPage> {
  late final RunRandomizer _eventRandomizer;
  final Random _visualRandom = Random();
  PathEventVisitResult? _visitResult;
  Augment? _selectedAugment;
  Augment? _previewAugment;
  Timer? _previewTimer;
  int _flavorPageIndex = 0;

  bool get _hasResolvedTechnosurgeon => _visitResult?.gainedAugment != null;

  bool get _isFlavorIntroVisible {
    final flavorTexts = widget.node.flavorTexts;
    return flavorTexts.isNotEmpty && _flavorPageIndex < flavorTexts.length;
  }

  @override
  void initState() {
    super.initState();
    _eventRandomizer = widget.randomizer ?? RunRandomizer();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop(
      _visitResult ??
          PathEventVisitResult(
            player: widget.player,
            outcomeText: 'La intervencion queda cancelada.',
          ),
    );
  }

  void _advanceFlavorIntro() {
    if (!_isFlavorIntroVisible) return;
    setState(() {
      _flavorPageIndex++;
    });
  }

  Future<void> _selectAugment() async {
    if (_hasResolvedTechnosurgeon || widget.player.augments.isEmpty) return;

    final selectedAugment = await showEndpointOverlay<Augment>(
      context: context,
      barrierLabel: 'Seleccionar aumento',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (_) => _TechnosurgeonAugmentSelectionOverlay(
        augments: widget.player.augments,
        accent: widget.node.accent,
      ),
    );
    if (!mounted || selectedAugment == null) return;

    setState(() {
      _selectedAugment = selectedAugment;
    });
    _startPreviewTicker();
  }

  void _startPreviewTicker() {
    _previewTimer?.cancel();
    _rollVisualPreviewAugment();
    _previewTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (!mounted || _hasResolvedTechnosurgeon) return;
        setState(_rollVisualPreviewAugment);
      },
    );
  }

  void _rollVisualPreviewAugment() {
    final selectedAugment = _selectedAugment;
    var candidates = augmentCatalogForArchetype(widget.player.archetypeId)
        .where((augment) => augment.id != selectedAugment?.id)
        .toList(growable: false);
    if (candidates.isEmpty) {
      candidates = augmentCatalog
          .where((augment) => augment.id != selectedAugment?.id)
          .toList(growable: false);
    }
    if (candidates.isEmpty) return;

    var nextAugment = candidates[_visualRandom.nextInt(candidates.length)];
    if (candidates.length > 1 && nextAugment.id == _previewAugment?.id) {
      final currentIndex = candidates.indexWhere(
        (augment) => augment.id == nextAugment.id,
      );
      final offset = 1 + _visualRandom.nextInt(candidates.length - 1);
      nextAugment = candidates[(currentIndex + offset) % candidates.length];
    }
    _previewAugment = nextAugment;
  }

  void _assumeTechnosurgeonChange() {
    final selectedAugment = _selectedAugment;
    if (selectedAugment == null || _hasResolvedTechnosurgeon) return;

    _previewTimer?.cancel();
    final result = widget.eventService.resolveTechnosurgeonMutation(
      node: widget.node,
      player: widget.player,
      selectedAugment: selectedAugment,
      randomizer: _eventRandomizer,
    );

    setState(() {
      _visitResult = result;
      _previewAugment = result.gainedAugment;
    });
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
      content: _buildTechnosurgeonContent(),
    );
  }

  Widget _buildTechnosurgeonContent() {
    final selectedAugment = _selectedAugment;
    final previewAugment = _previewAugment;
    final gainedAugment = _visitResult?.gainedAugment;
    final canAssumeChange =
        selectedAugment != null && !_hasResolvedTechnosurgeon;
    final hasAugments = widget.player.augments.isNotEmpty;
    final leftOrb = _TechnosurgeonOrbPanel(
      label: 'ENTREGA',
      caption: selectedAugment == null
          ? hasAugments
              ? 'Pulsa para elegir'
              : 'Sin aumentos'
          : 'Aumento seleccionado',
      augment: selectedAugment,
      accent: selectedAugment?.accent ?? widget.node.accent,
      isSelectable: hasAugments && !_hasResolvedTechnosurgeon,
      onPressed:
          hasAugments && !_hasResolvedTechnosurgeon ? _selectAugment : null,
    );
    final rightOrb = _TechnosurgeonOrbPanel(
      label: 'MUTACION',
      caption: _hasResolvedTechnosurgeon
          ? 'Resultado estable'
          : selectedAugment == null
              ? 'Esperando muestra'
              : 'Muestra inestable',
      augment: gainedAugment ?? previewAugment,
      accent: (gainedAugment ?? previewAugment)?.accent ?? widget.node.accent,
      isAnimating: selectedAugment != null && !_hasResolvedTechnosurgeon,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EndpointText(
            widget.node.description,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: textMedium.copyWith(
              color: EndpointPalette.softForeground.withAlpha(214),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: leftOrb),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.keyboard_double_arrow_right_rounded,
                  color: widget.node.accent,
                ),
              ),
              Expanded(child: rightOrb),
            ],
          ),
          if (_visitResult != null) ...[
            const SizedBox(height: 10),
            _TechnosurgeonResultCard(
              augment: gainedAugment,
              outcomeText: _visitResult!.outcomeText,
              accent: widget.node.accent,
            ),
          ],
          const SizedBox(height: 10),
          EndpointActionButton(
            label: _hasResolvedTechnosurgeon ? 'Cerrar' : 'Asumir el cambio',
            icon: _hasResolvedTechnosurgeon
                ? Icons.check_rounded
                : Icons.auto_fix_high_rounded,
            onPressed: _hasResolvedTechnosurgeon
                ? _close
                : canAssumeChange
                    ? _assumeTechnosurgeonChange
                    : null,
            tooltip: _hasResolvedTechnosurgeon
                ? EndpointStrings.backToRoute
                : canAssumeChange
                    ? 'Reemplazar el aumento seleccionado por uno de tier superior'
                    : 'Primero selecciona un aumento',
            accent: selectedAugment?.accent ?? widget.node.accent,
            backgroundColor: EndpointPalette.blend(
              EndpointPalette.panelBackgroundGold,
              selectedAugment?.accent ?? widget.node.accent,
              canAssumeChange || _hasResolvedTechnosurgeon ? 0.24 : 0.08,
            ),
            foregroundColor: EndpointPalette.soften(
              selectedAugment?.accent ?? widget.node.accent,
            ),
            expands: true,
            useMarquee: false,
          ),
        ],
      ),
    );
  }
}

class _TechnosurgeonAugmentSelectionOverlay extends StatelessWidget {
  final List<Augment> augments;
  final Color accent;

  const _TechnosurgeonAugmentSelectionOverlay({
    required this.augments,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointOverlayScaffold(
      title: 'Aumentos',
      subtitle: 'Elige el protocolo que vas a entregar',
      sectionLabel: 'AUMENTOS',
      sectionValue: '${augments.length}',
      closeTooltip: 'Cerrar seleccion',
      accent: accent,
      bottomInset: 104,
      maxWidth: 420,
      maxHeight: 360,
      child: augments.isEmpty
          ? Center(
              child: EndpointText(
                EndpointStrings.noAugments,
                textAlign: TextAlign.center,
                style: textSmallBold.copyWith(
                  color: EndpointPalette.softForeground.withAlpha(184),
                ),
              ),
            )
          : GridView.builder(
              itemCount: augments.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 104,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 96,
              ),
              itemBuilder: (context, index) {
                final augment = augments[index];

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(augment),
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        EndpointAugmentOrb(
                          augment: augment,
                          size: 58,
                        ),
                        const SizedBox(height: 6),
                        EndpointText(
                          augment.displayName,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: textSmallBold.copyWith(
                            color: augment.accent,
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

class _TechnosurgeonOrbPanel extends StatelessWidget {
  final String label;
  final String caption;
  final Augment? augment;
  final Color accent;
  final bool isSelectable;
  final bool isAnimating;
  final VoidCallback? onPressed;

  const _TechnosurgeonOrbPanel({
    required this.label,
    required this.caption,
    required this.augment,
    required this.accent,
    this.isSelectable = false,
    this.isAnimating = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = EndpointPalette.soften(accent);
    final panel = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: EndpointPalette.blend(
          EndpointPalette.panelBackgroundGold,
          accent,
          isSelectable ? 0.2 : 0.1,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withAlpha(isSelectable ? 230 : 140),
          width: isSelectable ? 1.6 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(isAnimating ? 74 : 31),
            blurRadius: isAnimating ? 18 : 10,
            spreadRadius: isSelectable ? 2 : 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          EndpointAugmentOrb(
            augment: augment,
            accent: accent,
            size: 72,
            emptyTooltip: caption,
            onPressed: onPressed,
          ),
          const SizedBox(height: 8),
          EndpointText(
            augment?.displayName ?? caption,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: textSmallBold.copyWith(
              color: augment?.accent ?? foreground,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          if (isSelectable) ...[
            const SizedBox(height: 5),
            EndpointText(
              'PULSABLE',
              style: textSmallBold.copyWith(
                color: foreground,
                fontSize: 8,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ],
      ),
    );

    if (onPressed == null) return panel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: panel,
      ),
    );
  }
}

class _TechnosurgeonResultCard extends StatelessWidget {
  final Augment? augment;
  final String outcomeText;
  final Color accent;

  const _TechnosurgeonResultCard({
    required this.augment,
    required this.outcomeText,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final currentAugment = augment;
    final resolvedAccent = currentAugment?.accent ?? accent;

    return EndpointPanel(
      accent: resolvedAccent,
      backgroundColor: EndpointPalette.blend(
        EndpointPalette.panelBackgroundGold,
        resolvedAccent,
        0.16,
      ),
      borderRadius: 14,
      glowOpacity: 0.08,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          EndpointAugmentOrb(
            augment: currentAugment,
            accent: resolvedAccent,
            size: 56,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EndpointText(
                  currentAugment?.displayName ?? 'Mutacion completada',
                  maxLines: null,
                  style: textMediumBold.copyWith(
                    color: EndpointPalette.soften(resolvedAccent),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                EndpointText(
                  outcomeText,
                  maxLines: null,
                  style: textSmallBold.copyWith(
                    color: EndpointPalette.softForeground.withAlpha(204),
                    fontSize: 10,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
