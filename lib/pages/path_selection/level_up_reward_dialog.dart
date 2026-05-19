import '../_imports.dart';

/// Fuerza a resolver la recompensa de nivel antes de volver a la pantalla de ruta.
class LevelUpRewardDialog extends StatelessWidget {
  final Battler player;
  final BattlerLevelRewardOffer offer;

  /// Recibe el jugador actual y la oferta ya tirada para esta subida.
  const LevelUpRewardDialog({
    super.key,
    required this.player,
    required this.offer,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
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
                    'Nivel ${player.level} -> ${offer.nextLevel}',
                    style: textMediumBold.copyWith(
                      color: EndpointPalette.rewardAccent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  EndpointText(
                    _baseRewardDescription,
                    maxLines: null,
                    style: textMedium.copyWith(
                      color: EndpointPalette.softForeground.withValues(
                        alpha: 0.82,
                      ),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LevelUpStatPreviewRow(
                    player: player,
                    nextLevel: offer.nextLevel,
                  ),
                  const SizedBox(height: 14),
                  EndpointText(
                    _sectionTitle,
                    style: textSmallBold.copyWith(
                      color: _sectionAccent,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var index = 0;
                      index < offer.choices.length;
                      index++) ...[
                    if (index > 0) const SizedBox(height: 10),
                    _LevelUpRewardCard(
                      player: player,
                      choice: offer.choices[index],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _sectionTitle {
    switch (offer.type) {
      case BattlerLevelRewardChoiceType.stat:
        return 'ELIGE UNA RECOMPENSA EXTRA';
      case BattlerLevelRewardChoiceType.ability:
        return 'ELIGE UNA AUMENTO ${offer.rarity?.label ?? ''}'.trim();
      case BattlerLevelRewardChoiceType.item:
        return 'ELIGE UN OBJETO ${offer.rarity?.label ?? ''}'.trim();
    }
  }

  Color get _sectionAccent =>
      offer.rarity?.accent ?? EndpointPalette.rewardAccent;

  String get _baseRewardDescription {
    final capacityGain = Battler.evenLevelProgressionBonusFor(offer.nextLevel) -
        Battler.evenLevelProgressionBonusFor(player.level);
    final extraText = capacityGain > 0
        ? ' Este nivel tambien suma +$capacityGain CAP y +$capacityGain PP.'
        : '';
    return 'La mejora base aplica +1 ATK, +1 Barrera y +5 HP.$extraText';
  }
}

/// Resume las mejoras base fijas de cualquier subida de nivel antes de la recompensa elegida.
class _LevelUpStatPreviewRow extends StatelessWidget {
  final Battler player;
  final int nextLevel;

  const _LevelUpStatPreviewRow({
    required this.player,
    required this.nextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final capacityGain = Battler.evenLevelProgressionBonusFor(nextLevel) -
        Battler.evenLevelProgressionBonusFor(player.level);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        const _LevelUpDeltaChip(
          label: '+1 ATK',
          accent: EndpointPalette.dangerAccent,
        ),
        _LevelUpDeltaChip(
          label: '+1 BAR',
          accent: BattlerStat.barrier.accent,
        ),
        const _LevelUpDeltaChip(
          label: '+5 HP',
          accent: EndpointPalette.primaryAccent,
        ),
        if (capacityGain > 0) ...[
          _LevelUpDeltaChip(
            label: '+$capacityGain CAP',
            accent: EndpointPalette.rewardAccent,
          ),
          _LevelUpDeltaChip(
            label: '+$capacityGain PP',
            accent: EndpointPalette.patternAccent,
          ),
        ],
      ],
    );
  }
}

/// Pinta una accion seleccionable que devuelve al caller la recompensa elegida.
class _LevelUpRewardCard extends StatelessWidget {
  final Battler player;
  final BattlerLevelRewardChoice choice;

  const _LevelUpRewardCard({
    required this.player,
    required this.choice,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final willUpgradeItem = _willUpgradeItem;
    final cardContent = Row(
      children: [
        _LevelUpChoiceLead(
          choice: choice,
          accent: accent,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EndpointText(
                _title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textMediumBold.copyWith(
                  color: EndpointPalette.softForeground,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 3),
              _LevelUpDescriptionText(
                choice: choice,
                description: _description,
              ),
              const SizedBox(height: 5),
              EndpointText(
                _meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textSmallBold.copyWith(
                  color: accent,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final panelChild = willUpgradeItem
        ? EndpointUpgradeBackdrop(
            color: endpointUpgradeIndicatorNeonYellow,
            iconSize: 19,
            spacing: 4,
            horizontalInset: 8,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: cardContent,
            ),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: cardContent,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(choice),
        borderRadius: BorderRadius.circular(16),
        child: EndpointPanel(
          accent: accent,
          backgroundColor: EndpointPalette.panelBackgroundSoft,
          borderRadius: 16,
          glowOpacity: 0.05,
          padding: EdgeInsets.zero,
          child: panelChild,
        ),
      ),
    );
  }

  bool get _willUpgradeItem {
    final item = choice.item;
    return item != null && player.wouldUpgradeItem(item);
  }

  Color get _accent {
    final statReward = choice.statReward;
    if (statReward != null) return _statAccent(statReward);

    return choice.rarity?.accent ?? EndpointPalette.rewardAccent;
  }

  String get _title {
    final statReward = choice.statReward;
    if (statReward != null) return _statTitle(statReward);

    final ability = choice.ability;
    if (ability != null) return ability.displayName;

    return choice.item?.displayName ?? 'Recompensa';
  }

  String get _description {
    final statReward = choice.statReward;
    if (statReward != null) return _statDescription(statReward);

    final ability = choice.ability;
    if (ability != null) return ability.displayDescription;

    return choice.item?.tooltipDescription ?? '';
  }

  String get _meta {
    final statReward = choice.statReward;
    if (statReward != null) return _statMeta(statReward);

    final ability = choice.ability;
    if (ability != null) {
      final status = player.wouldUpgradeAbility(ability) ? 'MEJORA' : 'NUEVA';
      return '$status | ${ability.rarity.label} | POTENCIA ${ability.currentValue}';
    }

    final item = choice.item;
    if (item != null) {
      final status = player.wouldUpgradeItem(item) ? 'MEJORA' : 'NUEVO';
      return '$status | ${item.rarity.label} | VENTA ${item.sellValue}C';
    }

    return '';
  }

  Color _statAccent(BattlerLevelReward reward) {
    switch (reward) {
      case BattlerLevelReward.income:
        return EndpointPalette.infoAccent;
      case BattlerLevelReward.attack:
        return EndpointPalette.dangerAccent;
      case BattlerLevelReward.health:
        return EndpointPalette.primaryAccent;
    }
  }

  String _statTitle(BattlerLevelReward reward) {
    switch (reward) {
      case BattlerLevelReward.income:
        return '+1 INCOME';
      case BattlerLevelReward.attack:
        return '+1 ATK EXTRA';
      case BattlerLevelReward.health:
        return '+5 HP EXTRA';
    }
  }

  String _statDescription(BattlerLevelReward reward) {
    switch (reward) {
      case BattlerLevelReward.income:
        return 'Aumenta el income base permanente del operativo.';
      case BattlerLevelReward.attack:
        return 'Suma un punto de ataque adicional al bonus base del nivel.';
      case BattlerLevelReward.health:
        return 'Suma cinco puntos mas de vida maxima sobre el bonus base del nivel.';
    }
  }

  String _statMeta(BattlerLevelReward reward) {
    switch (reward) {
      case BattlerLevelReward.income:
        return 'STATS | ECONOMIA';
      case BattlerLevelReward.attack:
        return 'STATS | ATAQUE';
      case BattlerLevelReward.health:
        return 'STATS | VIDA';
    }
  }
}

class _LevelUpDescriptionText extends StatelessWidget {
  final BattlerLevelRewardChoice choice;
  final String description;

  const _LevelUpDescriptionText({
    required this.choice,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final style = textSmall.copyWith(
      color: EndpointPalette.softForeground.withValues(alpha: 0.74),
    );
    final ability = choice.ability;
    if (ability != null) {
      return EndpointHighlightedValueText(
        description,
        tags: ability.tags,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final item = choice.item;
    if (item != null) {
      return EndpointHighlightedValueText(
        description,
        tags: item.tags,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return EndpointText(
      description,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

class _LevelUpChoiceLead extends StatelessWidget {
  final BattlerLevelRewardChoice choice;
  final Color accent;

  const _LevelUpChoiceLead({
    required this.choice,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: _buildLead(),
    );
  }

  Widget _buildLead() {
    final statReward = choice.statReward;
    if (statReward != null) {
      return Icon(_statIcon(statReward), color: accent, size: 22);
    }

    final ability = choice.ability;
    if (ability != null) {
      return Icon(ability.icon, color: accent, size: 22);
    }

    final item = choice.item;
    if (item != null) {
      return EndpointText(
        item.iconEmoji,
        style: const TextStyle(
          fontSize: 20,
          height: 1,
        ),
      );
    }

    return Icon(Icons.redeem_rounded, color: accent, size: 22);
  }

  IconData _statIcon(BattlerLevelReward reward) {
    switch (reward) {
      case BattlerLevelReward.income:
        return Icons.trending_up_rounded;
      case BattlerLevelReward.attack:
        return Icons.flash_on_rounded;
      case BattlerLevelReward.health:
        return Icons.favorite_rounded;
    }
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
