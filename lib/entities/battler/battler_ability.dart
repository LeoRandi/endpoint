import '../_imports.dart';
import '../../services/battler_runtime_service.dart';

part 'abilities/battler_ability_effects.dart';
part 'abilities/battler_ability_presets.dart';

/// Enumera los ids estables usados para guardar y resolver presets de habilidades.
enum BattlerAbilityId {
  criticalScanner,
  weaknessHunter,
  ghostMesh,
  ritmoCircadiano,
  cambioDeGuardia,
  toqueDeQueda,
  turnoDeNoche,
  amanecerSintetico,
  lunaArtificial,
  eclipseManual,
  cruelCatalysis,
  venousOverload,
  hardReset,
  cashflow,
  pulsoRepL,
  sustraccion,
  limpiezaCache,
  hemostasiaAgresiva,
  mallaRebote,
  inyeccionCorrosiva,
  escanerRuptura,
  reenrutadoInverso,
  jaulaSenal,
  nucleoParasitario,
  espejoDolor,
  protocoloUsurpacion,
  refactorizacionTimeline,
  monopolio,
  compraDeOportunidad,
  diversificacionHostil,
  convencionRepentina,
  furiaHematica,
  mordidaDeAcero,
  noHayRetirada,
  pulsoArmonico,
  masaCritica,
  descargaSismica,
  cortafuegosPortatil,
  marcaDeCaza,
  cadenciaRapida,
  extrabloqueo,
  triageAutomatico,
  opresionTactica,
  sobrecargaRegulada,
  copiaDeSeguridad,
  puntoCiego,
  provocacionFrontal,
  cargaTemeraria,
  mandatoColiseo,
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

/// Identifica a que arquetipos pertenece una habilidad para ofertas y contenido.
enum BattlerAbilityArchetypeAffinity {
  general,
  veloz,
  inamovible,
  imparable,
  mercante,
}

/// Traduce afinidades de habilidad a arquetipos jugables.
extension BattlerAbilityArchetypeAffinityMapping
    on BattlerAbilityArchetypeAffinity {
  bool get isSpecific => this != BattlerAbilityArchetypeAffinity.general;

  ArchetypeId? get archetypeId {
    switch (this) {
      case BattlerAbilityArchetypeAffinity.general:
        return null;
      case BattlerAbilityArchetypeAffinity.veloz:
        return ArchetypeId.veloz;
      case BattlerAbilityArchetypeAffinity.inamovible:
        return ArchetypeId.inamovible;
      case BattlerAbilityArchetypeAffinity.imparable:
        return ArchetypeId.imparable;
      case BattlerAbilityArchetypeAffinity.mercante:
        return ArchetypeId.mercante;
    }
  }
}

/// Traduce arquetipos jugables a la afinidad usada por las habilidades.
extension ArchetypeIdAbilityAffinity on ArchetypeId {
  BattlerAbilityArchetypeAffinity get abilityAffinity {
    switch (this) {
      case ArchetypeId.veloz:
        return BattlerAbilityArchetypeAffinity.veloz;
      case ArchetypeId.inamovible:
        return BattlerAbilityArchetypeAffinity.inamovible;
      case ArchetypeId.imparable:
        return BattlerAbilityArchetypeAffinity.imparable;
      case ArchetypeId.mercante:
        return BattlerAbilityArchetypeAffinity.mercante;
    }
  }
}

/// Enumera los puntos del ciclo de combate en los que una habilidad puede aportar hooks.
enum BattlerAbilityHook {
  hourStart,
  turnStart,
  turnEnd,
  combatEnd,
  outgoingDamageModifier,
  incomingDamageModifier,
  incomingStatusModifier,
  attackResolved,
  receiveDamageResolved,
  fatalDamage,
  passive,
}

const _ataqueAbilityTags = <EntityTag>[
  EntityTag.ataque,
];
const _ataqueDebuffAbilityTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.debuff,
];
const _vidaBarreraAbilityTags = <EntityTag>[
  EntityTag.vida,
  EntityTag.barrera,
];
const _debuffAbilityTags = <EntityTag>[
  EntityTag.debuff,
];
const _debuffBarreraAbilityTags = <EntityTag>[
  EntityTag.debuff,
  EntityTag.barrera,
];
const _buffAbilityTags = <EntityTag>[
  EntityTag.buff,
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
const _economiaAbilityTags = <EntityTag>[
  EntityTag.economia,
];
const _vidaAbilityTags = <EntityTag>[
  EntityTag.vida,
];
const _buffBarreraAbilityTags = <EntityTag>[
  EntityTag.buff,
  EntityTag.barrera,
];
const _economiaAtaqueBarreraAbilityTags = <EntityTag>[
  EntityTag.economia,
  EntityTag.ataque,
  EntityTag.barrera,
];
const _ataqueBarreraAbilityTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.barrera,
];
const _vidaAtaqueAbilityTags = <EntityTag>[
  EntityTag.vida,
  EntityTag.ataque,
];
const _intoxicacionDebuffAbilityTags = <EntityTag>[
  EntityTag.intoxicacion,
  EntityTag.debuff,
];
const _buffAtaqueAbilityTags = <EntityTag>[
  EntityTag.buff,
  EntityTag.ataque,
];
const _buffDebuffAbilityTags = <EntityTag>[
  EntityTag.buff,
  EntityTag.debuff,
];
const _buffDebuffBarreraAbilityTags = <EntityTag>[
  EntityTag.buff,
  EntityTag.debuff,
  EntityTag.barrera,
];
const _desafioAtaqueAbilityTags = <EntityTag>[
  EntityTag.desafio,
  EntityTag.ataque,
  EntityTag.buff,
];
const _cicloBuffAbilityTags = <EntityTag>[
  EntityTag.ciclo,
  EntityTag.buff,
];
const _cicloVidaAtaqueBuffAbilityTags = <EntityTag>[
  EntityTag.ciclo,
  EntityTag.vida,
  EntityTag.ataque,
  EntityTag.buff,
];
const _cicloAtaqueBarreraBuffAbilityTags = <EntityTag>[
  EntityTag.ciclo,
  EntityTag.ataque,
  EntityTag.barrera,
  EntityTag.buff,
];
const _cicloAtaqueBarreraDebuffAbilityTags = <EntityTag>[
  EntityTag.ciclo,
  EntityTag.ataque,
  EntityTag.barrera,
  EntityTag.debuff,
];
const _resonanciaBarreraAbilityTags = <EntityTag>[
  EntityTag.resonancia,
  EntityTag.barrera,
  EntityTag.buff,
];
const _resonanciaAtaqueBarreraAbilityTags = <EntityTag>[
  EntityTag.resonancia,
  EntityTag.ataque,
  EntityTag.barrera,
];
const _resonanciaAtaqueBarreraDebuffAbilityTags = <EntityTag>[
  EntityTag.resonancia,
  EntityTag.ataque,
  EntityTag.barrera,
  EntityTag.debuff,
];

