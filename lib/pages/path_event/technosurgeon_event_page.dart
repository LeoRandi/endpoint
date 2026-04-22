import '../_imports.dart';

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
  BattlerAbility? _selectedAbility;
  BattlerAbility? _previewAbility;
  Timer? _previewTimer;
  int _flavorPageIndex = 0;

  bool get _hasResolvedTechnosurgeon => _visitResult?.gainedAbility != null;

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

  Future<void> _selectAbility() async {
    if (_hasResolvedTechnosurgeon || widget.player.abilities.isEmpty) return;

    final selectedAbility = await showEndpointOverlay<BattlerAbility>(
      context: context,
      barrierLabel: 'Seleccionar habilidad',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (_) => _TechnosurgeonAbilitySelectionOverlay(
        abilities: widget.player.abilities,
        accent: widget.node.accent,
      ),
    );
    if (!mounted || selectedAbility == null) return;

    setState(() {
      _selectedAbility = selectedAbility;
    });
    _startPreviewTicker();
  }

  void _startPreviewTicker() {
    _previewTimer?.cancel();
    _rollVisualPreviewAbility();
    _previewTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (!mounted || _hasResolvedTechnosurgeon) return;
        setState(_rollVisualPreviewAbility);
      },
    );
  }

  void _rollVisualPreviewAbility() {
    final selectedAbility = _selectedAbility;
    var candidates = abilityPoolForArchetype(widget.player.archetypeId)
        .where((ability) => ability.id != selectedAbility?.id)
        .toList(growable: false);
    if (candidates.isEmpty) {
      candidates = abilityPresets
          .where((ability) => ability.id != selectedAbility?.id)
          .toList(growable: false);
    }
    if (candidates.isEmpty) return;

    var nextAbility = candidates[_visualRandom.nextInt(candidates.length)];
    if (candidates.length > 1 && nextAbility.id == _previewAbility?.id) {
      final currentIndex = candidates.indexWhere(
        (ability) => ability.id == nextAbility.id,
      );
      final offset = 1 + _visualRandom.nextInt(candidates.length - 1);
      nextAbility = candidates[(currentIndex + offset) % candidates.length];
    }
    _previewAbility = nextAbility;
  }

  void _assumeTechnosurgeonChange() {
    final selectedAbility = _selectedAbility;
    if (selectedAbility == null || _hasResolvedTechnosurgeon) return;

    _previewTimer?.cancel();
    final result = widget.eventService.resolveTechnosurgeonMutation(
      node: widget.node,
      player: widget.player,
      selectedAbility: selectedAbility,
      randomizer: _eventRandomizer,
    );

    setState(() {
      _visitResult = result;
      _previewAbility = result.gainedAbility;
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
    final selectedAbility = _selectedAbility;
    final previewAbility = _previewAbility;
    final gainedAbility = _visitResult?.gainedAbility;
    final canAssumeChange =
        selectedAbility != null && !_hasResolvedTechnosurgeon;
    final hasAbilities = widget.player.abilities.isNotEmpty;
    final leftOrb = _TechnosurgeonOrbPanel(
      label: 'ENTREGA',
      caption: selectedAbility == null
          ? hasAbilities
              ? 'Pulsa para elegir'
              : 'Sin habilidades'
          : 'Habilidad seleccionada',
      ability: selectedAbility,
      accent: selectedAbility?.accent ?? widget.node.accent,
      isSelectable: hasAbilities && !_hasResolvedTechnosurgeon,
      onPressed:
          hasAbilities && !_hasResolvedTechnosurgeon ? _selectAbility : null,
    );
    final rightOrb = _TechnosurgeonOrbPanel(
      label: 'MUTACION',
      caption: _hasResolvedTechnosurgeon
          ? 'Resultado estable'
          : selectedAbility == null
              ? 'Esperando muestra'
              : 'Muestra inestable',
      ability: gainedAbility ?? previewAbility,
      accent: (gainedAbility ?? previewAbility)?.accent ?? widget.node.accent,
      isAnimating: selectedAbility != null && !_hasResolvedTechnosurgeon,
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
              ability: gainedAbility,
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
                    ? 'Reemplazar la habilidad seleccionada por una de tier superior'
                    : 'Primero selecciona una habilidad',
            accent: selectedAbility?.accent ?? widget.node.accent,
            backgroundColor: EndpointPalette.blend(
              EndpointPalette.panelBackgroundGold,
              selectedAbility?.accent ?? widget.node.accent,
              canAssumeChange || _hasResolvedTechnosurgeon ? 0.24 : 0.08,
            ),
            foregroundColor: EndpointPalette.soften(
              selectedAbility?.accent ?? widget.node.accent,
            ),
            expands: true,
            useMarquee: false,
          ),
        ],
      ),
    );
  }
}

class _TechnosurgeonAbilitySelectionOverlay extends StatelessWidget {
  final List<BattlerAbility> abilities;
  final Color accent;

  const _TechnosurgeonAbilitySelectionOverlay({
    required this.abilities,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointOverlayScaffold(
      title: 'Habilidades',
      subtitle: 'Elige el protocolo que vas a entregar',
      sectionLabel: 'HABILIDADES',
      sectionValue: '${abilities.length}',
      closeTooltip: 'Cerrar seleccion',
      accent: accent,
      bottomInset: 104,
      maxWidth: 420,
      maxHeight: 360,
      child: abilities.isEmpty
          ? Center(
              child: EndpointText(
                EndpointStrings.noSkills,
                textAlign: TextAlign.center,
                style: textSmallBold.copyWith(
                  color: EndpointPalette.softForeground.withAlpha(184),
                ),
              ),
            )
          : GridView.builder(
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

class _TechnosurgeonOrbPanel extends StatelessWidget {
  final String label;
  final String caption;
  final BattlerAbility? ability;
  final Color accent;
  final bool isSelectable;
  final bool isAnimating;
  final VoidCallback? onPressed;

  const _TechnosurgeonOrbPanel({
    required this.label,
    required this.caption,
    required this.ability,
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
          EndpointAbilityOrb(
            ability: ability,
            accent: accent,
            size: 72,
            emptyTooltip: caption,
            onPressed: onPressed,
            enableTooltipLongPress: false,
          ),
          const SizedBox(height: 8),
          EndpointText(
            ability?.displayName ?? caption,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: textSmallBold.copyWith(
              color: ability?.accent ?? foreground,
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
  final BattlerAbility? ability;
  final String outcomeText;
  final Color accent;

  const _TechnosurgeonResultCard({
    required this.ability,
    required this.outcomeText,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final currentAbility = ability;
    final resolvedAccent = currentAbility?.accent ?? accent;

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
          EndpointAbilityOrb(
            ability: currentAbility,
            accent: resolvedAccent,
            size: 56,
            enableTooltipLongPress: false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EndpointText(
                  currentAbility?.displayName ?? 'Mutacion completada',
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
