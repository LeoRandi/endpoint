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
    final foreground =
        Color.lerp(Colors.white, accent, 0.32) ?? const Color(0xFFEEDB96);
    final screenSize = MediaQuery.sizeOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: min(480, screenSize.width - 48),
                maxHeight: screenSize.height * 0.82,
              ),
              child: EndpointPanel(
                accent: accent,
                backgroundColor: const Color(0xF017130B),
                borderRadius: 18,
                glowOpacity: 0.12,
                blurRadius: 26,
                padding: EdgeInsets.zero,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
                                    style: textMediumBold.copyWith(
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
                            color: Colors.white.withOpacity(0.84),
                          ),
                        ),
                        const SizedBox(height: 12),
                        EndpointText(
                          _buildModifiersText(item),
                          maxLines: null,
                          style: textSmallBold.copyWith(
                            fontSize: 10,
                            color: accent,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        EndpointPanel(
                          accent: accent,
                          backgroundColor: const Color(0xCC2A2212),
                          glowOpacity: 0.03,
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: EndpointText(
                            statusText,
                            maxLines: null,
                            style: textSmallBold.copyWith(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.76),
                              letterSpacing: 0.9,
                            ),
                          ),
                        ),
                        if (actionLabel != null) ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: EndpointActionButton(
                              label: actionLabel!,
                              icon: Icons.shopping_bag_outlined,
                              onPressed:
                                  isActionEnabled ? onPrimaryAction : null,
                              tooltip: isActionEnabled
                                  ? enabledActionTooltip
                                  : disabledActionTooltip,
                              accent: accent,
                              backgroundColor: const Color(0xFF2A2212),
                              foregroundColor: foreground,
                              borderWidth: 1.3,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              textStyle:
                                  textMediumBold.copyWith(letterSpacing: 1.2),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -18,
              right: -10,
              child: EndpointSceneCloseButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Cerrar detalle',
                accent: accent,
                foregroundColor: foreground,
                backgroundColor: const Color(0xFF17130B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildModifiersText(Item item) {
    if (item.statModifiers.isEmpty) return 'Sin modificadores directos.';

    final entries = item.statModifiers.entries.map((entry) {
      return '+${entry.value} ${entry.key.name.toUpperCase()}';
    });

    return entries.join('   ');
  }
}
