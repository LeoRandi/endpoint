import '../entities/_exports.dart';
import '../services/_exports.dart';
import 'package:flutter/foundation.dart';

typedef AbilityActivationBlockReason = String? Function(
  BattlerAbility ability,
);

/// Orquesta el overlay de habilidades y concentra las reglas de activacion visibles en UI.
class AbilitiesOverlayController extends ChangeNotifier {
  static const BattlerEffectPipeline _effectPipeline = BattlerEffectPipeline();

  final BattlerAbilityActivationContext screenContext;
  final ValueChanged<Battler>? onPlayerChanged;
  final AbilityActivationBlockReason? activationBlockReason;
  Battler _player;

  /// Crea el controlador del overlay a partir del battler visible y del contexto de activacion actual.
  AbilitiesOverlayController({
    required Battler player,
    required this.screenContext,
    this.onPlayerChanged,
    this.activationBlockReason,
  }) : _player = player;

  /// Expone el battler actual para tiles, dialogs y callbacks externos.
  Battler get player => _player;

  /// Expone la lista actual de habilidades visibles en el overlay.
  List<BattlerAbility> get abilities => _player.abilities;

  /// Sincroniza la habilidad recibida con la ultima copia viva del battler.
  BattlerAbility abilityState(BattlerAbility ability) {
    return _player.abilityById(ability.id) ?? ability;
  }

  /// Construye el texto de estado que se muestra en el dialogo de detalle de habilidad.
  String statusTextFor(BattlerAbility ability) {
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

  /// Devuelve la etiqueta de accion principal del dialogo si la habilidad puede alternarse en este contexto.
  String? actionLabelFor(BattlerAbility ability) {
    if (!ability.canToggleOn(screenContext)) return null;
    return ability.isActive ? 'Desactivar' : 'Activar';
  }

  /// Indica si la accion principal del dialogo esta disponible para esta habilidad.
  bool isActionEnabled(BattlerAbility ability) {
    if (!ability.canToggleOn(screenContext)) return false;
    if (ability.isActive) return true;
    if (activationBlockReason?.call(ability) != null) return false;
    return !ability.isOnCooldown && ability.isImplemented;
  }

  /// Explica por que la accion principal esta bloqueada en el dialogo de detalle.
  String disabledActionTooltipFor(BattlerAbility ability) {
    if (!ability.isImplemented) return 'La habilidad aun no esta implementada';
    final contextualBlockReason = activationBlockReason?.call(ability);
    if (contextualBlockReason != null) return contextualBlockReason;
    if (ability.isOnCooldown) {
      return 'Recarga restante: ${ability.remainingCooldownLabel}';
    }
    return 'No se puede activar desde esta pantalla';
  }

  /// Alterna una habilidad manual y propaga el battler resultante al overlay y a su consumidor externo.
  void toggleAbility(BattlerAbility ability) {
    if (!isActionEnabled(ability) && !ability.isActive) return;

    final resolution = _effectPipeline.toggleAbilityActivation(
      owner: _player,
      abilityId: ability.id,
      screenContext: screenContext,
    );
    _player = resolution.owner;
    onPlayerChanged?.call(_player);
    notifyListeners();
  }
}
