import '../_imports.dart';

class EndpointEmojiSprite extends StatelessWidget {
  final String emoji;
  final String? imageAsset;
  final Color accent;
  final Color? borderAccent;
  final double size;
  final bool mirror;

  const EndpointEmojiSprite({
    super.key,
    required this.emoji,
    this.imageAsset,
    required this.accent,
    this.borderAccent,
    this.size = 128,
    this.mirror = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedBorderAccent = borderAccent ?? accent;
    final sprite = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.24),
            EndpointPalette.blend(
              EndpointPalette.panelBackground,
              accent,
              0.06,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: resolvedBorderAccent.withValues(alpha: 0.82),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.16),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.all(size * 0.12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(size * 0.16),
                border: Border.all(
                  color: resolvedBorderAccent.withValues(alpha: 0.24),
                ),
              ),
            ),
          ),
          Center(
            child: imageAsset == null
                ? _EmojiSpriteGlyph(
                    emoji: emoji,
                    size: size,
                  )
                : Padding(
                    padding: EdgeInsets.all(size * 0.08),
                    child: Image.asset(
                      imageAsset!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (context, error, stackTrace) {
                        return _EmojiSpriteGlyph(
                          emoji: emoji,
                          size: size,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );

    return Transform.flip(
      flipX: mirror,
      child: sprite,
    );
  }
}

class _EmojiSpriteGlyph extends StatelessWidget {
  final String emoji;
  final double size;

  const _EmojiSpriteGlyph({
    required this.emoji,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointText(
      emoji,
      style: TextStyle(
        fontSize: size * 0.48,
        height: 1,
      ),
    );
  }
}
