part of 'battle_page.dart';

class _BattleItemStrip extends StatelessWidget {
  final Battler battler;
  final Color accent;
  final ValueChanged<Item>? onItemPressed;

  const _BattleItemStrip({
    required this.battler,
    required this.accent,
    this.onItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Center(
                child: EndpointEquipmentSlotsStrip(
                  battler: battler,
                  layout: EndpointEquipmentLayout.standard,
                  tileExtent: 42,
                  tileHeight: 46,
                  emojiSize: 12,
                  borderColor: accent.withAlpha(112),
                  onItemPressed: onItemPressed,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BattleAbilityStrip extends StatelessWidget {
  final List<BattlerAbility> abilities;
  final Color accent;
  final ValueChanged<BattlerAbility>? onAbilityPressed;
  final bool enableAbilityTooltipLongPress;

  const _BattleAbilityStrip({
    required this.abilities,
    required this.accent,
    this.onAbilityPressed,
    this.enableAbilityTooltipLongPress = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Center(
                child: EndpointAbilitySlotsStrip(
                  abilities: abilities,
                  accent: accent,
                  onAbilityPressed: onAbilityPressed,
                  holdDuration: const Duration(milliseconds: 500),
                  enableTooltipLongPress: enableAbilityTooltipLongPress,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BattleSpriteDock extends StatelessWidget {
  final String emoji;
  final String? imageAsset;
  final Color accent;
  final bool mirror;

  const _BattleSpriteDock({
    required this.emoji,
    this.imageAsset,
    required this.accent,
    this.mirror = false,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointSectionPanel(
      preset: _buildBattlePanelPreset(
        accent,
        borderRadius: 12,
        glowOpacity: 0.06,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EndpointEmojiSprite(
            emoji: emoji,
            imageAsset: imageAsset,
            accent: accent,
            size: 58,
            mirror: mirror,
          ),
        ],
      ),
    );
  }
}
