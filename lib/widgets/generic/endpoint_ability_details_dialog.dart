import '../_imports.dart';

class EndpointAbilityDetailsDialog extends StatelessWidget {
  final BattlerAbility ability;
  final Color accent;
  final String statusText;
  final int? moneyCost;
  final String? actionLabel;
  final VoidCallback? onPrimaryAction;
  final bool isActionEnabled;
  final String enabledActionTooltip;
  final String disabledActionTooltip;

  const EndpointAbilityDetailsDialog({
    super.key,
    required this.ability,
    required this.accent,
    required this.statusText,
    this.moneyCost,
    this.actionLabel,
    this.onPrimaryAction,
    this.isActionEnabled = false,
    this.enabledActionTooltip = '',
    this.disabledActionTooltip = '',
  });

  @override
  Widget build(BuildContext context) {
    final foreground = EndpointPalette.soften(accent);
    final descriptionSurface = EndpointPalette.blend(
      EndpointPalette.panelBackground,
      accent,
      0.12,
    );
    final statusSurface = EndpointPalette.blend(
      EndpointPalette.panelBackgroundGold,
      accent,
      0.16,
    );
    final actionSurface = ability.isActive
        ? EndpointPalette.blend(
            EndpointPalette.panelBackgroundGold,
            accent,
            0.3,
          )
        : statusSurface;

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
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EndpointPalette.panelBackground,
                  border: Border.all(color: accent),
                ),
                child: Center(
                  child: Icon(
                    ability.icon,
                    size: 36,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EndpointText(
                      ability.displayName,
                      maxLines: null,
                      style: textLargeBold.copyWith(
                        color: foreground,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    EndpointText(
                      'ACTIVACION  ${ability.manualActivationContext?.label ?? 'Pasiva'}',
                      maxLines: null,
                      style: textSmallBold.copyWith(
                        fontSize: 10,
                        color: accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    EndpointText(
                      'COOLDOWN  ${ability.cooldownLabel}',
                      maxLines: null,
                      style: textMediumNumericBold.copyWith(
                        fontSize: 14,
                        color: foreground,
                      ),
                    ),
                    if (statusText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      EndpointText(
                        statusText,
                        maxLines: null,
                        style: textSmallBold.copyWith(
                          fontSize: 10,
                          color: accent,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                    if (moneyCost != null) ...[
                      const SizedBox(height: 4),
                      EndpointCurrencyInline(
                        value: moneyCost!,
                        iconColor: EndpointPalette.warningAccent,
                        textColor: EndpointPalette.softForegroundWarm,
                        iconSize: 13,
                        spacing: 3,
                        textStyle: textSmallNumericBold.copyWith(
                          fontSize: 11,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EndpointPanel(
            accent: accent,
            backgroundColor: descriptionSurface,
            glowOpacity: 0.03,
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
            child: EndpointText(
              ability.description,
              maxLines: null,
              style: textMedium.copyWith(
                fontSize: 14,
                color: EndpointPalette.softForeground.withValues(alpha: 0.84),
              ),
            ),
          ),
          if (ability.hasTags) ...[
            const SizedBox(height: 12),
            EndpointText(
              'TAGS',
              style: textSmallBold.copyWith(
                fontSize: 10,
                color: accent,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: EndpointTagPillMarquee(
                tags: ability.tags,
                accent: accent,
              ),
            ),
          ],
          const SizedBox(height: 12),
          EndpointText(
            _buildInfoText(ability),
            maxLines: null,
            style: textSmallNumericBold.copyWith(
              fontSize: 10,
              color: accent,
              letterSpacing: 1,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: EndpointActionButton(
                label: actionLabel!,
                icon: ability.isActive
                    ? Icons.pause_circle_outline_rounded
                    : Icons.power_settings_new_rounded,
                onPressed: isActionEnabled ? onPrimaryAction : null,
                tooltip: isActionEnabled
                    ? enabledActionTooltip
                    : disabledActionTooltip,
                accent: accent,
                backgroundColor: actionSurface,
                foregroundColor: foreground,
                borderWidth: ability.isActive ? 1.6 : 1.3,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                textStyle: textMediumBold.copyWith(letterSpacing: 1.2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildInfoText(BattlerAbility ability) {
    final parts = <String>[
      'VALOR ${ability.currentValue}',
      'MEJORA +${ability.upgradeValue}',
      'RECARGA ${ability.remainingCooldownLabel}',
    ];

    final preparts = parts.join('   ');
    parts.clear();
    parts.add(preparts);

    if (ability.runtimeValueBonus > 0) {
      parts.add('BONO +${ability.runtimeValueBonus}');
    }
    if (ability.isActive) {
      parts.add('ESTADO: Activa');
    }

    return parts.join('\n');
  }
}
