import '_imports.dart';

class BattleCharacterPanel extends StatelessWidget {
  final String factionLabel;
  final String characterName;
  final int currentHealth;
  final int maxHealth;
  final String spriteEmoji;
  final Color accent;
  final bool mirrorSprite;
  final Alignment spriteAlignment;

  const BattleCharacterPanel({
    super.key,
    required this.factionLabel,
    required this.characterName,
    required this.currentHealth,
    required this.maxHealth,
    required this.spriteEmoji,
    required this.accent,
    this.mirrorSprite = false,
    this.spriteAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final healthFactor = maxHealth <= 0
        ? 0.0
        : (currentHealth / maxHealth).clamp(0.0, 1.0).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 248),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xD907120D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.7)),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.12),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      EndpointText(
                        factionLabel,
                        style: textSmallBold.copyWith(
                          color: accent,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const Spacer(),
                      EndpointText(
                        '$currentHealth / $maxHealth',
                        style: textSmallBold.copyWith(
                          color: Colors.white.withOpacity(0.86),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  EndpointHealthBar(
                    value: healthFactor,
                    accent: accent,
                    height: 12,
                  ),
                  const SizedBox(height: 8),
                  EndpointText(
                    characterName,
                    textAlign: TextAlign.center,
                    style: textMediumBold.copyWith(
                      color: const Color(0xFFE6FFF0),
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: spriteAlignment,
          child: EndpointEmojiSprite(
            emoji: spriteEmoji,
            accent: accent,
            size: 104,
            mirror: mirrorSprite,
          ),
        ),
      ],
    );
  }
}
