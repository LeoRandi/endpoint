import '../_imports.dart';

/// Enumera los ids estables usados para guardar y resolver presets de habilidades.
enum BattlerAbilityId {
  criticalScanner,
  weaknessHunter,
  ghostMesh,
  cruelCatalysis,
  venousOverload,
  hardReset,
}

/// Define en que pantalla puede activarse manualmente una habilidad.
enum BattlerAbilityActivationContext {
  battle,
  pathSelection,
  shop;

  /// Devuelve la etiqueta corta que usa la UI para mostrar este contexto.
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

const _ataqueAbilityTags = <EntityTag>[
  EntityTag.ataque,
];
const _ataqueDebuffAbilityTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.debuff,
];
const _vidaDefensaAbilityTags = <EntityTag>[
  EntityTag.vida,
  EntityTag.defensa,
];
const _debuffAbilityTags = <EntityTag>[
  EntityTag.debuff,
];
const _ataqueQuemaduraAbilityTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.debuff,
  EntityTag.quemadura,
];
const _vidaDebuffAbilityTags = <EntityTag>[
  EntityTag.vida,
  EntityTag.debuff,
];

/// Agrupa el estado final del usuario y del rival tras resolver un efecto de habilidad.
class BattlerAbilityEffectResolution {
  final Battler owner;
  final Battler opponent;

  /// Crea una resolucion inmutable con ambos combatientes ya actualizados.
  const BattlerAbilityEffectResolution({
    required this.owner,
    required this.opponent,
  });
}

/// Sirve como base comun para los hooks de habilidades activas y pasivas.
abstract class BattlerAbilityEffect {
  /// Construye un efecto sin estado propio para reutilizarlo en presets const.
  const BattlerAbilityEffect();

  /// Resuelve lo que pasa al activar manualmente la habilidad.
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve efectos que deben dispararse al inicio de turno.
  BattlerAbilityEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve efectos que deben dispararse al final de turno.
  BattlerAbilityEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve efectos puntuales al terminar el combate antes de resetear runtime.
  Battler onCombatEnd({
    required Battler owner,
    required BattlerAbility ability,
  }) {
    return owner;
  }

  /// Ajusta el dano que el portador va a infligir antes de aplicarlo.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    return damage;
  }

  /// Ajusta el dano que el portador va a recibir antes de aplicarlo.
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damage,
  }) {
    return damage;
  }

  /// Resuelve efectos posteriores a que el portador complete un ataque.
  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: target);
  }

  /// Resuelve efectos posteriores a que el portador reciba dano.
  BattlerAbilityEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damageTaken,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: source);
  }

  /// Aplica efectos pasivos que deben reevaluarse sin necesidad de un evento puntual.
  BattlerAbilityEffectResolution applyPassive({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }
}

/// Hace que el siguiente ataque activo pegue mas y luego entre en cooldown.
class CriticalScannerAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para el preset de Escaner critico.
  const CriticalScannerAbilityEffect();

  @override

  /// Suma el value actual solo mientras la habilidad siga activada.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (!ability.isActive) return damage;

    return damage + ability.currentValue;
  }

  @override

  /// Consume la activacion al resolver el golpe y arranca su cooldown.
  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    if (!ability.isActive || owner.hasPendingBasicAttackFollowUp) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: target);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.startCooldown()),
      opponent: target,
    );
  }
}

/// Premia atacar objetivos ya debilitados con dano extra constante.
class WeaknessHunterAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para el preset de Caza de debilidades.
  const WeaknessHunterAbilityEffect();

  @override

  /// Suma dano solo si el objetivo ya tiene al menos un debuff.
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

    return damage + ability.currentValue;
  }
}

/// Reduce el dano recibido mientras el portador siga con la vida al maximo.
class GhostMeshAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para el preset de Malla Fantasma.
  const GhostMeshAbilityEffect();

  @override

  /// Divide el dano entrante por el value cuando el usuario esta intacto.
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (damage <= 0 || owner.health < owner.maxHealth) return damage;

    return (damage / max(1, ability.currentValue)).ceil();
  }
}

