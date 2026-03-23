import '_imports.dart';

class PathNodeCard extends StatelessWidget {
  final PathNode node;
  final VoidCallback? onPressed;

  const PathNodeCard({
    super.key,
    required this.node,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = node.accent;
    final topColor =
        Color.lerp(const Color(0xFF09100C), accent, 0.18) ?? const Color(0xFF112016);
    final bottomColor =
        Color.lerp(const Color(0xFF040705), accent, 0.08) ?? const Color(0xFF09100C);

    return HoldTooltip(
      message: node.tooltip,
      child: Material(
        color: Colors.transparent,
        child: AspectRatio(
          aspectRatio: 0.76,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    topColor,
                    bottomColor,
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
                        node.badgeLabel,
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
                            emoji: node.iconEmoji,
                            accent: accent,
                            size: 68,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      node.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
