import '_imports.dart';

class EndpointEmojiSprite extends StatelessWidget {
  final String emoji;
  final Color accent;
  final double size;
  final bool mirror;

  const EndpointEmojiSprite({
    super.key,
    required this.emoji,
    required this.accent,
    this.size = 128,
    this.mirror = false,
  });

  @override
  Widget build(BuildContext context) {
    final sprite = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withOpacity(0.24),
            EndpointPalette.blend(
                EndpointPalette.panelBackground, accent, 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: accent.withOpacity(0.82), width: 2),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.16),
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
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(size * 0.16),
                border: Border.all(color: accent.withOpacity(0.24)),
              ),
            ),
          ),
          Center(
            child: EndpointText(
              emoji,
              style: TextStyle(
                fontSize: size * 0.48,
                height: 1,
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
