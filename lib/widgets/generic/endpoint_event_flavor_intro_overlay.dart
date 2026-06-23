import '_imports.dart';

/// Overlay de introduccion para eventos con paginas de texto y avance manual.
class EndpointEventFlavorIntroOverlay extends StatelessWidget {
  final List<String> pages;
  final int pageIndex;
  final String emoji;
  final Color accent;
  final VoidCallback onAdvance;
  final String nextLabel;
  final String closeLabel;

  const EndpointEventFlavorIntroOverlay({
    super.key,
    required this.pages,
    required this.pageIndex,
    required this.emoji,
    required this.accent,
    required this.onAdvance,
    this.nextLabel = 'Siguiente',
    this.closeLabel = 'Cerrar',
  });

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty || pageIndex < 0 || pageIndex >= pages.length) {
      return const SizedBox.shrink();
    }

    final isLastPage = pageIndex >= pages.length - 1;
    final foreground = EndpointPalette.soften(accent);

    return Stack(
      fit: StackFit.expand,
      children: [
        const ModalBarrier(
          dismissible: false,
          color: EndpointPalette.overlayScrimStrong,
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: [
                const Spacer(),
                EndpointEmojiSprite(
                  emoji: emoji,
                  accent: accent,
                  size: 156,
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: EndpointPanel(
                    accent: accent,
                    backgroundColor: EndpointPalette.panelBackgroundOpaque,
                    borderRadius: 16,
                    glowOpacity: 0.14,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EndpointText(
                          pages[pageIndex],
                          textAlign: TextAlign.center,
                          maxLines: null,
                          style: textMedium.copyWith(
                            color:
                                EndpointPalette.softForeground.withAlpha(226),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            EndpointText(
                              '${pageIndex + 1}/${pages.length}',
                              style: textSmallBold.copyWith(
                                color: foreground.withAlpha(186),
                                fontSize: 10,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 136,
                              child: EndpointActionButton(
                                label: isLastPage ? closeLabel : nextLabel,
                                icon: isLastPage
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                                onPressed: onAdvance,
                                tooltip: isLastPage
                                    ? 'Cerrar introduccion'
                                    : 'Mostrar siguiente fragmento',
                                accent: accent,
                                backgroundColor: EndpointPalette.blend(
                                  EndpointPalette.panelBackgroundGold,
                                  accent,
                                  0.2,
                                ),
                                foregroundColor: foreground,
                                useMarquee: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
