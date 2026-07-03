part of 'battle_page.dart';

class _ActionPanel extends StatelessWidget {
  final bool isEnabled;
  final bool isPatternMode;
  final VoidCallback onAttack;
  final VoidCallback onBlock;
  final PlayerActionIntentPreview actionPreview;

  const _ActionPanel({
    required this.isEnabled,
    required this.isPatternMode,
    required this.onAttack,
    required this.onBlock,
    required this.actionPreview,
  });

  @override
  Widget build(BuildContext context) {
    if (isPatternMode) {
      return _MatchActionButton(
        isEnabled: isEnabled,
        onMatch: onAttack,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AttackActionButton(
          isEnabled: isEnabled,
          onAttack: onAttack,
          preview: actionPreview,
        ),
        const SizedBox(width: 8),
        _BlockActionButton(
          isEnabled: isEnabled,
          onBlock: onBlock,
          blockBarrierGain: actionPreview.blockBarrierGain,
          effects: actionPreview.blockEffects,
        ),
      ],
    );
  }
}

class _PlayerBattleHud extends StatelessWidget {
  final Battler player;
  final bool isEnabled;
  final bool isPatternMode;
  final VoidCallback onAttack;
  final VoidCallback onBlock;
  final bool canOpenPreviewOperatives;
  final Future<void> Function() onOpenPreviewOperatives;
  final PlayerActionIntentPreview actionPreview;
  final _OpenBattleItemDetailsCallback? onOpenEquippedItemDetails;
  final _OpenBattleAugmentDetailsCallback? onOpenAugmentDetails;
  final Key? statusBarKey;
  final Duration healthAnimationDuration;
  final Duration barrierAnimationDuration;
  final int? barrierAnimationReference;

  const _PlayerBattleHud({
    required this.player,
    required this.isEnabled,
    required this.isPatternMode,
    required this.onAttack,
    required this.onBlock,
    required this.canOpenPreviewOperatives,
    required this.onOpenPreviewOperatives,
    required this.actionPreview,
    required this.onOpenEquippedItemDetails,
    required this.onOpenAugmentDetails,
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
        const SizedBox(height: 4),
        _BattleItemStrip(
          battler: player,
          accent: EndpointPalette.primaryAccent,
          onItemPressed: onOpenEquippedItemDetails,
        ),
        if (player.augments.isNotEmpty) ...[
          const SizedBox(height: 8),
          _BattleAugmentStrip(
            augments: player.augments,
            accent: EndpointPalette.primaryAccent,
            onAugmentPressed: onOpenAugmentDetails,
          ),
        ],
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
            Expanded(
              child: _ActionPanel(
                isEnabled: isEnabled,
                isPatternMode: isPatternMode,
                onAttack: onAttack,
                onBlock: onBlock,
                actionPreview: actionPreview,
              ),
            ),
            if (canOpenPreviewOperatives) ...[
              const SizedBox(width: 8),
              _PreviewOperativesButton(
                onPressed: () => unawaited(onOpenPreviewOperatives()),
              ),
            ],
            const SizedBox(width: 8),
            _BattleSpriteDock(
              emoji: player.iconEmoji,
              imageAsset: player.imageAsset,
              accent: EndpointPalette.primaryAccent,
              mirror: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _PreviewOperativesButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PreviewOperativesButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointActionButton(
      label: 'Equipo',
      icon: Icons.inventory_2_outlined,
      onPressed: onPressed,
      tooltip: 'Abrir inventario y equipo',
      height: 72,
      useMarquee: false,
      labelMaxLines: 1,
      iconSize: 20,
      iconSpacing: 6,
      borderRadius: 12,
      borderWidth: 1.5,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      textStyle: textSmallBold.copyWith(
        color: EndpointPalette.softForeground,
        fontSize: 12,
        letterSpacing: 0.8,
        height: 1,
      ),
      backgroundColor: EndpointPalette.closeButtonBackground,
      foregroundColor: EndpointPalette.softForeground,
      accent: EndpointPalette.primaryAccent,
    );
  }
}

class _MatchActionButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onMatch;

  const _MatchActionButton({
    required this.isEnabled,
    required this.onMatch,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointActionButton(
      label: 'MATCH',
      icon: Icons.join_inner_rounded,
      onPressed: isEnabled ? onMatch : null,
      tooltip: 'Abrir patron de combate',
      height: 72,
      useMarquee: false,
      labelMaxLines: 1,
      iconSize: 22,
      iconSpacing: 8,
      borderRadius: 12,
      borderWidth: 1.5,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      textStyle: textTitleSmallBold.copyWith(
        color: isEnabled
            ? EndpointPalette.softForeground
            : EndpointPalette.softForeground.withAlpha(107),
        fontSize: 18,
        letterSpacing: 1,
        height: 1,
      ),
      backgroundColor: EndpointPalette.closeButtonBackground,
      foregroundColor: isEnabled
          ? EndpointPalette.softForeground
          : EndpointPalette.softForeground.withAlpha(107),
      accent: EndpointPalette.primaryAccent,
    );
  }
}

class _AttackActionButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onAttack;
  final PlayerActionIntentPreview preview;

  const _AttackActionButton({
    required this.isEnabled,
    required this.onAttack,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return _IntentActionButton(
      label: 'Atacar',
      icon: Icons.flash_on_rounded,
      tooltip: 'Atacar al enemigo',
      onPressed: isEnabled ? onAttack : null,
      valueLabel: preview.attackDamageLabel,
      valueAccent: EndpointPalette.dangerAccent,
      effects: preview.attackEffects,
    );
  }
}

class _BlockActionButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onBlock;
  final int blockBarrierGain;
  final List<PlayerActionEffectIntent> effects;

  const _BlockActionButton({
    required this.isEnabled,
    required this.onBlock,
    required this.blockBarrierGain,
    required this.effects,
  });

  @override
  Widget build(BuildContext context) {
    return _IntentActionButton(
      label: 'Bloquear',
      icon: Icons.shield_rounded,
      tooltip: 'Ganar barrera y terminar turno',
      onPressed: isEnabled ? onBlock : null,
      valueLabel: '$blockBarrierGain',
      valueAccent: BattlerStat.barrier.accent,
      effects: effects,
    );
  }
}

class _IntentActionButton extends StatelessWidget {
  static const _buttonDimension = 84.0;

