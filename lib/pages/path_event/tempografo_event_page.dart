import '../_imports.dart';

class TempografoEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final PathEventService eventService;

  const TempografoEventPage({
    super.key,
    required this.player,
    required this.node,
    this.eventService = const PathEventService(),
  });

  @override
  State<TempografoEventPage> createState() => _TempografoEventPageState();
}

class _TempografoEventPageState extends State<TempografoEventPage> {
  int _flavorPageIndex = 0;

  bool get _isFlavorIntroVisible =>
      widget.node.flavorTexts.isNotEmpty &&
      _flavorPageIndex < widget.node.flavorTexts.length;

  void _advanceFlavorIntro() {
    if (!_isFlavorIntroVisible) return;
    setState(() => _flavorPageIndex++);
  }

  void _close() {
    Navigator.of(context).pop(
      PathEventVisitResult(
        player: widget.player,
        outcomeText: 'El Tempografo guarda sus herramientas sin ajustar nada.',
      ),
    );
  }

  void _choose(bool preferShops) {
    Navigator.of(context).pop(
      widget.eventService.resolveTempografoChoice(
        player: widget.player,
        preferShops: preferShops,
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: EndpointPanel(
        accent: widget.node.accent,
        backgroundColor: EndpointPalette.panelBackgroundSoft,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EndpointText(
              widget.node.description,
              textAlign: TextAlign.center,
              maxLines: null,
              style: textMedium.copyWith(
                color: EndpointPalette.softForeground.withAlpha(214),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: EndpointActionButton(
                    label: 'Tiendas',
                    icon: Icons.store_rounded,
                    onPressed: () => _choose(true),
                    tooltip: 'Adelantar rareza de tiendas durante este dia',
                    accent: widget.node.accent,
                    expands: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: EndpointActionButton(
                    label: 'Eventos',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: () => _choose(false),
                    tooltip: 'Adelantar rareza de eventos durante este dia',
                    accent: widget.node.accent,
                    expands: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
