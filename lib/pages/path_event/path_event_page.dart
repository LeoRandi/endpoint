import '_imports.dart';

class PathEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final RunRandomizer randomizer;
  final PathEventService eventService;

  const PathEventPage({
    super.key,
    required this.player,
    required this.node,
    required this.randomizer,
    this.eventService = const PathEventService(),
  });

  @override
  State<PathEventPage> createState() => _PathEventPageState();
}

class _PathEventPageState extends State<PathEventPage> {
  late final PathEventVisitResult _visitResult;
  int _flavorPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _visitResult = widget.eventService.visit(
      node: widget.node,
      player: widget.player,
      randomizer: widget.randomizer,
    );
  }

  void _close() {
    Navigator.of(context).pop(_visitResult);
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
          const SizedBox(height: 8),
          EndpointText(
            _visitResult.outcomeText,
            textAlign: TextAlign.center,
            maxLines: null,
            style: textMediumBold.copyWith(
              color: widget.node.accent,
            ),
          ),
        ],
      ),
    );
  }
}