/// Devuelve un indice pseudoaleatorio estable para efectos que piden elegir objetivos aleatorios.
int _stableSelectionIndex({
  required Battler owner,
  required Battler opponent,
  required int length,
  int salt = 0,
}) {
  if (length <= 1) return 0;

  final seed = owner.health * 31 +
      owner.currentBarrier * 17 +
      owner.money * 13 +
      owner.abilities.length * 11 +
      owner.statuses.length * 7 +
      opponent.health * 5 +
      opponent.currentBarrier * 3 +
      opponent.abilities.length * 2 +
      opponent.statuses.length +
      salt;

  return seed.abs() % length;
}

BattlerAbilityEffectResolution _applyAbilityStatusToOpponentFromOwner({
  required Battler owner,
  required Battler opponent,
  required BattlerStatus status,
  bool applyEquipmentModifiers = true,
}) {
  final resolution = opponent.applyStatusFromSourceResolved(
    status,
    source: owner,
    applyEquipmentModifiers: applyEquipmentModifiers,
  );
  return BattlerAbilityEffectResolution(
    owner: resolution.source,
    opponent: resolution.owner,
  );
}

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

/// Agrupa el resultado de interceptar un estado entrante con una habilidad.
class BattlerAbilityIncomingStatusResolution {
  final Battler owner;
  final Battler source;
  final BattlerStatus? status;

