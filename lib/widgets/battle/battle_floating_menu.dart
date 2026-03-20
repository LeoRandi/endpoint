import '_imports.dart';

class BattleFloatingMenu extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emptyText;
  final List<String> entries;
  final Map<String, String> entryTooltips;
  final String closeTooltip;
  final double bottomInset;

  const BattleFloatingMenu({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emptyText,
    this.entries = const [],
    this.entryTooltips = const {},
    this.closeTooltip = 'Cerrar menu',
    this.bottomInset = 164,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF5AF78E);

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF07120D),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withOpacity(0.7)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.12),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textLargeBold.copyWith(
                        color: accent,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: textMedium.copyWith(
                        color: Colors.white.withOpacity(0.72),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (entries.isEmpty)
                      Text(
                        emptyText,
                        style: textMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      )
                    else
                      ...entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: HoldTooltip(
                              message: entryTooltips[entry] ?? entry,
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(entry),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: accent,
                                  side: const BorderSide(color: accent),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  textStyle: textMediumBold.copyWith(
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                child: Text(entry),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: HoldTooltip(
                        message: closeTooltip,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            side: const BorderSide(color: accent),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            textStyle:
                                textMediumBold.copyWith(letterSpacing: 1.4),
                          ),
                          child: const Text('Cerrar'),
                        ),
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
