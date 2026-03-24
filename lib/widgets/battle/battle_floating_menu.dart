import '_imports.dart';

class BattleMenuEntry<T> {
  final T value;
  final String label;
  final String tooltip;
  final bool isEnabled;

  const BattleMenuEntry({
    required this.value,
    required this.label,
    required this.tooltip,
    this.isEnabled = true,
  });
}

class BattleFloatingMenu<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emptyText;
  final List<BattleMenuEntry<T>> entries;
  final String closeTooltip;
  final double bottomInset;

  const BattleFloatingMenu({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emptyText,
    this.entries = const [],
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
            child: EndpointPanel(
              accent: accent,
              backgroundColor: const Color(0xFF07120D),
              borderRadius: 18,
              blurRadius: 24,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EndpointText(
                    title,
                    style: textLargeBold.copyWith(
                      color: accent,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  EndpointText(
                    subtitle,
                    style: textMedium.copyWith(
                      color: Colors.white.withOpacity(0.72),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (entries.isEmpty)
                    EndpointText(
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
                            message: entry.tooltip,
                            child: OutlinedButton(
                              onPressed: entry.isEnabled
                                  ? () => Navigator.of(context).pop(entry.value)
                                  : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accent,
                                disabledForegroundColor: accent.withOpacity(0.38),
                                side: BorderSide(color: accent.withOpacity(0.9)),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                textStyle: textMediumBold.copyWith(
                                  letterSpacing: 1.4,
                                ),
                              ),
                              child: EndpointText(entry.label),
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
                        child: const EndpointText('Cerrar'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