  /// Crea una resolucion para modificar o cancelar un estado entrante.
  const BattlerAbilityIncomingStatusResolution({
    required this.owner,
    required this.source,
    required this.status,
  });
}

/// Sirve como base comun para los hooks de habilidades activas y pasivas.
abstract class BattlerAbilityEffect {
  final Set<BattlerAbilityHook> hooks;

  /// Construye un efecto sin estado propio para reutilizarlo en presets const.
  const BattlerAbilityEffect({
    this.hooks = const <BattlerAbilityHook>{},
  });

  /// Resuelve lo que pasa al activar manualmente la habilidad.
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve efectos pasivos que deben dispararse al comenzar una nueva hora.
  Battler onHourStart({
    required Battler owner,
    required BattlerAbility ability,
  }) {
    return owner;
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

  /// Ajusta el daño que el portador va a infligir antes de aplicarlo.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    return damage;
  }

  /// Ajusta el daño que el portador va a recibir antes de aplicarlo.
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damage,
  }) {
    return damage;
  }

  /// Permite alterar o cancelar un estado recibido antes de que se aplique.
  BattlerAbilityIncomingStatusResolution onIncomingStatus({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required BattlerStatus status,
  }) {
    return BattlerAbilityIncomingStatusResolution(
      owner: owner,
      source: source,
      status: status,
    );
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

  /// Resuelve efectos posteriores a que el portador reciba daño.
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

  /// Permite interceptar un golpe letal justo antes de que el portador muera.
  Battler onReceiveFatalDamage({
    required Battler owner,
    required BattlerAbility ability,
    required int incomingDamage,
  }) {
    return owner;
  }
}

/// Describe una habilidad completa, incluyendo su estado runtime y su efecto.
class BattlerAbility {
  final BattlerAbilityId id;
  final List<BattlerAbilityArchetypeAffinity> archetypeAffinities;
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
    this.archetypeAffinities = const [
      BattlerAbilityArchetypeAffinity.general,
    ],
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

  /// Expone los hooks activos del efecto para que el battler pueda indexarlos.
  Set<BattlerAbilityHook> get hookBindings =>
      effect?.hooks ?? const <BattlerAbilityHook>{};

  /// Indica si la habilidad tiene al menos una tag visible o filtrable.
  bool get hasTags => tags.isNotEmpty;

  /// Comprueba si esta habilidad pertenece a una tag concreta.
  bool hasTag(EntityTag tag) => tags.contains(tag);

  /// Comprueba si la habilidad declara afinidad con un arquetipo concreto.
  bool hasArchetypeAffinity(BattlerAbilityArchetypeAffinity affinity) {
    return archetypeAffinities.contains(affinity);
  }

  /// Comprueba si comparte afinidad con alguna de las pedidas.
  bool hasAnyArchetypeAffinity(
    Iterable<BattlerAbilityArchetypeAffinity> affinities,
  ) {
    for (final affinity in affinities) {
      if (hasArchetypeAffinity(affinity)) {
        return true;
      }
    }
    return false;
  }

  /// Reexpone el color de rareza para que la UI no tenga que duplicar este lookup.
  Color get accent => rarity.accent;

  /// Indica si la habilidad puede activarse desde alguna pantalla.
  bool get canManuallyActivate => manualActivationContext != null;

  /// Indica si la habilidad es pasiva y no requiere ninguna pantalla para activarse.
  bool get isPassive => manualActivationContext == null;

  /// Indica si la habilidad sigue esperando a que termine su cooldown.
  bool get isOnCooldown => remainingCooldownTurns > 0;

  /// Indica si el estado activo debe comunicarse como activacion manual visible.
  bool get isManualActivationActive => canManuallyActivate && isActive;

  /// Devuelve el value base mas los bonus temporales ganados en combate.
  int get currentValue => value + runtimeValueBonus;

