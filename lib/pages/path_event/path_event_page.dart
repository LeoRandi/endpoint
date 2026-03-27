import '../_imports.dart';

class PathEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final PathEventService eventService;

  const PathEventPage({
    super.key,
    required this.player,
    required this.node,
    this.eventService = const PathEventService(),
  });

  @override
  State<PathEventPage> createState() => _PathEventPageState();
}

class _PathEventPageState extends State<PathEventPage> {
  late final PathEventVisitResult _visitResult;

  @override
  void initState() {
    super.initState();
    _visitResult = widget.eventService.visit(
      node: widget.node,
      player: widget.player,
    );
  }

  void _close() {
    Navigator.of(context).pop(_visitResult);
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
      content: EndpointPanel(
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
      ),
    );
  }
}
