part of 'battle_page.dart';

class _ActionPanel extends StatelessWidget {
  final bool isEnabled;
  final bool isDrawingMode;
  final VoidCallback onAttack;
  final VoidCallback onBlock;
  final int blockBarrierGain;

  const _ActionPanel({
    required this.isEnabled,
    required this.isDrawingMode,
    required this.onAttack,
    required this.onBlock,
    required this.blockBarrierGain,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BattleActionButton(
          label: 'Atacar',
          icon: Icons.flash_on_rounded,
          onPressed: isEnabled ? onAttack : null,
          tooltip:
              isDrawingMode ? 'Abrir ataque dibujado' : 'Atacar al enemigo',
        ),
        const SizedBox(width: 8),
        _BlockActionButton(
          isEnabled: isEnabled,
          isDrawingMode: isDrawingMode,
          onBlock: onBlock,
          blockBarrierGain: blockBarrierGain,
        ),
      ],
    );
  }
}

class _PlayerBattleHud extends StatelessWidget {
  final Battler player;
  final List<BattlerAbility> visibleAbilities;
  final bool isEnabled;
  final bool isDrawingMode;
  final VoidCallback onAttack;
  final VoidCallback onBlock;
  final int blockBarrierGain;
  final ValueChanged<BattlerAbility> onQuickActivateAbility;
  final bool Function(BattlerAbility ability) canQuickActivateAbility;
  final _OpenBattleItemDetailsCallback onOpenEquippedItemDetails;
  final _OpenBattleAbilityDetailsCallback onOpenAbilityDetails;
  final Key? statusBarKey;
  final Duration healthAnimationDuration;
  final Duration barrierAnimationDuration;
  final int? barrierAnimationReference;