/// Aplica Catalisis Cruel al rival y consume la activacion en combate.
class CruelCatalysisAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para el preset de Catalisis Cruel.
  const CruelCatalysisAbilityEffect();

  @override

  /// Coloca el debuff en el rival y pone la habilidad en cooldown.
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final updatedOpponent = opponent.applyStatus(
      CatalisisCruelStatus(value: max(2, ability.currentValue)),
      source: owner,
    );

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.startCooldown()),
      opponent: updatedOpponent,
    );
  }
}

/// Convierte el siguiente ataque en uno mas fuerte a cambio de Quemadura propia.
class VenousOverloadAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para el preset de Sobrecarga venosa.
  const VenousOverloadAbilityEffect();

  @override

  /// Al activarse no cambia nada todavia porque el bonus se consume al atacar.
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

  /// Suma el value actual solo mientras la preparacion siga activa.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (!ability.isActive) return damage;

    return damage + ability.currentValue;
  }

  @override

  /// Tras pegar, se aplica Quemadura propia y la habilidad entra en cooldown.
  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    if (!ability.isActive || owner.hasPendingBasicAttackFollowUp) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: target);
    }

    final burnTurns = max(1, ability.currentValue ~/ 2);
    final updatedOwner = owner
        .applyStatus(
          QuemaduraStatus(remainingTurns: burnTurns),
          source: owner,
        )
        .updateAbility(ability.startCooldown());

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: target,
    );
  }
}

