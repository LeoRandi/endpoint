part of 'battle_page.dart';

class _BattleLoadoutStrip extends StatelessWidget {
  final Battler battler;
  final List<BattlerAbility> abilities;
  final Color accent;
  final bool mirrorHorizontally;
  final ValueChanged<Item>? onItemPressed;
  final ValueChanged<BattlerAbility>? onAbilityPressed;
  final ValueChanged<BattlerAbility>? onAbilityHoldCompleted;
  final bool Function(BattlerAbility ability)? canHoldActivateAbility;
  final bool enableAbilityTooltipLongPress;

  const _BattleLoadoutStrip({
    required this.battler,
    required this.abilities,
    required this.accent,
    required this.mirrorHorizontally,
    this.onItemPressed,
    this.onAbilityPressed,
    this.onAbilityHoldCompleted,
    this.canHoldActivateAbility,
    this.enableAbilityTooltipLongPress = true,
  });

  @override
  Widget build(BuildContext context) {
    final equipmentStrip = Expanded(
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
                  tileExtent: 54,
                  tileHeight: 66,
                  emojiSize: 14,
                  borderColor: accent.withAlpha(87),
                  onItemPressed: onItemPressed,
                ),
              ),
            ),
          );
        },
      ),
    );
    final abilityStrip = Expanded(
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
                  onAbilityHoldCompleted: onAbilityHoldCompleted,
                  canHoldActivateAbility: canHoldActivateAbility,
                  holdDuration: const Duration(milliseconds: 500),
                  enableTooltipLongPress: enableAbilityTooltipLongPress,
                ),
              ),
            ),
          );
        },
      ),
    );
    final separator = _BattleLoadoutDivider(accent: accent);
    final children = mirrorHorizontally
        ? <Widget>[
            abilityStrip,
            const SizedBox(width: 8),
            separator,
            const SizedBox(width: 8),
            equipmentStrip,
          ]
        : <Widget>[
            equipmentStrip,
            const SizedBox(width: 8),
            separator,
            const SizedBox(width: 8),
            abilityStrip,
          ];

    return SizedBox(
      height: 66,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class _BattleLoadoutDivider extends StatelessWidget {
  final Color accent;

  const _BattleLoadoutDivider({
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 54,
      child: Center(
        child: Container(
          width: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accent.withAlpha(18),
                accent.withAlpha(184),
                accent.withAlpha(18),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withAlpha(56),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleSpriteDock extends StatelessWidget {
  final String emoji;
  final Color accent;
  final String label;
  final bool mirror;

  const _BattleSpriteDock({
    required this.emoji,
    required this.accent,
    required this.label,
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
            accent: accent,
            size: 58,
            mirror: mirror,
          ),
          const SizedBox(height: 4),
          EndpointText(
            label,
            style: textSmallBold.copyWith(
              color: EndpointPalette.softForeground,
              fontSize: 12,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}