  const _PlayerBattleHud({
    required this.player,
    required this.visibleAbilities,
    required this.isEnabled,
    required this.isDrawingMode,
    required this.onAttack,
    required this.onBlock,
    required this.blockBarrierGain,
    required this.onQuickActivateAbility,
    required this.canQuickActivateAbility,
    required this.onOpenEquippedItemDetails,
    required this.onOpenAbilityDetails,
    required this.statusBarKey,
    required this.healthAnimationDuration,
    required this.barrierAnimationDuration,
    required this.barrierAnimationReference,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        _BattleLoadoutStrip(
          battler: player,
          abilities: visibleAbilities,
          accent: EndpointPalette.primaryAccent,
          mirrorHorizontally: false,
          onItemPressed: onOpenEquippedItemDetails,
          onAbilityPressed: onOpenAbilityDetails,
          onAbilityHoldCompleted: onQuickActivateAbility,
          canHoldActivateAbility: canQuickActivateAbility,
          enableAbilityTooltipLongPress: false,
        ),
        const SizedBox(height: 8),
        _BattleStatusBar(
          key: statusBarKey,
          battler: player,
          accent: EndpointPalette.primaryAccent,
          factionLabel: 'ALLY',
          mirrorHorizontally: false,
          healthAnimationDuration: healthAnimationDuration,
          barrierAnimationDuration: barrierAnimationDuration,
          barrierAnimationReference: barrierAnimationReference,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ActionPanel(
              isEnabled: isEnabled,
              isDrawingMode: isDrawingMode,
              onAttack: onAttack,
              onBlock: onBlock,
              blockBarrierGain: blockBarrierGain,
            ),
            const Spacer(),
            _BattleSpriteDock(
              emoji: player.iconEmoji,
              accent: EndpointPalette.primaryAccent,
              label: 'TU',
              mirror: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _BlockActionButton extends StatelessWidget {
  static const _buttonDimension = 84.0;

  final bool isEnabled;
  final bool isDrawingMode;
  final VoidCallback onBlock;
  final int blockBarrierGain;

  const _BlockActionButton({
    required this.isEnabled,
    required this.isDrawingMode,
    required this.onBlock,
    required this.blockBarrierGain,
  });

  @override
  Widget build(BuildContext context) {
    final barrierLabelColor = isEnabled
        ? BattlerStat.barrier.accent
        : BattlerStat.barrier.accent.withAlpha(107);

    return SizedBox(
      width: _buttonDimension,
      height: _buttonDimension,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: BattleActionButton(
              label: 'Bloquear',
              icon: Icons.shield_rounded,
              dimension: _buttonDimension,
              onPressed: isEnabled ? onBlock : null,
              tooltip: isDrawingMode
                  ? 'Dibuja formas para activar bonus y neutralizar malus'
                  : 'Ganar barrera y terminar turno',
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: IgnorePointer(
              child: Center(
                child: EndpointText(
                  '[ $blockBarrierGain ]',
                  style: textSmallNumericBold.copyWith(
                    color: barrierLabelColor,
                    fontSize: 11,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnemyBattleHud extends StatelessWidget {
  final Battler enemy;
  final EnemyTurnIntentPreview enemyIntent;
  final List<BattlerAbility> visibleAbilities;
  final _OpenBattleItemDetailsCallback onOpenEquippedItemDetails;
  final _OpenBattleAbilityDetailsCallback onOpenAbilityDetails;
  final Key? statusBarKey;
  final Duration healthAnimationDuration;
  final Duration barrierAnimationDuration;
  final int? barrierAnimationReference;

  const _EnemyBattleHud({
    required this.enemy,
    required this.enemyIntent,
    required this.visibleAbilities,
    required this.onOpenEquippedItemDetails,
    required this.onOpenAbilityDetails,
    required this.statusBarKey,
    required this.healthAnimationDuration,
    required this.barrierAnimationDuration,
    required this.barrierAnimationReference,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BattleSpriteDock(
              emoji: '\u{1F47E}',
              accent: EndpointPalette.dangerAccent,
              label: 'FOE',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.topRight,
                child: _EnemyIntentCard(intent: enemyIntent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BattleStatusBar(
          key: statusBarKey,
          battler: enemy,
          accent: EndpointPalette.dangerAccent,
          factionLabel: 'HOSTILE',
          mirrorHorizontally: true,
          healthAnimationDuration: healthAnimationDuration,
          barrierAnimationDuration: barrierAnimationDuration,
          barrierAnimationReference: barrierAnimationReference,
        ),
        const SizedBox(height: 8),
        _BattleLoadoutStrip(
          battler: enemy,
          abilities: visibleAbilities,
          accent: EndpointPalette.dangerAccent,
          mirrorHorizontally: true,
          onItemPressed: onOpenEquippedItemDetails,
          onAbilityPressed: onOpenAbilityDetails,
        ),
        const Spacer(),
      ],
    );
  }
}

class _EnemyIntentCard extends StatelessWidget {
  final EnemyTurnIntentPreview intent;

  const _EnemyIntentCard({
    required this.intent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        EndpointText(
          'INCOMING:',
          style: textSmallBold.copyWith(
            color: EndpointPalette.dangerAccent.withAlpha(224),
            fontSize: 10,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 252),
          child: EndpointSectionPanel(
            preset: _buildBattlePanelPreset(
              EndpointPalette.dangerAccent,
              borderRadius: 11,
              glowOpacity: 0.05,
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                _EnemyIntentChip(
                  symbol:
                      intent.action == EnemyTurnAction.attack ? '\u2694' : null,
                  icon: intent.action == EnemyTurnAction.defend
                      ? Icons.shield_rounded
                      : null,
                  accent: intent.action == EnemyTurnAction.defend
                      ? BattlerStat.barrier.accent
                      : EndpointPalette.dangerAccent,
                ),
                if (intent.activatedBattleAbility != null)
                  _EnemyIntentChip(
                    icon: intent.activatedBattleAbility!.icon,
                    accent: intent.activatedBattleAbility!.accent,
                  ),
                if (intent.damage > 0 ||
                    intent.action == EnemyTurnAction.attack)
                  _EnemyIntentChip(
                    icon: Icons.flash_on_rounded,
                    valueLabel: '${intent.damage}',
                    accent: EndpointPalette.dangerAccent,
                  ),
                if (intent.barrierGain > 0)
                  _EnemyIntentChip(
                    icon: Icons.shield_rounded,
                    valueLabel: '${intent.barrierGain}',
                    accent: BattlerStat.barrier.accent,
                  ),
                for (final debuff in intent.appliedDebuffs)
                  _EnemyIntentChip(
                    icon: debuff.status.icon,
                    valueLabel: debuff.amountLabel,
                    accent: debuff.status.type.accent,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EnemyIntentChip extends StatelessWidget {
  final IconData? icon;
  final String? symbol;
  final String? valueLabel;
  final Color accent;

  const _EnemyIntentChip({
    this.icon,
    this.symbol,
    required this.accent,
    this.valueLabel,
  }) : assert(icon != null || symbol != null);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.panelBackgroundBattleOpaque,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withAlpha(158),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 17,
                color: accent,
              ),
            if (symbol != null)
              EndpointText(
                symbol!,
                style: textSmallBold.copyWith(
                  color: accent,
                  fontSize: 15,
                  height: 1,
                ),
              ),
            if (valueLabel != null) ...[
              const SizedBox(width: 4),
              EndpointText(
                valueLabel!,
                style: textSmallNumericBold.copyWith(
                  fontSize: 13,
                  color: EndpointPalette.softForeground,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BattleStatusBar extends StatelessWidget {
  final Battler battler;
  final Color accent;
  final String factionLabel;
  final bool mirrorHorizontally;
  final Duration healthAnimationDuration;
  final Duration barrierAnimationDuration;
  final int? barrierAnimationReference;

  const _BattleStatusBar({
    super.key,
    required this.battler,
    required this.accent,
    required this.factionLabel,
    required this.mirrorHorizontally,
    required this.healthAnimationDuration,
    required this.barrierAnimationDuration,
    required this.barrierAnimationReference,
  });

  @override
  Widget build(BuildContext context) {
    final healthFactor = battler.maxHealth <= 0
        ? 0.0
        : (battler.health / battler.maxHealth).clamp(0.0, 1.0).toDouble();

    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: EndpointSectionPanel(
          preset: _buildBattlePanelPreset(accent),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: mirrorHorizontally
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (mirrorHorizontally) ...[
                    EndpointText(
                      '${battler.health} / ${battler.maxHealth}',
                      style: textSmallNumericBold.copyWith(
                        color: Colors.white.withAlpha(214),
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: EndpointText(
                      battler.name,
                      maxLines: 1,
                      textAlign:
                          mirrorHorizontally ? TextAlign.right : TextAlign.left,
                      style: textTitleSmallBold.copyWith(
                        color: EndpointPalette.softForeground,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  EndpointText(
                    factionLabel,
                    style: textSmallBold.copyWith(
                      color: accent,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (!mirrorHorizontally) ...[
                    const SizedBox(width: 8),
                    EndpointText(
                      '${battler.health} / ${battler.maxHealth}',
                      style: textSmallNumericBold.copyWith(
                        color: Colors.white.withAlpha(214),
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              EndpointHealthBarWithStatuses(
                battler: battler,
                value: healthFactor,
                accent: accent,
                height: 10,
                badgeSize: 20,
                badgeOverlap: 6,
                healthAnimationDuration: healthAnimationDuration,
                barrierAnimationDuration: barrierAnimationDuration,
                barrierReferenceValue: barrierAnimationReference,
                badgeAlignment: mirrorHorizontally
                    ? WrapAlignment.end
                    : WrapAlignment.start,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
