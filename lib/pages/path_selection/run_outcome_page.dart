import '../_imports.dart';

/// Pantalla final de la run que muestra el cierre de victoria o derrota antes de volver al menu.
class RunOutcomePage extends StatelessWidget {
  final RunCompletionType completionType;
  final Battler player;

  /// Recibe el tipo de cierre y el estado final del jugador para pintar el resumen.
  const RunOutcomePage({
    super.key,
    required this.completionType,
    required this.player,
  });

  /// Devuelve el acento visual dominante segun el tipo de cierre de run.
  Color get accent {
    switch (completionType) {
      case RunCompletionType.victory:
        return EndpointPalette.rewardAccent;
      case RunCompletionType.defeat:
        return EndpointPalette.dangerAccent;
      case RunCompletionType.retreated:
        return EndpointPalette.infoAccent;
    }
  }

  /// Devuelve el titulo principal grande que remata la run.
  String get title {
    switch (completionType) {
      case RunCompletionType.victory:
        return 'YOU WIN!';
      case RunCompletionType.defeat:
        return 'GAME OVER';
      case RunCompletionType.retreated:
        return 'RUN ENDED';
    }
  }

  /// Devuelve la linea descriptiva corta que contextualiza el cierre.
  String get description {
    switch (completionType) {
      case RunCompletionType.victory:
        return 'Has sobrevivido hasta el sunrise y cerrado la run con vida.';
      case RunCompletionType.defeat:
        return 'La unidad ha quedado fuera de servicio antes de llegar al sunrise.';
      case RunCompletionType.retreated:
        return 'La retirada ha cerrado la operacion antes del final de la run.';
    }
  }

  /// Devuelve el emoji central usado para reforzar el tono del resultado final.
  String get emoji {
    switch (completionType) {
      case RunCompletionType.victory:
        return '\u2600';
      case RunCompletionType.defeat:
        return '\u2620';
      case RunCompletionType.retreated:
        return '\u26A0';
    }
  }

  /// Cierra la pantalla final y devuelve el control a la pagina de ruta para volver al menu.
  void _close(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return EndpointCenterStageScene(
      showTitle: title,
      background: EndpointGradients.event(accent),
      onClose: () => _close(context),
      closeTooltip: 'Volver al menu',
      accent: accent,
      emoji: emoji,
      title: title,
      titleColor: accent,
      content: EndpointPanel(
        accent: accent,
        backgroundColor: EndpointPalette.panelBackgroundSoft,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EndpointText(
              description,
              textAlign: TextAlign.center,
              maxLines: null,
              style: textMedium.copyWith(
                color: EndpointPalette.softForeground.withAlpha(214),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                EndpointValueChip(
                  label: 'LV',
                  value: player.level,
                  accent: accent,
                  foreground: EndpointPalette.softForeground,
                ),
                EndpointValueChip(
                  label: 'ATK',
                  value: player.attack,
                  accent: accent,
                  foreground: EndpointPalette.softForeground,
                ),
                EndpointValueChip(
                  label: 'HP',
                  value: player.maxHealth,
                  accent: accent,
                  foreground: EndpointPalette.softForeground,
                ),
                EndpointValueChip(
                  label: 'INC',
                  value: player.income,
                  accent: accent,
                  foreground: EndpointPalette.softForeground,
                ),
                EndpointValueChip(
                  label: 'C',
                  value: player.money,
                  accent: EndpointPalette.warningAccent,
                  foreground: EndpointPalette.softForegroundWarm,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: EndpointActionButton(
                label: 'Volver al menu',
                icon: Icons.home_rounded,
                onPressed: () => _close(context),
                tooltip: 'Cerrar la run y volver al menu principal',
                accent: accent,
                backgroundColor: EndpointPalette.closeButtonBackground,
                foregroundColor: EndpointPalette.softForeground,
                expands: true,
                useMarquee: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
