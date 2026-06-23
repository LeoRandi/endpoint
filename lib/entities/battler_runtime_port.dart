part of 'battler/battler.dart';

typedef BattlerSourceResolution = ({Battler owner, Battler source});

/// Runtime operations required by entity-defined effects.
///
/// The implementation lives in `services/runtime`; entities only depend on
/// this port and therefore do not import application services.
abstract interface class BattlerRuntimePort {
  Battler receiveDamage(Battler owner, int damage);

  Battler receiveDirectDamage({
    required Battler owner,
    required int damage,
    required Battler source,
  });

  Battler receiveDebuffDamage({
    required Battler owner,
    required int damage,
    required Battler source,
    required DamageKind kind,
  });

  BattlerIncomingDamageResolution applyIncomingDamageEffects({
    required Battler owner,
    required Battler source,
    required int damage,
    required DamageKind kind,
  });

  Battler applyFatalDamageEffects({
    required Battler owner,
    required int incomingDamage,
  });

  BattlerSourceResolution applyStatusFromSource({
    required Battler owner,
    required BattlerStatus status,
    required Battler source,
    required bool applyEquipmentModifiers,
  });

  int maxBlockingPointsFor(Battler owner);
}

abstract final class BattlerRuntimeGateway {
  static BattlerRuntimePort? _port;

  static void configure(BattlerRuntimePort port) {
    _port = port;
  }

  static BattlerRuntimePort get instance {
    final port = _port;
    if (port == null) {
      throw StateError('BattlerRuntimeGateway has not been configured.');
    }
    return port;
  }
}

extension BattlerRuntimePortAccess on Battler {
  Battler runtimeReceiveDamage(int damage) {
    return BattlerRuntimeGateway.instance.receiveDamage(this, damage);
  }

  Battler runtimeReceiveDirectDamage(
    int damage, {
    required Battler source,
  }) {
    return BattlerRuntimeGateway.instance.receiveDirectDamage(
      owner: this,
      damage: damage,
      source: source,
    );
  }

  Battler runtimeReceiveDebuffDamage(
    int damage, {
    required Battler source,
    DamageKind kind = DamageKind.debuff,
  }) {
    return BattlerRuntimeGateway.instance.receiveDebuffDamage(
      owner: this,
      damage: damage,
      source: source,
      kind: kind,
    );
  }

  BattlerIncomingDamageResolution runtimeApplyIncomingDamageEffects({
    required Battler source,
    required int damage,
    required DamageKind kind,
  }) {
    return BattlerRuntimeGateway.instance.applyIncomingDamageEffects(
      owner: this,
      source: source,
      damage: damage,
      kind: kind,
    );
  }

  Battler runtimeApplyFatalDamageEffects({required int incomingDamage}) {
    return BattlerRuntimeGateway.instance.applyFatalDamageEffects(
      owner: this,
      incomingDamage: incomingDamage,
    );
  }

  Battler runtimeApplyStatusFromSource(
    BattlerStatus status, {
    required Battler source,
    bool applyEquipmentModifiers = true,
  }) {
    return runtimeApplyStatusFromSourceResolved(
      status,
      source: source,
      applyEquipmentModifiers: applyEquipmentModifiers,
    ).owner;
  }

  BattlerSourceResolution runtimeApplyStatusFromSourceResolved(
    BattlerStatus status, {
    required Battler source,
    bool applyEquipmentModifiers = true,
  }) {
    return BattlerRuntimeGateway.instance.applyStatusFromSource(
      owner: this,
      status: status,
      source: source,
      applyEquipmentModifiers: applyEquipmentModifiers,
    );
  }
}
