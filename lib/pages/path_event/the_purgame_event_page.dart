import '_imports.dart';

class ThePurgameEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final PathEventService eventService;

  const ThePurgameEventPage({
    super.key,
    required this.player,
    required this.node,
    this.eventService = const PathEventService(),
  });

  @override
  State<ThePurgameEventPage> createState() => _ThePurgameEventPageState();
}

class _ThePurgameEventPageState extends State<ThePurgameEventPage> {
  static const _afterText =
      'Tristemente, aun habiendo seleccionado tu camino, sabes que todos acabareis igual';

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

  void _chooseDoctrine(PurgeDoctrine doctrine) {
    if (_visitResult != null) return;

    setState(() {
      _visitResult = widget.eventService.resolveThePurgameChoice(
        player: widget.player,
        doctrine: doctrine,
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
            Column(
              children: [
                EndpointActionButton(
                  label: 'ABRAZAR LA PURGA',
                  onPressed: () => _chooseDoctrine(PurgeDoctrine.embrace),
                  tooltip: 'La Purga empieza en ronda 3 con 6 daño fijo',
                  accent: EndpointPalette.dangerAccent,
                  backgroundColor: EndpointPalette.panelBackground,
                  foregroundColor: EndpointPalette.softForegroundWarm,
                  expands: true,
                ),
                const SizedBox(height: 8),
                EndpointActionButton(
                  label: 'CREER EN UNA SALIDA',
                  onPressed: () => _chooseDoctrine(PurgeDoctrine.wayOut),
                  tooltip: 'La Purga empieza en ronda 7 con 4 daño fijo',
                  accent: widget.node.accent,
                  backgroundColor: EndpointPalette.panelBackground,
                  foregroundColor: EndpointPalette.softForegroundWarm,
                  expands: true,
                ),
              ],
            )
          else ...[
            EndpointText(
              _afterText,
              textAlign: TextAlign.center,
              maxLines: null,
              style: textMediumBold.copyWith(
                color: widget.node.accent,
              ),
            ),
            const SizedBox(height: 8),
            EndpointText(
              visitResult.outcomeText,
              textAlign: TextAlign.center,
              maxLines: null,
              style: textSmall.copyWith(
                color: EndpointPalette.softForeground.withAlpha(214),
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
