import '../_imports.dart';

class EndpointAbilitiesOverlay extends StatefulWidget {
  final Battler player;
  final BattlerAbilityActivationContext screenContext;
  final ValueChanged<Battler>? onPlayerChanged;
  final AbilityActivationBlockReason? abilityActivationBlockReason;
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
    this.abilityActivationBlockReason,
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
  late AbilitiesOverlayController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
  }

  /// Reconstruye el controlador cuando cambia el battler visible o el contexto de activacion.
  @override
  void didUpdateWidget(covariant EndpointAbilitiesOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player == widget.player &&
        oldWidget.screenContext == widget.screenContext &&
        oldWidget.onPlayerChanged == widget.onPlayerChanged &&
        oldWidget.abilityActivationBlockReason ==
            widget.abilityActivationBlockReason) {
      return;
    }

    _controller.dispose();
    _controller = _buildController();
  }

  /// Crea el controlador que concentra la logica de activacion de este overlay.
  AbilitiesOverlayController _buildController() {
    return AbilitiesOverlayController(
      player: widget.player,
      screenContext: widget.screenContext,
      onPlayerChanged: widget.onPlayerChanged,
      activationBlockReason: widget.abilityActivationBlockReason,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openAbilityDetails(BattlerAbility ability) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de habilidad',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final currentAbility = _controller.abilityState(ability);

            return EndpointAbilityDetailsDialog(
              ability: currentAbility,
              accent: currentAbility.accent,
              statusText: _controller.statusTextFor(currentAbility),
              actionLabel: _controller.actionLabelFor(currentAbility),
              onPrimaryAction: _controller.isActionEnabled(currentAbility)
                  ? () {
                      _controller.toggleAbility(currentAbility);
                    }
                  : null,
              isActionEnabled: _controller.isActionEnabled(currentAbility),
              enabledActionTooltip: currentAbility.isActive
                  ? 'Desactivar habilidad manual'
                  : 'Activar habilidad manual',
              disabledActionTooltip:
                  _controller.disabledActionTooltipFor(currentAbility),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final abilities = _controller.abilities;

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
                      onPressed: () => _openAbilityDetails(ability),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _AbilityOverlayTile extends StatelessWidget {
  final BattlerAbility ability;
  final VoidCallback onPressed;

  const _AbilityOverlayTile({
    required this.ability,
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
            size: 58,
          ),
        ),
      ),
    );
  }
}
