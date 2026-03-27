import '../_imports.dart';

class EndpointAbilitySlotsStrip extends StatelessWidget {
  final List<BattlerAbility> abilities;
  final Color accent;
  final ValueChanged<BattlerAbility>? onAbilityPressed;
  final int minimumSlots;
  final bool reserveEmptySlots;
  final double orbSize;
  final double spacing;
  final String emptyTooltip;

  const EndpointAbilitySlotsStrip({
    super.key,
    this.abilities = const [],
    this.accent = EndpointPalette.primaryAccent,
    this.onAbilityPressed,
    this.minimumSlots = 3,
    this.reserveEmptySlots = true,
    this.orbSize = 46,
    this.spacing = 6,
    this.emptyTooltip = 'Slot de habilidad',
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
          EndpointAbilityOrb(
            ability: index < abilities.length ? abilities[index] : null,
            accent: accent,
            size: orbSize,
            emptyTooltip: emptyTooltip,
            onPressed: index < abilities.length && onAbilityPressed != null
                ? () => onAbilityPressed!.call(abilities[index])
                : null,
          ),
        ],
      ],
    );
  }
}

class EndpointAbilityOrb extends StatelessWidget {
  final BattlerAbility? ability;
  final Color accent;
  final double size;
  final String emptyTooltip;
  final VoidCallback? onPressed;

  const EndpointAbilityOrb({
    super.key,
    required this.ability,
    this.accent = EndpointPalette.primaryAccent,
    this.size = 46,
    this.emptyTooltip = 'Slot de habilidad',
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final currentAbility = ability;
    final isActive = currentAbility?.isActive ?? false;
    final isOnCooldown = currentAbility?.isOnCooldown ?? false;
    final tooltip = currentAbility?.description ?? emptyTooltip;
    final borderColor = currentAbility == null
        ? accent.withOpacity(0.34)
        : isActive
            ? accent
            : accent.withOpacity(isOnCooldown ? 0.46 : 0.62);
    final fillColor = currentAbility == null
        ? accent.withOpacity(0.12)
        : isActive
            ? accent.withOpacity(0.82)
            : accent.withOpacity(isOnCooldown ? 0.2 : 0.42);
    final iconColor = currentAbility == null
        ? accent.withOpacity(0.32)
        : isActive
            ? EndpointPalette.panelBackground
            : accent.withOpacity(isOnCooldown ? 0.66 : 0.94);
    final shadowColor = isActive
        ? accent.withOpacity(0.24)
        : accent.withOpacity(isOnCooldown ? 0.08 : 0.14);
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
    final content = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: decoration,
          padding: const EdgeInsets.all(4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fillColor,
            ),
            child: Center(
              child: currentAbility == null
                  ? Container(
                      width: size * 0.18,
                      height: size * 0.18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconColor,
                      ),
                    )
                  : Icon(
                      currentAbility.icon,
                      size: size * 0.46,
                      color: iconColor,
                    ),
            ),
          ),
        ),
        if (currentAbility != null && isOnCooldown)
          Positioned(
            top: -2,
            right: -2,
            child: _AbilityBadge(
              label: '${currentAbility.remainingCooldownTurns}',
              accent: accent,
              backgroundColor: EndpointPalette.panelBackground,
            ),
          )
        else if (currentAbility != null && isActive)
          Positioned(
            top: -2,
            right: -2,
            child: _AbilityBadge(
              label: 'ON',
              accent: accent,
              backgroundColor: accent,
              foregroundColor: EndpointPalette.panelBackground,
            ),
          ),
      ],
    );

    return HoldTooltip(
      message: tooltip,
      child: onPressed == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                customBorder: const CircleBorder(),
                child: content,
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
