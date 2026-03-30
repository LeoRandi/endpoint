import '../_imports.dart';

class EndpointAbilitySlotsStrip extends StatelessWidget {
  final List<BattlerAbility> abilities;
  final Color accent;
  final ValueChanged<BattlerAbility>? onAbilityPressed;
  final ValueChanged<BattlerAbility>? onAbilityHoldCompleted;
  final bool Function(BattlerAbility ability)? canHoldActivateAbility;
  final int minimumSlots;
  final bool reserveEmptySlots;
  final double orbSize;
  final double spacing;
  final String emptyTooltip;
  final Duration holdDuration;
  final bool enableTooltipLongPress;

  const EndpointAbilitySlotsStrip({
    super.key,
    this.abilities = const [],
    this.accent = EndpointPalette.primaryAccent,
    this.onAbilityPressed,
    this.onAbilityHoldCompleted,
    this.canHoldActivateAbility,
    this.minimumSlots = 3,
    this.reserveEmptySlots = true,
    this.orbSize = 46,
    this.spacing = 6,
    this.emptyTooltip = 'Slot de habilidad',
    this.holdDuration = const Duration(seconds: 1),
    this.enableTooltipLongPress = true,
  });

  @override
  Widget build(BuildContext context) {
    final slotCount = reserveEmptySlots
        ? max(minimumSlots, abilities.length)
        : abilities.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int index = 0; index < slotCount; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          Builder(
            builder: (context) {
              final ability =
                  index < abilities.length ? abilities[index] : null;

              return EndpointAbilityOrb(
                key: ValueKey<String>(
                  ability == null ? 'ability-empty-$index' : ability.id.name,
                ),
                ability: ability,
                accent: accent,
                size: orbSize,
                emptyTooltip: emptyTooltip,
                holdDuration: holdDuration,
                enableTooltipLongPress: enableTooltipLongPress,
                canHoldActivate: ability != null &&
                    (canHoldActivateAbility?.call(ability) ?? false),
                onPressed: ability != null && onAbilityPressed != null
                    ? () => onAbilityPressed!.call(ability)
                    : null,
                onHoldComplete:
                    ability != null && onAbilityHoldCompleted != null
                        ? () => onAbilityHoldCompleted!.call(ability)
                        : null,
              );
            },
          ),
        ],
      ],
    );
  }
}

class EndpointAbilityOrb extends StatefulWidget {
  final BattlerAbility? ability;
  final Color accent;
  final double size;
  final String emptyTooltip;
  final VoidCallback? onPressed;
  final VoidCallback? onHoldComplete;
  final bool canHoldActivate;
  final Duration holdDuration;
  final bool enableTooltipLongPress;

  const EndpointAbilityOrb({
    super.key,
    required this.ability,
    this.accent = EndpointPalette.primaryAccent,
    this.size = 46,
    this.emptyTooltip = 'Slot de habilidad',
    this.onPressed,
    this.onHoldComplete,
    this.canHoldActivate = false,
    this.holdDuration = const Duration(seconds: 1),
    this.enableTooltipLongPress = true,
  });

  @override
  State<EndpointAbilityOrb> createState() => _EndpointAbilityOrbState();
}

