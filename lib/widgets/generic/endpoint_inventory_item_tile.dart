import '../_imports.dart';

class EndpointInventoryItemTile extends StatelessWidget {
  final Item item;
  final VoidCallback? onPressed;
  final Color? accent;
  final Color backgroundColor;
  final double borderRadius;
  final double glowOpacity;
  final double emojiSize;
  final Color textColor;

  const EndpointInventoryItemTile({
    super.key,
    required this.item,
    this.onPressed,
    this.accent,
    this.backgroundColor = EndpointPalette.panelBackgroundSoft,
    this.borderRadius = 12,
    this.glowOpacity = 0.03,
    this.emojiSize = 18,
    this.textColor = EndpointPalette.softForeground,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accent ?? item.rarity.accent;

    return HoldTooltip(
      message: item.tooltipDescription,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: EndpointPanel(
            accent: resolvedAccent,
            backgroundColor: backgroundColor,
            borderRadius: borderRadius,
            glowOpacity: glowOpacity,
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/slots/equipment_slot_base.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                      ),
                      Center(
                        child: EndpointText(
                          item.iconEmoji,
                          style: TextStyle(
                            fontSize: emojiSize,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                EndpointText(
                  item.displayName,
                  textAlign: TextAlign.center,
                  style: textSmallBold.copyWith(
                    color: textColor,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