/// Limpia debuffs purgables del usuario y cobra vida en proporcion al value.
class HardResetAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para el preset de Reinicio en seco.
  const HardResetAbilityEffect();

  @override

  /// Purga debuffs, luego hace dano propio y finalmente inicia el cooldown.
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    var updatedOwner = owner;
    final removableDebuffs = updatedOwner.statuses
        .where(
          (status) =>
              status.type == BattlerStatusType.debuff && status.isPurgeable,
        )
        .take(max(0, ability.currentValue))
        .toList(growable: false);

    for (final debuff in removableDebuffs) {
      updatedOwner = updatedOwner.removeStatusInstance(debuff);
    }

    final selfDamage = max(
      1,
      ((updatedOwner.maxHealth * ability.currentValue) / 10).round(),
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

/// Describe una habilidad completa, incluyendo su estado runtime y su efecto.
class BattlerAbility {
  final BattlerAbilityId id;
  final RarityTier rarity;
  final List<EntityTag> tags;
  final String name;
  final String description;
  final IconData icon;
  final int cooldownTurns;
  final int remainingCooldownTurns;
  final int value;
  final int upgradeValue;
  final int runtimeValueBonus;
  final bool isActive;
  final BattlerAbilityActivationContext? manualActivationContext;
  final BattlerAbilityEffect? effect;
  final bool isImplemented;

  /// Crea una habilidad inmutable lista para usarse como preset o como instancia runtime.
  const BattlerAbility({
    required this.id,
    this.rarity = RarityTier.gray,
    this.tags = const [],
    required this.name,
    required this.description,
    required this.icon,
    this.cooldownTurns = 0,
    this.remainingCooldownTurns = 0,
    this.value = 0,
    this.upgradeValue = 0,
    this.runtimeValueBonus = 0,
    this.isActive = false,
    this.manualActivationContext,
    this.effect,
    this.isImplemented = true,
  })  : assert(cooldownTurns >= 0),
        assert(remainingCooldownTurns >= 0);

  /// Indica si esta habilidad tiene hooks propios que deben ejecutarse.
  bool get hasEffect => effect != null;

  /// Indica si la habilidad tiene al menos una tag visible o filtrable.
  bool get hasTags => tags.isNotEmpty;

  /// Comprueba si esta habilidad pertenece a una tag concreta.
  bool hasTag(EntityTag tag) => tags.contains(tag);

  /// Reexpone el color de rareza para que la UI no tenga que duplicar este lookup.
  Color get accent => rarity.accent;

  /// Indica si la habilidad puede activarse desde alguna pantalla.
  bool get canManuallyActivate => manualActivationContext != null;

  /// Indica si la habilidad es pasiva y no requiere ninguna pantalla para activarse.
  bool get isPassive => manualActivationContext == null;

  /// Indica si la habilidad sigue esperando a que termine su cooldown.
  bool get isOnCooldown => remainingCooldownTurns > 0;

  /// Devuelve el value base mas los bonus temporales ganados en combate.
  int get currentValue => value + runtimeValueBonus;

  /// Indica cuantas mejoras visibles lleva esta habilidad respecto a su preset.
  int get upgradeCount {
    final baseAbility = presetForId(id);
    final resolvedUpgradeValue =
        upgradeValue > 0 ? upgradeValue : baseAbility.upgradeValue;
    if (resolvedUpgradeValue <= 0 || value <= baseAbility.value) {
      return 0;
    }

    return max(0, (value - baseAbility.value) ~/ resolvedUpgradeValue);
  }

  /// Devuelve el nombre visible incluyendo el sufijo de mejora cuando proceda.
  String get displayName {
    if (upgradeCount <= 0) return name;

    return '$name +$upgradeCount';
  }

  /// Devuelve el cooldown base en un formato corto para la interfaz.
  String get cooldownLabel {
    if (cooldownTurns <= 0) return 'Sin cooldown';
    if (cooldownTurns == 1) return '1 turno';
    return '$cooldownTurns turnos';
  }

  /// Devuelve el estado actual del cooldown en un formato corto para la interfaz.
  String get remainingCooldownLabel {
    if (!isOnCooldown) return 'Disponible';
    if (remainingCooldownTurns == 1) return '1 turno';
    return '$remainingCooldownTurns turnos';
  }

  /// Comprueba si esta habilidad pertenece al contexto manual indicado.
  bool canToggleOn(BattlerAbilityActivationContext screenContext) {
    return manualActivationContext == screenContext;
  }

  /// Indica si esta habilidad debe mostrarse en la interfaz del contexto indicado.
  bool appearsInContext(BattlerAbilityActivationContext screenContext) {
    return isPassive || canToggleOn(screenContext);
  }

  /// Comprueba si puede activarse ahora mismo sin estar activa ni en cooldown.
  bool canActivateOn(BattlerAbilityActivationContext screenContext) {
    return canToggleOn(screenContext) && !isActive && !isOnCooldown;
  }

  /// Comprueba si puede apagarse manualmente en el contexto actual.
  bool canDeactivateOn(BattlerAbilityActivationContext screenContext) {
    return canToggleOn(screenContext) && isActive;
  }

  /// Devuelve una version mejorada sumando el upgradeValue al value base.
  BattlerAbility upgraded() {
    final upgradeTemplate = upgradeValue > 0 ? this : presetForId(id);
    if (upgradeTemplate.upgradeValue <= 0) return this;

    return copyWith(
      rarity: upgradeTemplate.rarity,
      tags: upgradeTemplate.tags,
      name: upgradeTemplate.name,
      description: upgradeTemplate.description,
      icon: upgradeTemplate.icon,
      cooldownTurns: upgradeTemplate.cooldownTurns,
      value: value + upgradeTemplate.upgradeValue,
      upgradeValue: upgradeTemplate.upgradeValue,
      manualActivationContext: upgradeTemplate.manualActivationContext,
      effect: upgradeTemplate.effect,
      isImplemented: upgradeTemplate.isImplemented,
    );
  }

  /// Marca la habilidad como activa sin tocar todavia su cooldown.
  BattlerAbility activate() => copyWith(isActive: true);

  /// Desactiva la habilidad y limpia cualquier bonus temporal asociado.
  BattlerAbility deactivate() => copyWith(
        isActive: false,
        runtimeValueBonus: 0,
      );

  /// Entra en cooldown, se desactiva y limpia los bonus temporales.
  BattlerAbility startCooldown() {
    return copyWith(
      isActive: false,
      remainingCooldownTurns: cooldownTurns,
      runtimeValueBonus: 0,
    );
  }

  /// Reduce en uno el cooldown al inicio de turno cuando proceda.
  BattlerAbility tickCooldown() {
    if (!isOnCooldown || isActive) return this;

    return copyWith(
      remainingCooldownTurns: max(0, remainingCooldownTurns - 1),
    );
  }

  /// Devuelve la habilidad a su estado limpio para salir de combate o resetear.
  BattlerAbility resetState() {
    return copyWith(
      isActive: false,
      remainingCooldownTurns: 0,
      runtimeValueBonus: 0,
    );
  }

  /// Acumula un bonus temporal al value sin alterar el preset base.
  BattlerAbility addRuntimeValueBonus(int amount) {
    if (amount == 0) return this;

    return copyWith(runtimeValueBonus: runtimeValueBonus + amount);
  }

  /// Reduce el cooldown restante sin permitir valores negativos.
  BattlerAbility reduceCooldown(int amount) {
    if (amount <= 0 || !isOnCooldown) return this;

    return copyWith(
      remainingCooldownTurns: max(0, remainingCooldownTurns - amount),
    );
  }

  /// Clona la habilidad permitiendo cambiar cualquier parte de su estado.
  BattlerAbility copyWith({
    RarityTier? rarity,
    List<EntityTag>? tags,
    String? name,
    String? description,
    IconData? icon,
    int? cooldownTurns,
    int? remainingCooldownTurns,
    int? value,
    int? upgradeValue,
    int? runtimeValueBonus,
    bool? isActive,
    BattlerAbilityActivationContext? manualActivationContext,
    bool clearManualActivationContext = false,
    BattlerAbilityEffect? effect,
    bool clearEffect = false,
    bool? isImplemented,
  }) {
    return BattlerAbility(
      id: id,
      rarity: rarity ?? this.rarity,
      tags: tags ?? this.tags,
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
      runtimeValueBonus: runtimeValueBonus ?? this.runtimeValueBonus,
      isActive: isActive ?? this.isActive,
      manualActivationContext: clearManualActivationContext
          ? null
          : manualActivationContext ?? this.manualActivationContext,
      effect: clearEffect ? null : effect ?? this.effect,
      isImplemented: isImplemented ?? this.isImplemented,
    );
  }

  /// Devuelve el preset canonico asociado a un id de habilidad.
  static BattlerAbility presetForId(BattlerAbilityId id) {
    switch (id) {
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

/// Preset que prepara un siguiente ataque potenciado y luego entra en cooldown.
const criticalScannerAbility = BattlerAbility(
  id: BattlerAbilityId.criticalScanner,
  rarity: RarityTier.blue,
  tags: _ataqueAbilityTags,
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

/// Preset pasivo que castiga a los enemigos que ya tienen algun debuff.
const weaknessHunterAbility = BattlerAbility(
  id: BattlerAbilityId.weaknessHunter,
  tags: _ataqueDebuffAbilityTags,
  name: 'Caza de debilidades',
  description:
      'Pasiva. Tus ataques infligen dano adicional si el objetivo ya tiene al menos un debuff.',
  icon: Icons.track_changes_rounded,
  value: 2,
  upgradeValue: 2,
  effect: WeaknessHunterAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo defensivo que protege mientras la vida siga llena.
const ghostMeshAbility = BattlerAbility(
  id: BattlerAbilityId.ghostMesh,
  tags: _vidaDefensaAbilityTags,
  name: 'Malla Fantasma',
  description:
      'Pasiva. Si tu vida esta al maximo, el dano recibido por ataques se reduce a la mitad, redondeando hacia arriba.',
  icon: Icons.security_rounded,
  value: 2,
  effect: GhostMeshAbilityEffect(),
  isImplemented: true,
);

/// Preset manual que duplica la siguiente desventaja recibida por el objetivo.
const cruelCatalysisAbility = BattlerAbility(
  id: BattlerAbilityId.cruelCatalysis,
  rarity: RarityTier.yellow,
  tags: _debuffAbilityTags,
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

/// Preset manual que potencia un golpe y aplica Quemadura al propio usuario.
const venousOverloadAbility = BattlerAbility(
  id: BattlerAbilityId.venousOverload,
  tags: _ataqueQuemaduraAbilityTags,
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

/// Preset manual de ruta que purga debuffs purgables a cambio de vida.
const hardResetAbility = BattlerAbility(
  id: BattlerAbilityId.hardReset,
  tags: _vidaDebuffAbilityTags,
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