class _EndpointAbilityOrbState extends State<EndpointAbilityOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;
  bool _didCompleteHold = false;

  bool get _canUseHoldActivation {
    return widget.ability != null &&
        widget.canHoldActivate &&
        widget.onHoldComplete != null;
  }

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    )..addStatusListener(_handleHoldStatusChanged);
  }

  @override
  void didUpdateWidget(covariant EndpointAbilityOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.holdDuration != widget.holdDuration) {
      _holdController.duration = widget.holdDuration;
    }

    final abilityChanged = oldWidget.ability?.id != widget.ability?.id ||
        oldWidget.ability?.isActive != widget.ability?.isActive ||
        oldWidget.ability?.remainingCooldownTurns !=
            widget.ability?.remainingCooldownTurns;
    if (abilityChanged || !_canUseHoldActivation) {
      _resetHold(clearCompletionFlag: !_didCompleteHold);
    }
  }

  @override
  void dispose() {
    _holdController
      ..removeStatusListener(_handleHoldStatusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleHoldStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_canUseHoldActivation) {
      return;
    }

    _didCompleteHold = true;
    widget.onHoldComplete?.call();
  }

  void _startHold(TapDownDetails _) {
    if (!_canUseHoldActivation) return;

    _didCompleteHold = false;
    _holdController.forward(from: 0);
  }

  void _releaseHold(TapUpDetails _) {
    _resetHold(clearCompletionFlag: false);
  }

  void _cancelHold() {
    _resetHold(clearCompletionFlag: true);
  }

  void _consumeTapOrOpenDetails() {
    if (_didCompleteHold) {
      _didCompleteHold = false;
      return;
    }

    widget.onPressed?.call();
  }

  void _resetHold({required bool clearCompletionFlag}) {
    if (_holdController.value > 0) {
      _holdController.stop();
      _holdController.value = 0;
    }

    if (clearCompletionFlag) {
      _didCompleteHold = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAbility = widget.ability;
    final resolvedAccent = currentAbility?.accent ?? widget.accent;
    final isActive = currentAbility?.isActive ?? false;
    final isOnCooldown = currentAbility?.isOnCooldown ?? false;
    final tooltip = currentAbility?.description ?? widget.emptyTooltip;
    final borderColor = currentAbility == null
        ? resolvedAccent.withAlpha(87)
        : isActive
            ? resolvedAccent
            : resolvedAccent.withAlpha(isOnCooldown ? 117 : 158);
    final fillColor = currentAbility == null
        ? resolvedAccent.withAlpha(31)
        : isActive
            ? resolvedAccent.withAlpha(209)
            : resolvedAccent.withAlpha(isOnCooldown ? 51 : 107);
    final iconColor = currentAbility == null
        ? resolvedAccent.withAlpha(82)
        : isActive
            ? EndpointPalette.panelBackground
            : resolvedAccent.withAlpha(isOnCooldown ? 168 : 240);
    final shadowColor = isActive
        ? resolvedAccent.withAlpha(61)
        : resolvedAccent.withAlpha(isOnCooldown ? 20 : 36);
    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      color: EndpointPalette.panelBackgroundBattle,
      border: Border.all(color: borderColor, width: isActive ? 1.6 : 1.2),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: isActive ? 12 : 8,
        ),
      ],
    );

    return AnimatedBuilder(
      animation: _holdController,
      builder: (context, child) {
        final holdProgress = _holdController.value;
        final content = Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: decoration,
              padding: const EdgeInsets.all(4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fillColor,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (currentAbility == null)
                      Container(
                        width: widget.size * 0.18,
                        height: widget.size * 0.18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconColor,
                        ),
                      )
                    else
                      Icon(
                        currentAbility.icon,
                        size: widget.size * 0.46,
                        color: iconColor,
                      ),
                    if (_canUseHoldActivation && holdProgress > 0)
                      Positioned(
                        left: widget.size * 0.18,
                        right: widget.size * 0.18,
                        bottom: widget.size * 0.14,
                        child: _AbilityHoldProgressBar(
                          progress: holdProgress,
                          accent: resolvedAccent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (currentAbility != null && isOnCooldown)
              Positioned(
                top: -2,
                right: -2,
                child: _AbilityBadge(
                  label: '${currentAbility.remainingCooldownTurns}',
                  accent: resolvedAccent,
                  backgroundColor: EndpointPalette.panelBackground,
                ),
              )
            else if (currentAbility != null && isActive)
              Positioned(
                top: -2,
                right: -2,
                child: _AbilityBadge(
                  label: 'ON',
                  accent: resolvedAccent,
                  backgroundColor: resolvedAccent,
                  foregroundColor: EndpointPalette.panelBackground,
                ),
              ),
          ],
        );
        final interactiveContent = widget.onPressed == null
            ? content
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _consumeTapOrOpenDetails,
                  onTapDown: _startHold,
                  onTapUp: _releaseHold,
                  onTapCancel: _cancelHold,
                  customBorder: const CircleBorder(),
                  child: content,
                ),
              );

        if (!widget.enableTooltipLongPress) {
          return interactiveContent;
        }

        return HoldTooltip(
          message: tooltip,
          child: interactiveContent,
        );
      },
    );
  }
}

class _AbilityHoldProgressBar extends StatelessWidget {
  final double progress;
  final Color accent;

  const _AbilityHoldProgressBar({
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(77),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AbilityBadge extends StatelessWidget {
  final String label;
  final Color accent;
  final Color backgroundColor;
  final Color? foregroundColor;

  const _AbilityBadge({
    required this.label,
    required this.accent,
    required this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedForeground = foregroundColor ?? accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent),
      ),
      child: EndpointText(
        label,
        style: textSmallBold.copyWith(
          fontSize: 8,
          color: resolvedForeground,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
