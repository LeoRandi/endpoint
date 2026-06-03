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
  final bool showPatternBadges;

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
    this.showPatternBadges = false,
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
                      if (item.isGhostly)
                        const Positioned(
                          top: 2,
                          right: 2,
                          child: _GhostItemBadge(compact: true),
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
                if (showPatternBadges) ...[
                  const SizedBox(height: 4),
                  EndpointItemPatternBadges(item: item),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostItemBadge extends StatelessWidget {
  final bool compact;

  const _GhostItemBadge({
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Objeto fantasma: prestado por la Tintoreria Fantasma',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EndpointPalette.panelBackgroundBattleOpaque,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: RarityTier.purple.accent.withValues(alpha: 0.78),
          ),
          boxShadow: [
            BoxShadow(
              color: RarityTier.purple.accent.withValues(alpha: 0.18),
              blurRadius: 8,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 6,
            vertical: compact ? 2 : 3,
          ),
          child: EndpointText(
            compact ? '\u{1F47B}' : '\u{1F47B} FANTASMA',
            style: textSmallBold.copyWith(
              color: EndpointPalette.soften(RarityTier.purple.accent),
              fontSize: compact ? 10 : 9,
              letterSpacing: compact ? 0 : 0.8,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