  final String label;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String valueLabel;
  final Color valueAccent;
  final List<PlayerActionEffectIntent> effects;

  const _IntentActionButton({
    required this.label,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.valueLabel,
    required this.valueAccent,
    required this.effects,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return SizedBox(
      width: _buttonDimension,
      height: _buttonDimension,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: BattleActionButton(
              label: label,
              icon: icon,
              dimension: _buttonDimension,
              onPressed: onPressed,
              tooltip: tooltip,
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 20),
            ),
          ),
          Positioned(
            left: 4,
            right: 4,
            bottom: 5,
            child: IgnorePointer(
              child: _ActionIntentMarker(
                valueLabel: valueLabel,
                valueAccent:
                    isEnabled ? valueAccent : valueAccent.withAlpha(107),
                effects: effects,
                isEnabled: isEnabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIntentMarker extends StatelessWidget {
  final String valueLabel;
  final Color valueAccent;
  final List<PlayerActionEffectIntent> effects;
  final bool isEnabled;

  const _ActionIntentMarker({
    required this.valueLabel,
    required this.valueAccent,
    required this.effects,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _ActionIntentValueChip(
        label: '($valueLabel)',
        accent: valueAccent,
      ),
      for (final effect in effects) _ActionIntentEffectChip(effect: effect),
    ];

    return _ActionIntentMarquee(
      height: 19,
      gap: 22,
      children: children
          .map(
            (child) => Opacity(
              opacity: isEnabled ? 1.0 : 0.48,
              child: child,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ActionIntentValueChip extends StatelessWidget {
  final String label;
  final Color accent;

  const _ActionIntentValueChip({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointText(
      label,
      maxLines: 1,
      overflow: TextOverflow.visible,
      style: textSmallNumericBold.copyWith(
        color: accent,
        fontSize: 11,
        letterSpacing: 0.3,
        height: 1,
      ),
    );
  }
}

class _ActionIntentEffectChip extends StatelessWidget {
  final PlayerActionEffectIntent effect;

  const _ActionIntentEffectChip({
    required this.effect,
  });

  @override
  Widget build(BuildContext context) {
    switch (effect.kind) {
      case PlayerActionEffectIntentKind.heal:
        return _ActionIntentIconChip(
          icon: Icons.favorite_rounded,
          assetPath: 'assets/sprites/status/vida.png',
          accent: BattlerStatusType.buff.accent,
          valueLabel: '${max(0, effect.amount)}',
        );
      case PlayerActionEffectIntentKind.buff:
      case PlayerActionEffectIntentKind.debuff:
        final status = effect.status;
        if (status == null) return const SizedBox.shrink();
        return _ActionIntentIconChip(
          icon: status.icon,
          assetPath: status.iconAssetPath,
          accent: status.type.accent,
          valueLabel: _statusAmountLabel(status, effect.amount),
        );
    }
  }

  String? _statusAmountLabel(BattlerStatus status, int amount) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0) return null;
    if (status.type == BattlerStatusType.buff) return 'x$safeAmount';
    return '$safeAmount';
  }
}

class _ActionIntentIconChip extends StatelessWidget {
  final IconData icon;
  final String? assetPath;
  final Color accent;
  final String? valueLabel;

  const _ActionIntentIconChip({
    required this.icon,
    this.assetPath,
    required this.accent,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.panelBackgroundBattleOpaque,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withAlpha(145),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (assetPath != null)
              Image.asset(
                assetPath!,
                width: 12,
                height: 12,
                color: accent,
                filterQuality: FilterQuality.none,
              )
            else
              Icon(
                icon,
                size: 12,
                color: accent,
              ),
            if (valueLabel != null) ...[
              const SizedBox(width: 2),
              EndpointText(
                valueLabel!,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: textSmallNumericBold.copyWith(
                  color: accent,
                  fontSize: 10,
                  letterSpacing: 0.2,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionIntentMarquee extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final double gap;

  const _ActionIntentMarquee({
    required this.children,
    required this.height,
    required this.gap,
  });

  @override
  State<_ActionIntentMarquee> createState() => _ActionIntentMarqueeState();
}

class _ActionIntentMarqueeState extends State<_ActionIntentMarquee>
    with SingleTickerProviderStateMixin {
  final GlobalKey _contentKey = GlobalKey();
  late final AnimationController _controller = AnimationController(vsync: this);
  double _contentWidth = 0;
  double _viewportWidth = 0;
  double _cycleDistance = 0;
  Duration? _activeDuration;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportWidth = constraints.maxWidth.isFinite
            ? max(0.0, constraints.maxWidth)
            : _viewportWidth;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncMeasuredWidth();
        });

        final shouldScroll =
            _contentWidth > 0 && _contentWidth > _viewportWidth + 0.5;
        if (!shouldScroll) {
          _stopMarquee();
          return ClipRect(
            child: SizedBox(
              height: widget.height,
              child: Center(
                child: _buildContent(key: _contentKey),
              ),
            ),
          );
        }

        final cycleDistance = _contentWidth + widget.gap;
        _ensureMarquee(cycleDistance);
        return ClipRect(
          child: SizedBox(
            height: widget.height,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final dx = _controller.value * cycleDistance;
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Transform.translate(
                      offset: Offset(-dx, 0),
                      child: _buildContent(key: _contentKey),
                    ),
                    Transform.translate(
                      offset: Offset(cycleDistance - dx, 0),
                      child: _buildContent(),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent({Key? key}) {
    return Row(
      key: key,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < widget.children.length; index++) ...[
          if (index > 0) const SizedBox(width: 4),
          widget.children[index],
        ],
      ],
    );
  }

  void _syncMeasuredWidth() {
    if (!mounted) return;
    final context = _contentKey.currentContext;
    final measuredWidth = context?.size?.width ?? 0;
    if ((measuredWidth - _contentWidth).abs() <= 0.5) return;
    setState(() {
      _contentWidth = measuredWidth;
    });
  }

  void _ensureMarquee(double cycleDistance) {
    final duration = Duration(
      milliseconds: max(4200, (cycleDistance * 72).round()),
    );
    if (_cycleDistance == cycleDistance &&
        _activeDuration == duration &&
        _controller.isAnimating) {
      return;
    }

    _cycleDistance = cycleDistance;
    _activeDuration = duration;
    _controller
      ..duration = duration
      ..repeat();
  }

  void _stopMarquee() {
    _cycleDistance = 0;
    _activeDuration = null;
    if (_controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }
}

class _EnemyBattleHud extends StatelessWidget {
  final Battler enemy;
  final _OpenBattleItemDetailsCallback? onOpenEquippedItemDetails;
  final _OpenBattleAugmentDetailsCallback? onOpenAugmentDetails;
  final Key? statusBarKey;
  final Duration healthAnimationDuration;
  final Duration barrierAnimationDuration;
  final int? barrierAnimationReference;

  const _EnemyBattleHud({
    required this.enemy,
    required this.onOpenEquippedItemDetails,
    required this.onOpenAugmentDetails,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _BattleSpriteDock(
              emoji: enemy.iconEmoji,
              imageAsset: enemy.imageAsset,
              accent: EndpointPalette.dangerAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: EndpointText(
                enemy.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: textTitleSmallBold.copyWith(
                  color: EndpointPalette.softForeground,
                  fontSize: 32,
                  letterSpacing: 1.4,
                  height: 0.95,
                ),
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
        if (enemy.augments.isNotEmpty) ...[
          const SizedBox(height: 8),
          _BattleAugmentStrip(
            augments: enemy.augments,
            accent: EndpointPalette.dangerAccent,
            onAugmentPressed: onOpenAugmentDetails,
          ),
        ],
        const SizedBox(height: 8),
        _BattleItemStrip(
          battler: enemy,
          accent: EndpointPalette.dangerAccent,
          onItemPressed: onOpenEquippedItemDetails,
        ),
        const Spacer(),
      ],
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
