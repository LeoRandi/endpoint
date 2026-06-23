import '../../entities/_exports.dart';
import '../pattern/operative_pattern_combat_rules.dart';
import 'battler_runtime_service.dart';

class ServiceBattlerRuntimePort implements BattlerRuntimePort {
  const ServiceBattlerRuntimePort();

  @override
  Battler receiveDamage(Battler owner, int damage) {
    return owner.receiveDamage(damage);
  }

  @override
  Battler receiveDirectDamage({
    required Battler owner,
    required int damage,
    required Battler source,
  }) {
    return owner.receiveDirectDamage(damage, source: source);
  }

  @override
  Battler receiveDebuffDamage({
    required Battler owner,
    required int damage,
    required Battler source,
    required DamageKind kind,
  }) {
    return owner.receiveDebuffDamage(damage, source: source, kind: kind);
  }

  @override
  BattlerIncomingDamageResolution applyIncomingDamageEffects({
    required Battler owner,
    required Battler source,
    required int damage,
    required DamageKind kind,
  }) {
    return owner.applyIncomingDamageEffects(
      source: source,
      damage: damage,
      kind: kind,
    );
  }

  @override
  Battler applyFatalDamageEffects({
    required Battler owner,
    required int incomingDamage,
  }) {
    return owner.applyEquippedItemFatalDamageEffects(
      incomingDamage: incomingDamage,
    );
  }

  @override
  BattlerSourceResolution applyStatusFromSource({
    required Battler owner,
    required BattlerStatus status,
    required Battler source,
    required bool applyEquipmentModifiers,
  }) {
    final resolution = owner.applyStatusFromSourceResolved(
      status,
      source: source,
      applyEquipmentModifiers: applyEquipmentModifiers,
    );
    return (owner: resolution.owner, source: resolution.source);
  }

  @override
  int maxBlockingPointsFor(Battler owner) {
    return OperativePatternCombatRules.maxBlockingPointsFor(owner);
  }
}
