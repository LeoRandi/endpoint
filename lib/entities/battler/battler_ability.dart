import '_imports.dart';

enum BattlerAbilityId {
  defend,
  overclock,
  purge,
  criticalScanner,
  weaknessHunter,
  ghostMesh,
  cruelCatalysis,
  venousOverload,
  hardReset,
}

enum BattlerAbilityActivationContext {
  battle,
  pathSelection,
  shop;

  String get label {
    switch (this) {
      case BattlerAbilityActivationContext.battle:
        return 'Combate';
      case BattlerAbilityActivationContext.pathSelection:
        return 'Ruta';
      case BattlerAbilityActivationContext.shop:
        return 'Tienda';
    }
  }
}

class BattlerAbilityEffectResolution {
  final Battler owner;
  final Battler opponent;

  const BattlerAbilityEffectResolution({
    required this.owner,
    required this.opponent,
  });
}

abstract class BattlerAbilityEffect {
  const BattlerAbilityEffect();

  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  BattlerAbilityEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  BattlerAbilityEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    return damage;
  }

  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damage,
  }) {
    return damage;
  }

  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: target);
  }

  BattlerAbilityEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damageTaken,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: source);
  }

  BattlerAbilityEffectResolution applyPassive({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }
}

class CriticalScannerAbilityEffect extends BattlerAbilityEffect {
  const CriticalScannerAbilityEffect();

  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (!ability.isActive) return damage;

    return damage + ability.value;
  }

  @override
  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    if (!ability.isActive) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: target);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.startCooldown()),
      opponent: target,
    );
  }
}

class WeaknessHunterAbilityEffect extends BattlerAbilityEffect {
  const WeaknessHunterAbilityEffect();

  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    final targetHasDebuff = target.statuses.any(
      (status) => status.type == BattlerStatusType.debuff,
    );
    if (!targetHasDebuff) return damage;

    return damage + ability.value;
  }
}

class GhostMeshAbilityEffect extends BattlerAbilityEffect {
  const GhostMeshAbilityEffect();

  @override
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (damage <= 0 || owner.health < owner.maxHealth) return damage;

    return (damage / max(1, ability.value)).ceil();
  }
}

class CruelCatalysisAbilityEffect extends BattlerAbilityEffect {
  const CruelCatalysisAbilityEffect();

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final updatedOpponent = opponent.applyStatus(
      CatalisisCruelStatus(value: max(2, ability.value)),
    );

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.startCooldown()),
      opponent: updatedOpponent,
    );
  }
}

class VenousOverloadAbilityEffect extends BattlerAbilityEffect {
  const VenousOverloadAbilityEffect();

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(
      owner: owner,
      opponent: opponent,
    );
  }

  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (!ability.isActive) return damage;

    return damage + ability.value;
  }

  @override
  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    if (!ability.isActive) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: target);
    }

    final burnTurns = max(1, ability.value ~/ 2);
    final updatedOwner = owner
        .applyStatus(QuemaduraStatus(remainingTurns: burnTurns))
        .updateAbility(ability.startCooldown());

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: target,
    );
  }
}

class HardResetAbilityEffect extends BattlerAbilityEffect {
  const HardResetAbilityEffect();

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    var updatedOwner = owner;
    final removableDebuffs = updatedOwner.statuses
        .where((status) => status.type == BattlerStatusType.debuff)
        .take(max(0, ability.value))
        .toList(growable: false);

    for (final debuff in removableDebuffs) {
      updatedOwner = updatedOwner.removeStatusInstance(debuff);
    }

    final selfDamage = max(
      1,
      ((updatedOwner.maxHealth * ability.value) / 10).round(),
    );

    updatedOwner = updatedOwner
        .receiveDamage(selfDamage)
        .updateAbility(ability.startCooldown());

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: opponent,
    );
  }
}

class BattlerAbility {
  final BattlerAbilityId id;
  final String name;
  final String description;
  final IconData icon;
  final int cooldownTurns;
  final int remainingCooldownTurns;
  final int value;
  final int upgradeValue;
  final bool isActive;
  final BattlerAbilityActivationContext? manualActivationContext;
  final BattlerAbilityEffect? effect;
  final bool isImplemented;

