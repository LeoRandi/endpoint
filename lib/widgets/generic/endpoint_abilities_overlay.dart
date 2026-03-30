import '../_imports.dart';
import '../../services/battler_effect_pipeline.dart';

class EndpointAbilitiesOverlay extends StatefulWidget {
  final Battler player;
  final BattlerAbilityActivationContext screenContext;
  final ValueChanged<Battler>? onPlayerChanged;
  final String title;
  final String subtitle;
  final String emptyText;
  final String closeTooltip;
  final Color accent;
  final double bottomInset;
  final double maxWidth;
  final double maxHeight;

  const EndpointAbilitiesOverlay({
    super.key,
    required this.player,
    required this.screenContext,
    this.onPlayerChanged,
    this.title = 'Habilidades',
    this.subtitle = 'Panel tactico',
    this.emptyText = EndpointStrings.noSkills,
    this.closeTooltip = 'Cerrar habilidades',
    this.accent = EndpointPalette.primaryAccent,
    this.bottomInset = 112,
    this.maxWidth = 420,
    this.maxHeight = 360,
  });

  @override
  State<EndpointAbilitiesOverlay> createState() =>
      _EndpointAbilitiesOverlayState();
}

class _EndpointAbilitiesOverlayState extends State<EndpointAbilitiesOverlay> {
  static const _effectPipeline = BattlerEffectPipeline();
  late Battler _player;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
  }

  Future<void> _openAbilityDetails(BattlerAbility ability) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de habilidad',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentAbility = _player.abilityById(ability.id) ?? ability;

            return EndpointAbilityDetailsDialog(
              ability: currentAbility,
              accent: widget.accent,
              statusText: _statusTextFor(currentAbility),
              actionLabel: _actionLabelFor(currentAbility),
              onPrimaryAction: _isActionEnabled(currentAbility)
                  ? () {
                      final resolution =
                          _effectPipeline.toggleAbilityActivation(
                        owner: _player,
                        abilityId: currentAbility.id,
                        screenContext: widget.screenContext,
                      );
                      setState(() {
                        _player = resolution.owner;
                      });
                      widget.onPlayerChanged?.call(_player);
                      setDialogState(() {});
                    }
                  : null,
              isActionEnabled: _isActionEnabled(currentAbility),
              enabledActionTooltip: currentAbility.isActive
                  ? 'Desactivar habilidad manual'
                  : 'Activar habilidad manual',
              disabledActionTooltip: _disabledActionTooltipFor(currentAbility),
            );
          },
        );
      },
    );
  }

  String _statusTextFor(BattlerAbility ability) {
    final status = ability.isActive
        ? 'Estado actual: activa.'
        : ability.isOnCooldown
            ? 'Estado actual: en cooldown (${ability.remainingCooldownLabel}).'
            : 'Estado actual: lista.';
    final activation = ability.manualActivationContext == null
        ? 'Se aplica sin activacion manual.'
        : 'Se puede activar manualmente en ${ability.manualActivationContext!.label}.';

    return '$status $activation';
  }

  String? _actionLabelFor(BattlerAbility ability) {
    if (!ability.canToggleOn(widget.screenContext)) return null;
    return ability.isActive ? 'Desactivar' : 'Activar';
  }

  bool _isActionEnabled(BattlerAbility ability) {
    if (!ability.canToggleOn(widget.screenContext)) return false;
    if (ability.isActive) return true;
    return !ability.isOnCooldown && ability.isImplemented;
  }

  String _disabledActionTooltipFor(BattlerAbility ability) {
    if (!ability.isImplemented) return 'La habilidad aun no esta implementada';
    if (ability.isOnCooldown) {
      return 'Recarga restante: ${ability.remainingCooldownLabel}';
    }
    return 'No se puede activar desde esta pantalla';
  }

  @override
  Widget build(BuildContext context) {
    final abilities = _player.abilities;

    return EndpointOverlayScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      sectionLabel: 'HABILIDADES',
      sectionValue: '${abilities.length}',
      closeTooltip: widget.closeTooltip,
      accent: widget.accent,
      bottomInset: widget.bottomInset,
      maxWidth: widget.maxWidth,
      maxHeight: widget.maxHeight,
      child: abilities.isEmpty
          ? Center(
              child: EndpointText(
                widget.emptyText,
                textAlign: TextAlign.center,
                style: textSmallBold.copyWith(
                  color: Colors.white.withOpacity(0.72),
                ),
              ),
            )
          : GridView.builder(
              itemCount: abilities.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 92,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 82,
              ),
              itemBuilder: (context, index) {
                final ability = abilities[index];

                return _AbilityOverlayTile(
                  ability: ability,
                  accent: widget.accent,
                  onPressed: () => _openAbilityDetails(ability),
                );
              },
            ),
    );
  }
}

class _AbilityOverlayTile extends StatelessWidget {
  final BattlerAbility ability;
  final Color accent;
  final VoidCallback onPressed;

  const _AbilityOverlayTile({
    required this.ability,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Center(
          child: EndpointAbilityOrb(
            ability: ability,
            accent: accent,
            size: 58,
          ),
        ),
      ),
    );
  }
}
