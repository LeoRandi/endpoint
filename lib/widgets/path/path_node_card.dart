import '_imports.dart';

class PathNodeCard extends StatelessWidget {
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
  final String iconEmoji;

  const PathNodeCard({
    super.key,
    required this.label,
    required this.tooltip,
    this.onPressed,
    this.iconEmoji = '\u{1F47E}',
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF5AF78E);

    return HoldTooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: AspectRatio(
          aspectRatio: 0.76,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF112016),
                    Color(0xFF09100C),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withOpacity(0.7)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.14),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: accent.withOpacity(0.5)),
                      ),
                      child: Text(
                        'NODO',
                        style: textSmallBold.copyWith(
                          color: accent,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Center(
                          child: EndpointEmojiSprite(
                            emoji: iconEmoji,
                            accent: const Color(0xFFFF6B6B),
                            size: 68,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: textMediumBold.copyWith(
                        color: const Color(0xFFE6FFF0),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
