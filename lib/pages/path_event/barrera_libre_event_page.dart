import '_imports.dart';

class BarreraLibreEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final RunRandomizer randomizer;
  final PathEventService eventService;

  const BarreraLibreEventPage({
    super.key,
    required this.player,
    required this.node,
    required this.randomizer,
    this.eventService = const PathEventService(),
  });

  @override
  State<BarreraLibreEventPage> createState() => _BarreraLibreEventPageState();
}

class _BarreraLibreEventPageState extends State<BarreraLibreEventPage> {
  PathEventVisitResult? _visitResult;
  int _flavorPageIndex = 0;

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

  void _acceptReinforcedPoint() {
    if (_visitResult != null) return;

    setState(() {
      _visitResult = widget.eventService.resolveBarreraLibre(
        player: widget.player,
        randomizer: widget.randomizer,
      );
    });
  }

  void _close() {
    final visitResult = _visitResult;
    if (visitResult == null) return;

    Navigator.of(context).pop(visitResult);
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
      onClose: _visitResult == null ? () {} : _close,
      closeTooltip: EndpointStrings.backToRoute,
      accent: widget.node.accent,
      emoji: widget.node.iconEmoji,
      title: widget.node.eventTitle,
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    final visitResult = _visitResult;

    return EndpointPanel(
      accent: widget.node.accent,
      backgroundColor: EndpointPalette.panelBackgroundSoft,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        children: [
          EndpointText(
            widget.node.description,
            textAlign: TextAlign.center,
            maxLines: null,
            style: textMedium.copyWith(
              color: EndpointPalette.softForeground.withAlpha(214),
            ),
          ),
          const SizedBox(height: 10),
          if (visitResult == null)
            EndpointActionButton(
              label: 'ACEPTAR PLACA',
              onPressed: _acceptReinforcedPoint,
              tooltip: 'Aceptar el punto reforzado',
              accent: widget.node.accent,
              backgroundColor: EndpointPalette.panelBackground,
              foregroundColor: EndpointPalette.softForegroundWarm,
            )
          else ...[
            EndpointText(
              visitResult.outcomeText,
              textAlign: TextAlign.center,
              maxLines: null,
              style: textMediumBold.copyWith(
                color: widget.node.accent,
              ),
            ),
            const SizedBox(height: 10),
            EndpointActionButton(
              label: 'CONTINUAR',
              onPressed: _close,
              tooltip: EndpointStrings.backToRoute,
              accent: widget.node.accent,
              backgroundColor: EndpointPalette.panelBackground,
              foregroundColor: EndpointPalette.softForegroundWarm,
            ),
          ],
        ],
      ),
    );
  }
}
