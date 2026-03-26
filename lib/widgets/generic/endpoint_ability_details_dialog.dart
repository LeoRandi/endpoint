import '_imports.dart';

class EndpointAbilityDetailsDialog extends StatelessWidget {
  final BattlerAbility ability;
  final Color accent;
  final String statusText;
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
    this.actionLabel,
    this.onPrimaryAction,
    this.isActionEnabled = false,
    this.enabledActionTooltip = '',
    this.disabledActionTooltip = '',
  });

  @override
  Widget build(BuildContext context) {
    final foreground = EndpointPalette.soften(accent);
    final screenSize = MediaQuery.sizeOf(context);
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
                backgroundColor: EndpointPalette.panelBackgroundGold,
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
                                    ability.name,
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
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        EndpointPanel(
                          accent: accent,
                          backgroundColor: descriptionSurface,
                          glowOpacity: 0.03,
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: EndpointText(
                            ability.description,
                            maxLines: null,
                            style: textMedium.copyWith(
                              fontSize: 14,
                              color: EndpointPalette.softForeground
                                  .withOpacity(0.84),
                            ),
                          ),
                        ),
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
                        const SizedBox(height: 12),
                        EndpointPanel(
                          accent: accent,
                          backgroundColor: statusSurface,
                          glowOpacity: 0.03,
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: EndpointText(
                            statusText,
                            maxLines: null,
                            style: textSmallBold.copyWith(
                              fontSize: 10,
                              color: EndpointPalette.softForeground
                                  .withOpacity(0.76),
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
                              icon: ability.isActive
                                  ? Icons.pause_circle_outline_rounded
                                  : Icons.power_settings_new_rounded,
                              onPressed:
                                  isActionEnabled ? onPrimaryAction : null,
                              tooltip: isActionEnabled
                                  ? enabledActionTooltip
                                  : disabledActionTooltip,
                              accent: accent,
                              backgroundColor: actionSurface,
                              foregroundColor: foreground,
                              borderWidth: ability.isActive ? 1.6 : 1.3,
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
                backgroundColor: EndpointPalette.blend(
                  EndpointPalette.panelBackgroundGold,
                  accent,
                  0.08,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildInfoText(BattlerAbility ability) {
    final parts = <String>[
      'VALOR ${ability.currentValue}',
      'MEJORA +${ability.upgradeValue}',
      'RECARGA ${ability.remainingCooldownLabel}',
    ];
    if (ability.runtimeValueBonus > 0) {
      parts.add('BONO +${ability.runtimeValueBonus}');
    }
    if (ability.isActive) {
      parts.add('ESTADO ACTIVA');
    }

    return parts.join('   ');
  }
}
