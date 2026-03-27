import '_imports.dart';

class EndpointItemDetailsDialog extends StatelessWidget {
  final Item item;
  final Color accent;
  final int price;
  final String statusText;
  final String? actionLabel;
  final VoidCallback? onPrimaryAction;
  final bool isActionEnabled;
  final String enabledActionTooltip;
  final String disabledActionTooltip;

  const EndpointItemDetailsDialog({
    super.key,
    required this.item,
    required this.accent,
    required this.price,
    required this.statusText,
    this.actionLabel,
    this.onPrimaryAction,
    this.isActionEnabled = false,
    this.enabledActionTooltip = '',
    this.disabledActionTooltip = '',
  });

  @override
  Widget build(BuildContext context) {
    final foreground = EndpointPalette.soften(accent);
    final effectSurface =
        EndpointPalette.blend(EndpointPalette.panelBackground, accent, 0.12);
    final statusSurface = EndpointPalette.blend(
      EndpointPalette.panelBackgroundGold,
      accent,
      0.16,
    );

    return EndpointDetailsDialogScaffold(
      accent: accent,
      backgroundColor: EndpointPalette.panelBackgroundGold,
      foregroundColor: foreground,
      closeBackgroundColor: EndpointPalette.blend(
        EndpointPalette.panelBackgroundGold,
        accent,
        0.08,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EndpointEmojiSprite(
                emoji: item.iconEmoji,
                accent: accent,
                size: 72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EndpointText(
                      item.name,
                      maxLines: null,
                      style: textLargeBold.copyWith(
                        color: foreground,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    EndpointText(
                      '${item.rarity.label}  |  ${item.slot?.label ?? 'Consumible'}',
                      maxLines: null,
                      style: textSmallBold.copyWith(
                        fontSize: 10,
                        color: accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    EndpointText(
                      'COSTE ${price}C',
                      maxLines: null,
                      style: textMediumNumericBold.copyWith(
                        fontSize: 14,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          EndpointText(
            item.description,
            maxLines: null,
            style: textMedium.copyWith(
              fontSize: 14,
              color: EndpointPalette.softForeground.withOpacity(0.84),
            ),
          ),
          if (item.effect != null) ...[
            const SizedBox(height: 12),
            EndpointPanel(
              accent: accent,
              backgroundColor: effectSurface,
              glowOpacity: 0.03,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: EndpointText(
                item.effect!.descriptionFor(item),
                maxLines: null,
                style: textSmallBold.copyWith(
                  fontSize: 10,
                  color: EndpointPalette.softForeground,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          EndpointText(
            _buildModifiersText(item),
            maxLines: null,
            style: textSmallNumericBold.copyWith(
              fontSize: 10,
              color: accent,
              letterSpacing: 1,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: EndpointActionButton(
                label: actionLabel!,
                icon: Icons.shopping_bag_outlined,
                onPressed: isActionEnabled ? onPrimaryAction : null,
                tooltip: isActionEnabled
                    ? enabledActionTooltip
                    : disabledActionTooltip,
                accent: accent,
                backgroundColor: statusSurface,
                foregroundColor: foreground,
                borderWidth: 1.3,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                textStyle: textMediumBold.copyWith(letterSpacing: 1.2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildModifiersText(Item item) {
    final entries = <String>[
      ...item.statModifiers.entries.map((entry) {
        final value = entry.value;
        final sign = value >= 0 ? '+' : '';
        return '$sign$value ${entry.key.name.toUpperCase()}';
      }),
    ];

    if (item.incomeModifier != 0) {
      final sign = item.incomeModifier >= 0 ? '+' : '';
      entries.add('$sign${item.incomeModifier} INCOME');
    }

    if (item.maxHealthPercentModifier != 0) {
      final sign = item.maxHealthPercentModifier >= 0 ? '+' : '';
      entries.add('$sign${item.maxHealthPercentModifier}% HP MAX');
    }

    if (entries.isEmpty) return 'Sin modificadores directos.';

    return entries.join('   ');
  }
}