  /// Indica si esta habilidad todavia puede escalar un tier mas.
  bool get canUpgrade {
    final baseAbility = presetForId(id);
    final resolvedUpgradeValue =
        upgradeValue != 0 ? upgradeValue : baseAbility.upgradeValue;

    return resolvedUpgradeValue != 0 && !rarity.isMaxTier;
  }

  /// Indica cuantas mejoras visibles lleva esta habilidad respecto a su preset.
  int get upgradeCount {
    final baseAbility = presetForId(id);
    final resolvedUpgradeValue =
        upgradeValue != 0 ? upgradeValue : baseAbility.upgradeValue;
    if (resolvedUpgradeValue == 0) {
      return 0;
    }

    if (resolvedUpgradeValue > 0) {
      if (value <= baseAbility.value) return 0;

      return max(0, (value - baseAbility.value) ~/ resolvedUpgradeValue);
    }

    if (value >= baseAbility.value) return 0;

    return max(
      0,
      (baseAbility.value - value) ~/ resolvedUpgradeValue.abs(),
    );
  }

  /// Devuelve el nombre visible de la habilidad sin marcadores extras de mejora.
  String get displayName => name;

  /// Devuelve la descripcion mecanica usando el valor actual de esta instancia.
  String get displayDescription => _abilityDescriptionFor(this);

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

