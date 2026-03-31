import '../_imports.dart';

/// Fuerza a resolver la recompensa de nivel antes de volver a la pantalla de ruta.
class LevelUpRewardDialog extends StatelessWidget {
  final Battler player;

  /// Recibe el jugador actual para pintar el salto de stats y las recompensas posibles.
  const LevelUpRewardDialog({
    super.key,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final nextLevel = min(Battler.maximumLevel, player.level + 1);

    return PopScope(
      canPop: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: EndpointPanel(
              accent: EndpointPalette.rewardAccent,
              backgroundColor: EndpointPalette.panelBackgroundBattleOpaque,
              borderRadius: 20,
              glowOpacity: 0.1,
              blurRadius: 26,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EndpointText(
                    'SUBIDA DE NIVEL',
                    style: textLargeBold.copyWith(
                      color: EndpointPalette.softForegroundWarm,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  EndpointText(
                    'Nivel ${player.level} -> $nextLevel',
                    style: textMediumBold.copyWith(
                      color: EndpointPalette.rewardAccent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  EndpointText(
                    'La mejora base siempre aplica +1 CAPACIDAD, +1 ATK y +10 VIDA.',
                    maxLines: null,
                    style: textMedium.copyWith(
                      color: EndpointPalette.softForeground.withValues(
                        alpha: 0.82,
                      ),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _LevelUpStatPreviewRow(),
                  const SizedBox(height: 14),
                  EndpointText(
                    'ELIGE UNA RECOMPENSA EXTRA',
                    style: textSmallBold.copyWith(
                      color: EndpointPalette.rewardAccent,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _LevelUpRewardCard(
                    reward: BattlerLevelReward.income,
                    title: '+1 INCOME',
                    description:
                        'Aumenta el income base permanente del operativo.',
                    accent: EndpointPalette.infoAccent,
                    icon: Icons.trending_up_rounded,
                  ),
                  const SizedBox(height: 10),
                  const _LevelUpRewardCard(
                    reward: BattlerLevelReward.attack,
                    title: '+1 ATK EXTRA',
                    description:
                        'Suma un punto de ataque adicional al bonus base del nivel.',
                    accent: EndpointPalette.dangerAccent,
                    icon: Icons.flash_on_rounded,
                  ),
                  const SizedBox(height: 10),
                  const _LevelUpRewardCard(
                    reward: BattlerLevelReward.health,
                    title: '+10 VIDA EXTRA',
                    description:
                        'Suma diez puntos mas de vida maxima sobre el bonus base del nivel.',
                    accent: EndpointPalette.primaryAccent,
                    icon: Icons.favorite_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resume las mejoras base fijas de cualquier subida de nivel antes de la recompensa elegida.
class _LevelUpStatPreviewRow extends StatelessWidget {
  const _LevelUpStatPreviewRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _LevelUpDeltaChip(
          label: '+1 CAP',
          accent: EndpointPalette.rewardAccent,
        ),
        _LevelUpDeltaChip(
          label: '+1 ATK',
          accent: EndpointPalette.dangerAccent,
        ),
        _LevelUpDeltaChip(
          label: '+10 VIDA',
          accent: EndpointPalette.primaryAccent,
        ),
      ],
    );
  }
}

/// Pinta una accion seleccionable que devuelve al caller la recompensa elegida.
class _LevelUpRewardCard extends StatelessWidget {
  final BattlerLevelReward reward;
  final String title;
  final String description;
  final Color accent;
  final IconData icon;

  /// Recibe la metadata visible necesaria para describir una recompensa concreta.
  const _LevelUpRewardCard({
    required this.reward,
    required this.title,
    required this.description,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(reward),
        borderRadius: BorderRadius.circular(16),
        child: EndpointPanel(
          accent: accent,
          backgroundColor: EndpointPalette.panelBackgroundSoft,
          borderRadius: 16,
          glowOpacity: 0.05,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.56),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EndpointText(
                      title,
                      style: textMediumBold.copyWith(
                        color: EndpointPalette.softForeground,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    EndpointText(
                      description,
                      maxLines: null,
                      style: textSmall.copyWith(
                        color: EndpointPalette.softForeground.withValues(
                          alpha: 0.74,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reutiliza el look de chip para remarcar los incrementos base del nivel.
class _LevelUpDeltaChip extends StatelessWidget {
  final String label;
  final Color accent;

  /// Recibe el texto y el color del bonus que se quiere destacar.
  const _LevelUpDeltaChip({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: 0.36),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: EndpointText(
          label,
          style: textSmallBold.copyWith(
            color: accent,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