  const BattlerAbility({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.cooldownTurns = 0,
    this.remainingCooldownTurns = 0,
    this.value = 0,
    this.upgradeValue = 0,
    this.isActive = false,
    this.manualActivationContext,
    this.effect,
    this.isImplemented = true,
  })  : assert(cooldownTurns >= 0),
        assert(remainingCooldownTurns >= 0);

  bool get hasEffect => effect != null;
  bool get canManuallyActivate => manualActivationContext != null;
  bool get isOnCooldown => remainingCooldownTurns > 0;

  String get cooldownLabel {
    if (cooldownTurns <= 0) return 'Sin cooldown';
    if (cooldownTurns == 1) return '1 turno';
    return '$cooldownTurns turnos';
  }

  String get remainingCooldownLabel {
    if (!isOnCooldown) return 'Disponible';
    if (remainingCooldownTurns == 1) return '1 turno';
    return '$remainingCooldownTurns turnos';
  }

  bool canToggleOn(BattlerAbilityActivationContext screenContext) {
    return manualActivationContext == screenContext;
  }

  bool canActivateOn(BattlerAbilityActivationContext screenContext) {
    return canToggleOn(screenContext) && !isActive && !isOnCooldown;
  }

  bool canDeactivateOn(BattlerAbilityActivationContext screenContext) {
    return canToggleOn(screenContext) && isActive;
  }

  BattlerAbility upgraded() {
    if (upgradeValue <= 0) return this;

    return copyWith(value: value + upgradeValue);
  }

  BattlerAbility activate() => copyWith(isActive: true);

  BattlerAbility deactivate() => copyWith(isActive: false);

  BattlerAbility startCooldown() {
    return copyWith(
      isActive: false,
      remainingCooldownTurns: cooldownTurns,
    );
  }

  BattlerAbility tickCooldown() {
    if (!isOnCooldown || isActive) return this;

    return copyWith(
      remainingCooldownTurns: max(0, remainingCooldownTurns - 1),
    );
  }

  BattlerAbility resetState() {
    return copyWith(
      isActive: false,
      remainingCooldownTurns: 0,
    );
  }

  BattlerAbility copyWith({
    String? name,
    String? description,
    IconData? icon,
    int? cooldownTurns,
    int? remainingCooldownTurns,
    int? value,
    int? upgradeValue,
    bool? isActive,
    BattlerAbilityActivationContext? manualActivationContext,
    bool clearManualActivationContext = false,
    BattlerAbilityEffect? effect,
    bool clearEffect = false,
    bool? isImplemented,
  }) {
    return BattlerAbility(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      cooldownTurns: max(0, cooldownTurns ?? this.cooldownTurns),
      remainingCooldownTurns: max(
        0,
        remainingCooldownTurns ?? this.remainingCooldownTurns,
      ),
      value: value ?? this.value,
      upgradeValue: upgradeValue ?? this.upgradeValue,
      isActive: isActive ?? this.isActive,
      manualActivationContext: clearManualActivationContext
          ? null
          : manualActivationContext ?? this.manualActivationContext,
      effect: clearEffect ? null : effect ?? this.effect,
      isImplemented: isImplemented ?? this.isImplemented,
    );
  }

  static BattlerAbility fromLegacy(Object value) {
    if (value is BattlerAbility) return value;
    if (value is BattlerAbilityId) return presetForId(value);
    if (value is! String) {
      throw ArgumentError.value(value, 'value', 'Unsupported ability value.');
    }

    switch (value.trim().toLowerCase()) {
      case 'defender':
      case 'defend':
        return defendAbility;
      case 'overclock':
        return overclockAbility;
      case 'purge':
        return purgeAbility;
      case 'escaner critico':
      case 'scanner critico':
      case 'critical scanner':
        return criticalScannerAbility;
      case 'caza de debilidades':
      case 'weakness hunter':
        return weaknessHunterAbility;
      case 'malla fantasma':
      case 'ghost mesh':
        return ghostMeshAbility;
      case 'catalisis cruel':
      case 'cruel catalysis':
        return cruelCatalysisAbility;
      case 'sobrecarga venosa':
      case 'venous overload':
        return venousOverloadAbility;
      case 'reinicio en seco':
      case 'hard reset':
        return hardResetAbility;
    }

    throw ArgumentError.value(value, 'value', 'Unknown battler ability.');
  }

