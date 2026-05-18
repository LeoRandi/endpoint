import '../entities/_exports.dart';
import 'package:flutter/foundation.dart';

typedef AbilityActivationBlockReason = String? Function(
  BattlerAbility ability,
);

/// Orquesta el overlay de aumentos pasivos.
class AbilitiesOverlayController extends ChangeNotifier {
  final BattlerAbilityActivationContext screenContext;
  final ValueChanged<Battler>? onPlayerChanged;
  final AbilityActivationBlockReason? activationBlockReason;
  final Battler _player;

  /// Crea el controlador del overlay a partir del battler visible y del contexto de activacion actual.
  AbilitiesOverlayController({
    required Battler player,
    required this.screenContext,
    this.onPlayerChanged,
    this.activationBlockReason,
  }) : _player = player;

  /// Expone el battler actual para tiles, dialogs y callbacks externos.
  Battler get player => _player;

  /// Expone la lista actual de aumentos visibles en el overlay.
  List<BattlerAbility> get abilities => _player.abilities;

  /// Sincroniza el aumento recibido con la ultima copia viva del battler.
  BattlerAbility abilityState(BattlerAbility ability) {
    return _player.abilityById(ability.id) ?? ability;
  }

  /// Construye el texto de estado que se muestra en el dialogo de detalle.
  String statusTextFor(BattlerAbility ability) {
    return 'Aumento pasivo.';
  }

  /// Los aumentos ya no tienen accion manual en el panel.
  String? actionLabelFor(BattlerAbility ability) => null;

  /// No hay accion primaria para aumentos pasivos.
  bool isActionEnabled(BattlerAbility ability) => false;

  /// Explica por que la accion principal esta bloqueada en el dialogo de detalle.
  String disabledActionTooltipFor(BattlerAbility ability) {
    if (!ability.isImplemented) return 'El aumento aun no esta implementado';
    return 'Los aumentos son pasivos';
  }

  /// Conserva la firma usada por la UI, aunque los aumentos ya no se alternan.
  void toggleAbility(BattlerAbility ability) {}
}