  /// Devuelve una version mejorada subiendo tier y valor hasta el limite amarillo.
  BattlerAbility upgraded() {
    final upgradeTemplate = canUpgrade ? this : presetForId(id);
    if (!upgradeTemplate.canUpgrade) return this;

    return copyWith(
      archetypeAffinities: upgradeTemplate.archetypeAffinities,
      rarity: rarity.nextTier,
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
    List<BattlerAbilityArchetypeAffinity>? archetypeAffinities,
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
      archetypeAffinities: archetypeAffinities ?? this.archetypeAffinities,
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
    final preset = abilityPresetRegistry[id];
    if (preset != null) {
      return preset;
    }

    throw StateError('No existe preset para la habilidad ${id.name}.');
  }

  /// Ajusta la rareza visual de habilidades legacy segun sus mejoras ya guardadas.
  BattlerAbility normalizeUpgradeTier() {
    final preset = presetForId(id);
    final inferredRarity = preset.rarity.advanceBy(upgradeCount);
    if (rarity.index >= inferredRarity.index) return this;

    return copyWith(rarity: inferredRarity);
  }
}

String _abilityDescriptionFor(BattlerAbility ability) {
  final amount = max(0, ability.currentValue);
  final positiveAmount = max(1, ability.currentValue);

  switch (ability.id) {
    case BattlerAbilityId.criticalScanner:
      return 'Activacion manual en combate. El siguiente ataque inflige +$amount daño adicional.';
    case BattlerAbilityId.weaknessHunter:
      return 'Pasiva. Tus ataques infligen +$amount daño si el objetivo ya tiene al menos un debuff.';
    case BattlerAbilityId.ghostMesh:
      return 'Pasiva. Si tu vida esta al maximo, el daño recibido por ataques se divide entre $positiveAmount, redondeando hacia arriba.';
    case BattlerAbilityId.ritmoCircadiano:
      return 'Pasiva. Al inicio de tu turno: de dia te curas $positiveAmount HP y de noche ganas $positiveAmount de Potencia.';
    case BattlerAbilityId.cambioDeGuardia:
      return 'Activacion manual en combate. De dia ganas ${positiveAmount * 2} de Barrera; de noche ganas $positiveAmount de Potencia.';
    case BattlerAbilityId.toqueDeQueda:
      return 'Activacion manual en combate. De dia aplica Interferencia durante $positiveAmount turnos; de noche aplica Fragilidad durante $positiveAmount turnos.';
    case BattlerAbilityId.turnoDeNoche:
      return 'Pasiva. De dia reduces el daño recibido en $positiveAmount. De noche infliges +$positiveAmount daño.';
    case BattlerAbilityId.amanecerSintetico:
      return 'Activacion manual en ruta. Durante el proximo combate, tus efectos de Ciclo cuentan siempre como dia.';
    case BattlerAbilityId.lunaArtificial:
      return 'Activacion manual en ruta. Durante el proximo combate, tus efectos de Ciclo cuentan siempre como noche.';
    case BattlerAbilityId.eclipseManual:
      final activeTurns = min(3, positiveAmount);
      return 'Activacion manual en combate. Durante $activeTurns turnos, tus efectos de Ciclo cuentan como dia y noche a la vez.';
    case BattlerAbilityId.cruelCatalysis:
      return 'Activacion manual en combate. Aplica al enemigo un debuff que multiplica x${max(2, ability.currentValue)} la siguiente desventaja que reciba.';
    case BattlerAbilityId.venousOverload:
      return 'Activacion manual en combate. El siguiente ataque inflige +$amount daño adicional, pero te aplica Quemadura durante ${max(1, ability.currentValue ~/ 2)} turnos.';
    case BattlerAbilityId.hardReset:
      return 'Activacion manual en ruta. Elimina hasta $amount debuffs propios y luego te inflige ${max(0, amount * 10)}% de tu vida maxima como daño.';
    case BattlerAbilityId.cashflow:
      return 'Pasiva. Al comienzo de cada hora, ganas creditos iguales a tu income actual.';
    case BattlerAbilityId.pulsoRepL:
      return 'Pasiva. Al final de tu turno, ganas $amount de Barrera.';
    case BattlerAbilityId.sustraccion:
      return 'Activacion manual en combate. Tras el siguiente ataque, absorbes hasta $amount de Barrera del objetivo.';
    case BattlerAbilityId.limpiezaCache:
      return 'Activacion manual en combate. Elimina 1 turno de un buff enemigo aleatorio $amount veces.';
    case BattlerAbilityId.cortafuegosPortatil:
      return 'Pasiva. La primera $positiveAmount vez por combate que fueras a recibir un debuff, lo ignoras y ganas 2 de Barrera.';
    case BattlerAbilityId.marcaDeCaza:
      return 'Activacion manual en combate. Aplica $positiveAmount de Fragilidad al enemigo. Si el enemigo no tenia debuffs, haces un ataque con $positiveAmount de dano inmediatamente despues.';
    case BattlerAbilityId.cadenciaRapida:
      return 'Pasiva. El maximo cooldown que pueden tener tus habilidades manuales es $positiveAmount.';
    case BattlerAbilityId.extrabloqueo:
      return 'Activacion manual en combate. El siguiente dano que recibas se reduce en $amount.';
    case BattlerAbilityId.triageAutomatico:
      return 'Pasiva. Al inicio de tu turno, si estas por debajo de la mitad de vida, te curas $positiveAmount HP. Si tienes algun debuff, reduces 1 turno de un debuff purgable por cada punto que fueras a curarte y conviertes el restante en vida.';
    case BattlerAbilityId.opresionTactica:
      return 'Pasiva. Cada vez que un buff enemigo o un debuff propio se elimina o expira, ganas $positiveAmount de Barrera. Maximo una vez por turno.';
    case BattlerAbilityId.sobrecargaRegulada:
      return 'Activacion manual en combate. Ganas $positiveAmount de Potencia, pero tu siguiente habilidad manual gana +1 turno de cooldown.';
    case BattlerAbilityId.copiaDeSeguridad:
      return 'Pasiva. Una vez por combate, si un ataque te dejaria a 0 HP, sobrevives con 1 HP y ganas $positiveAmount de Barrera.';
    case BattlerAbilityId.puntoCiego:
      return 'Activacion manual en combate. Durante $positiveAmount turnos, el enemigo falla sus ataques contra ti, evitando su dano y los efectos aplicados sobre ti.';
    case BattlerAbilityId.provocacionFrontal:
      return 'Activacion manual en combate. Ganas $positiveAmount Desafio.';
    case BattlerAbilityId.cargaTemeraria:
      return 'Activacion manual en combate. Ganas $positiveAmount Desafio y haces un ataque inmediato. Si el enemigo sobrevive, el contraataque de Desafio hace +3 dano.';
    case BattlerAbilityId.mandatoColiseo:
      return 'Pasiva. Al principio del combate ganas $positiveAmount Desafio. La primera vez por turno que consumes Desafio, no provoca contraataque.';
    case BattlerAbilityId.hemostasiaAgresiva:
      return 'Pasiva. Al golpear a un objetivo con debuff, te curas $amount HP.';
    case BattlerAbilityId.mallaRebote:
      return 'Pasiva. El primer ataque que recibes cada turno devuelve $amount de daño al atacante.';
    case BattlerAbilityId.inyeccionCorrosiva:
      return 'Activacion manual en combate. Aplica Intoxicacion ($positiveAmount) al objetivo, o aumenta su Intoxicacion en $positiveAmount si ya la tenia.';
    case BattlerAbilityId.escanerRuptura:
      return 'Pasiva. Tus ataques infligen +$amount daño si el objetivo tiene al menos un buff.';
    case BattlerAbilityId.reenrutadoInverso:
      return 'Activacion manual en combate. Transfiere 1 turno de un debuff aleatorio tuyo al enemigo $positiveAmount veces.';
    case BattlerAbilityId.jaulaSenal:
      return 'Activacion manual en combate. Una habilidad manual del enemigo se desactiva y gana +$amount turnos de cooldown.';
    case BattlerAbilityId.nucleoParasitario:
      return 'Pasiva. En el primer ataque durante tu turno, drenas $amount de vida al objetivo.';
    case BattlerAbilityId.espejoDolor:
      return 'Activacion manual en combate. El siguiente ataque recibido reduce su daño en $amount y refleja ${amount * 2} de daño directo.';
    case BattlerAbilityId.protocoloUsurpacion:
      return 'Activacion manual en combate. Robas hasta $amount buffs activos del enemigo y te los aplicas.';
    case BattlerAbilityId.refactorizacionTimeline:
      return 'Activacion manual en ruta. Pagas ${max(0, amount)} creditos y cambias todos los nodos visibles por otros distintos.';
    case BattlerAbilityId.monopolio:
      return 'Pasiva. Si todos tus objetos son de Mercante o generales, te curas $amount HP al principio de cada turno.';
    case BattlerAbilityId.compraDeOportunidad:
      return 'Activacion manual en combate. Pagas $amount creditos. Tu siguiente ataque inflige +$amount daño y recuperas Barrera igual al numero de arquetipos distintos entre tus objetos equipados.';
    case BattlerAbilityId.diversificacionHostil:
      return 'Pasiva. Tus ataques infligen +$amount daño por cada arquetipo no mercante distinto entre tus objetos equipados.';
    case BattlerAbilityId.convencionRepentina:
      return 'Activacion manual en ruta. Si no es al atardecer o al amanecer, cambia todos los nodos actuales por diferentes tiendas de tiers azul, morada y amarilla.';
    case BattlerAbilityId.furiaHematica:
      return 'Pasiva. El primer ataque de tu turno inflige +$amount daño por cada 15% de vida maxima que te falte, hasta 90%.';
    case BattlerAbilityId.mordidaDeAcero:
      return 'Activacion manual en combate. Tu siguiente ataque inflige +$amount daño adicional y te cura la mitad del daño infligido por esta habilidad.';
    case BattlerAbilityId.noHayRetirada:
      return 'Pasiva. La primera vez que recibes daño cada turno, ganas $positiveAmount de Potencia. Si ya tenias Potencia, tambien ganas $positiveAmount de Calentando.';
    case BattlerAbilityId.pulsoArmonico:
      return 'Activacion manual en combate. Ganas $positiveAmount de Barrera y $positiveAmount de Resonancia.';
    case BattlerAbilityId.masaCritica:
      return 'Pasiva. Tus efectos de Resonancia infligen +$positiveAmount dano si tu Barrera es mayor que la mitad de tu vida maxima.';
    case BattlerAbilityId.descargaSismica:
      return 'Activacion manual en combate. Consume hasta $positiveAmount de tu Barrera e inflige esa cantidad como dano directo de Resonancia. Si consumes toda tu Barrera, aplica Conmocion ${max(1, positiveAmount ~/ 2)}.';
  }
}