  static BattlerAbility presetForId(BattlerAbilityId id) {
    switch (id) {
      case BattlerAbilityId.defend:
        return defendAbility;
      case BattlerAbilityId.overclock:
        return overclockAbility;
      case BattlerAbilityId.purge:
        return purgeAbility;
      case BattlerAbilityId.criticalScanner:
        return criticalScannerAbility;
      case BattlerAbilityId.weaknessHunter:
        return weaknessHunterAbility;
      case BattlerAbilityId.ghostMesh:
        return ghostMeshAbility;
      case BattlerAbilityId.cruelCatalysis:
        return cruelCatalysisAbility;
      case BattlerAbilityId.venousOverload:
        return venousOverloadAbility;
      case BattlerAbilityId.hardReset:
        return hardResetAbility;
    }
  }
}

const defendAbility = BattlerAbility(
  id: BattlerAbilityId.defend,
  name: 'Defender',
  description: 'Accion basica. Consume el turno sin atacar.',
  icon: Icons.shield_outlined,
  isImplemented: true,
);

const overclockAbility = BattlerAbility(
  id: BattlerAbilityId.overclock,
  name: 'Overclock',
  description: 'TODO: aplicar una mejora temporal de ataque.',
  icon: Icons.bolt_rounded,
  isImplemented: false,
);

const purgeAbility = BattlerAbility(
  id: BattlerAbilityId.purge,
  name: 'Purge',
  description: 'TODO: aplicar una habilidad ofensiva especial.',
  icon: Icons.cleaning_services_outlined,
  isImplemented: false,
);

const criticalScannerAbility = BattlerAbility(
  id: BattlerAbilityId.criticalScanner,
  name: 'Escaner critico',
  description:
      'Activacion manual en combate. El siguiente ataque inflige dano adicional igual a su value.',
  icon: Icons.radar_rounded,
  cooldownTurns: 3,
  value: 3,
  upgradeValue: 2,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: CriticalScannerAbilityEffect(),
  isImplemented: true,
);

const weaknessHunterAbility = BattlerAbility(
  id: BattlerAbilityId.weaknessHunter,
  name: 'Caza de debilidades',
  description:
      'Pasiva. Tus ataques infligen dano adicional si el objetivo ya tiene al menos un debuff.',
  icon: Icons.track_changes_rounded,
  value: 2,
  upgradeValue: 2,
  effect: WeaknessHunterAbilityEffect(),
  isImplemented: true,
);

const ghostMeshAbility = BattlerAbility(
  id: BattlerAbilityId.ghostMesh,
  name: 'Malla Fantasma',
  description:
      'Pasiva. Si tu vida esta al maximo, el dano recibido por ataques se reduce a la mitad, redondeando hacia arriba.',
  icon: Icons.security_rounded,
  value: 2,
  effect: GhostMeshAbilityEffect(),
  isImplemented: true,
);

const cruelCatalysisAbility = BattlerAbility(
  id: BattlerAbilityId.cruelCatalysis,
  name: 'Catalisis Cruel',
  description:
      'Activacion manual en combate. Aplica al enemigo un debuff que duplica el valor de la siguiente desventaja que reciba.',
  icon: Icons.biotech_rounded,
  cooldownTurns: 2,
  value: 2,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: CruelCatalysisAbilityEffect(),
  isImplemented: true,
);

const venousOverloadAbility = BattlerAbility(
  id: BattlerAbilityId.venousOverload,
  name: 'Sobrecarga venosa',
  description:
      'Activacion manual en combate. El siguiente ataque inflige dano adicional igual a su value, pero te aplica Quemadura por value/2 turnos.',
  icon: Icons.flash_on_rounded,
  value: 4,
  upgradeValue: 2,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: VenousOverloadAbilityEffect(),
  isImplemented: true,
);

const hardResetAbility = BattlerAbility(
  id: BattlerAbilityId.hardReset,
  name: 'Reinicio en seco',
  description:
      'Activacion manual en ruta. Elimina debuffs propios y luego te inflige dano igual al 10% de tu vida maxima por cada punto de value.',
  icon: Icons.refresh_rounded,
  value: 1,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.pathSelection,
  effect: HardResetAbilityEffect(),
  isImplemented: true,
);
