import '../_imports.dart';

class EndpointCenterStageScene extends StatelessWidget {
  final String showTitle;
  final Gradient background;
  final Widget? backdrop;
  final Widget? foregroundOverlay;
  final VoidCallback onClose;
  final String closeTooltip;
  final Color accent;
  final String emoji;
  final double emojiSize;
  final String title;
  final Color titleColor;
  final Widget content;

  const EndpointCenterStageScene({
    super.key,
    required this.showTitle,
    required this.background,
    this.backdrop,
    this.foregroundOverlay,
    required this.onClose,
    this.closeTooltip = 'Volver',
    required this.accent,
    required this.emoji,
    this.emojiSize = 138,
    required this.title,
    this.titleColor = EndpointPalette.softForeground,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NodeSceneWrapper(
        showTitle: showTitle,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: background),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (backdrop != null) backdrop!,
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: EndpointSceneCloseButton(
                          onPressed: onClose,
                          tooltip: closeTooltip,
                          accent: accent,
                        ),
                      ),
                      const Spacer(),
                      EndpointEmojiSprite(
                        emoji: emoji,
                        accent: accent,
                        size: emojiSize,
                      ),
                      const SizedBox(height: 12),
                      EndpointText(
                        title,
                        textAlign: TextAlign.center,
                        style: textLargeBold.copyWith(
                          color: titleColor,
                          letterSpacing: 2.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      content,
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              if (foregroundOverlay != null) foregroundOverlay!,
            ],
          ),
        ),
      ),
    );
  }
}
