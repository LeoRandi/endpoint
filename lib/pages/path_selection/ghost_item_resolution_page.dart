import '_imports.dart';

class GhostItemResolutionPage extends StatelessWidget {
  final Battler player;
  final Item item;
  final int price;

  const GhostItemResolutionPage({
    super.key,
    required this.player,
    required this.item,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final canPay = player.canAfford(price);
    final accent = item.rarity.accent;

    return EndpointCenterStageScene(
      showTitle: 'La Tintoreria Fantasma reclama su prenda',
      background: EndpointGradients.event(accent),
      onClose: () => Navigator.of(context).pop(false),
      closeTooltip: 'Devolver al tecno-eter',
      accent: accent,
      emoji: '\u{1F9FA}',
      title: 'TINTORERIA FANTASMA',
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: EndpointPanel(
          accent: accent,
          backgroundColor: EndpointPalette.panelBackgroundSoft,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EndpointText(
                '<La prenda recuerda donde estaba colgada. Devuelvela, o pagale al mundo para que finja que siempre fue tuya.>',
                textAlign: TextAlign.center,
                maxLines: null,
                style: textMediumBold.copyWith(
                  color: EndpointPalette.softForeground.withAlpha(218),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 104,
                height: 122,
                child: EndpointInventoryItemTile(
                  item: item,
                  accent: accent,
                  glowOpacity: 0.16,
                  onPressed: () => _openItemDetails(context),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EndpointCurrencyInline(
                    value: player.money,
                    iconColor: EndpointPalette.warningAccent,
                    textColor: EndpointPalette.softForegroundWarm,
                    iconSize: 14,
                    spacing: 4,
                    textStyle: textSmallNumericBold.copyWith(
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  EndpointText(
                    'PRECIO $price C',
                    style: textSmallBold.copyWith(
                      color: canPay
                          ? EndpointPalette.warningAccent
                          : EndpointPalette.dangerAccent,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  EndpointActionButton(
                    label: 'Devolver',
                    icon: Icons.keyboard_return_rounded,
                    onPressed: () => Navigator.of(context).pop(false),
                    tooltip: 'Devolver el objeto al tecno-eter',
                    accent: EndpointPalette.infoAccent,
                    backgroundColor: EndpointPalette.blend(
                      EndpointPalette.panelBackground,
                      EndpointPalette.infoAccent,
                      0.14,
                    ),
                    foregroundColor:
                        EndpointPalette.soften(EndpointPalette.infoAccent),
                  ),
                  EndpointActionButton(
                    label: 'Fijar',
                    icon: Icons.auto_awesome_rounded,
                    onPressed:
                        canPay ? () => Navigator.of(context).pop(true) : null,
                    tooltip: canPay
                        ? 'Pagar para conservar el objeto'
                        : 'No tienes creditos suficientes',
                    accent: EndpointPalette.warningAccent,
                    backgroundColor: EndpointPalette.blend(
                      EndpointPalette.panelBackgroundGold,
                      EndpointPalette.warningAccent,
                      canPay ? 0.22 : 0.08,
                    ),
                    foregroundColor:
                        EndpointPalette.soften(EndpointPalette.warningAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openItemDetails(BuildContext context) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de objeto fantasma',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return EndpointItemDetailsDialog(
          item: item,
          accent: item.rarity.accent,
          price: price,
          priceLabel: 'FIJAR',
          statusText: 'Prestamo fantasma agotado.',
        );
      },
    );
  }
}
