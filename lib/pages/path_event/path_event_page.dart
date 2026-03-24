import '_imports.dart';

class PathEventPage extends StatelessWidget {
  final Battler player;
  final String showTitle;
  final String eventTitle;
  final String description;
  final String outcomeText;
  final String iconEmoji;
  final Color accent;

  const PathEventPage({
    super.key,
    required this.player,
    required this.showTitle,
    required this.eventTitle,
    required this.description,
    required this.outcomeText,
    required this.iconEmoji,
    required this.accent,
  });

  void _close(BuildContext context) {
    Navigator.of(context).pop(PathEventVisitResult(player: player));
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Apply temporary status effects and timed modifiers when event logic exists.
    return EndpointCenterStageScene(
      showTitle: showTitle,
      background: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(const Color(0xFF050907), accent, 0.12) ??
              const Color(0xFF050907),
          const Color(0xFF09120D),
          const Color(0xFF020403),
        ],
      ),
      onClose: () => _close(context),
      closeTooltip: EndpointStrings.backToRoute,
      accent: accent,
      emoji: iconEmoji,
      title: eventTitle,
      content: EndpointPanel(
        accent: accent,
        backgroundColor: const Color(0xCC07120D),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          children: [
            EndpointText(
              description,
              textAlign: TextAlign.center,
              maxLines: null,
              style: textMedium.copyWith(
                color: Colors.white.withOpacity(0.84),
              ),
            ),
            const SizedBox(height: 10),
            EndpointText(
              outcomeText,
              textAlign: TextAlign.center,
              maxLines: null,
              style: textMediumBold.copyWith(
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
