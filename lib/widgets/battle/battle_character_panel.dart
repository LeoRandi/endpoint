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
          constraints: const BoxConstraints(maxWidth: 280),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xD907120D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.7)),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      EndpointText(
                        factionLabel,
                        style: textMediumBold.copyWith(
                          color: accent,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      EndpointText(
                        '$currentHealth / $maxHealth',
                        style: textMediumBold.copyWith(
                          color: Colors.white.withOpacity(0.86),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 14,
                      color: Colors.black.withOpacity(0.35),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: healthFactor,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accent.withOpacity(0.75),
                                  accent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  EndpointText(
                    characterName,
                    textAlign: TextAlign.center,
                    style: textLargeBold.copyWith(
                      color: const Color(0xFFE6FFF0),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: spriteAlignment,
          child: EndpointEmojiSprite(
            emoji: spriteEmoji,
            accent: accent,
            size: 132,
            mirror: mirrorSprite,
          ),
        ),
      ],
    );
  }
}

