import 'battler/_exports.dart';
import 'status/_exports.dart';

/// Punto de integracion global para avisar descubrimientos nuevos al Codex.
///
/// Se mantiene como hook estatico para que entidades puras puedan reportar
/// descubrimientos sin depender directamente del controlador de progreso.
abstract final class CodexDiscoveryHook {
  /// Desactiva temporalmente los avisos cuando se reconstruyen datos guardados.
  static bool isSuppressed = false;

  /// Notifica que un item entro por primera vez en el contexto del jugador.
  static void Function(String catalogKey)? onItemAdded;

  /// Notifica que un aumento entro por primera vez en el contexto del jugador.
  static void Function(int augmentId)? onAugmentAdded;

  /// Notifica que una habilidad entro por primera vez en el contexto del jugador.
  static void Function(BattlerAbilityId abilityId)? onAbilityAdded;

  /// Notifica que un estado fue aplicado y debe quedar visible en el Codex.
  static void Function(BattlerStatusId statusId)? onStatusApplied;
}
