import '_imports.dart';

class EndpointAugmentsOverlay extends StatelessWidget {
  final Battler player;
  final String title;
  final String subtitle;
  final String emptyText;
  final String closeTooltip;
  final Color accent;
  final double bottomInset;
  final double maxWidth;
  final double maxHeight;

  const EndpointAugmentsOverlay({
    super.key,
    required this.player,
    this.title = 'Aumentos',
    this.subtitle = 'Panel tactico',
    this.emptyText = EndpointStrings.noAugments,
    this.closeTooltip = 'Cerrar aumentos',
    this.accent = EndpointPalette.primaryAccent,
    this.bottomInset = 112,
    this.maxWidth = 420,
    this.maxHeight = 360,
  });

  @override
  Widget build(BuildContext context) {
    final augments = player.augments;

    return EndpointOverlayScaffold(
      title: title,
      subtitle: subtitle,
      sectionLabel: 'AUMENTOS',
      sectionValue: '${augments.length}',
      closeTooltip: closeTooltip,
      accent: accent,
      bottomInset: bottomInset,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      child: augments.isEmpty
          ? Center(
              child: EndpointText(
                emptyText,
                textAlign: TextAlign.center,
                style: textSmallBold.copyWith(
                  color: Colors.white.withOpacity(0.72),
                ),
              ),
            )
          : GridView.builder(
              itemCount: augments.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 92,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 82,
              ),
              itemBuilder: (context, index) {
                final augment = augments[index];

                return _AugmentOverlayTile(
                  augment: augment,
                  onPressed: () => _openAugmentDetails(context, augment),
                );
              },
            ),
    );
  }

  Future<void> _openAugmentDetails(BuildContext context, Augment augment) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de aumento',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        final currentAugment = player.augmentById(augment.id) ?? augment;

        return EndpointAugmentDetailsDialog(
          augment: currentAugment,
          statusText: 'Integrado en ${player.name}.',
        );
      },
    );
  }
}

class _AugmentOverlayTile extends StatelessWidget {
  final Augment augment;
  final VoidCallback onPressed;

  const _AugmentOverlayTile({
    required this.augment,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Center(
          child: EndpointAugmentOrb(
            augment: augment,
            size: 58,
          ),
        ),
      ),
    );
  }
}
