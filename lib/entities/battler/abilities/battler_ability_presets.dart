part of '../battler_ability.dart';

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
  tags: _vidaBarreraAbilityTags,
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

/// Preset pasivo economico que entrega creditos al comienzo de cada hora.
const cashflowAbility = BattlerAbility(
  id: BattlerAbilityId.cashflow,
  rarity: RarityTier.green,
  tags: _economiaAbilityTags,
  name: 'Flujo de Caja',
  description:
      'Pasiva. Al comienzo de cada hora, ganas creditos iguales a tu income actual.',
  icon: Icons.payments_rounded,
  value: 1,
  effect: CashflowAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo de barrera minima al inicio de cada turno propio.
const pulsoRepLAbility = BattlerAbility(
  id: BattlerAbilityId.pulsoRepL,
  rarity: RarityTier.green,
  tags: _buffBarreraAbilityTags,
  name: 'Pulso REP-L',
  description:
      'Pasiva. Al inicio de tu turno, si tienes menos barrera que value, subes tu barrera hasta value.',
  icon: Icons.shield_rounded,
  value: 4,
  upgradeValue: 2,
  effect: PulsoRepLAbilityEffect(),
  isImplemented: true,
);

/// Preset manual de combate que roba barrera tras el siguiente ataque.
const sustraccionAbility = BattlerAbility(
  id: BattlerAbilityId.sustraccion,
  tags: _ataqueBarreraAbilityTags,
  name: 'Sustraccion',
  description:
      'Activacion manual en combate. Tras el siguiente ataque, absorbes hasta value de barrera del objetivo.',
  icon: Icons.swap_horiz_rounded,
  cooldownTurns: 3,
  value: 4,
  upgradeValue: 2,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: SustraccionAbilityEffect(),
  isImplemented: true,
);

/// Preset manual de combate que elimina turnos de buffs enemigos.
const limpiezaCacheAbility = BattlerAbility(
  id: BattlerAbilityId.limpiezaCache,
  tags: _debuffAbilityTags,
  name: 'Limpieza de Cache',
  description:
      'Activacion manual en combate. Elimina 1 turno de un buff enemigo aleatorio, value veces.',
  icon: Icons.cleaning_services_rounded,
  cooldownTurns: 2,
  value: 1,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: LimpiezaCacheAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo amarillo que convierte debuffs enemigos en curacion.
const hemostasiaAgresivaAbility = BattlerAbility(
  id: BattlerAbilityId.hemostasiaAgresiva,
  rarity: RarityTier.yellow,
  tags: _vidaAtaqueAbilityTags,
  name: 'Hemostasia Agresiva',
  description:
      'Pasiva. Al golpear a un objetivo con debuff, te curas value de vida.',
  icon: Icons.favorite_rounded,
  value: 5,
  upgradeValue: 0,
  effect: HemostasiaAgresivaAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo morado que refleja dano del primer impacto de cada turno.
const mallaReboteAbility = BattlerAbility(
  id: BattlerAbilityId.mallaRebote,
  rarity: RarityTier.purple,
  tags: _buffBarreraAbilityTags,
  name: 'Malla de Rebote',
  description:
      'Pasiva. El primer ataque que recibes cada turno devuelve value de dano al atacante.',
  icon: Icons.sync_alt_rounded,
  value: 4,
  upgradeValue: 4,
  effect: MallaReboteAbilityEffect(),
  isImplemented: true,
);

/// Preset manual de combate centrado en Intoxicacion acumulativa.
const inyeccionCorrosivaAbility = BattlerAbility(
  id: BattlerAbilityId.inyeccionCorrosiva,
  rarity: RarityTier.green,
  tags: _intoxicacionDebuffAbilityTags,
  name: 'Inyeccion Corrosiva',
  description:
      'Activacion manual en combate. Aplica Intoxicacion con value de potencia al objetivo, o aumenta en value si el objetivo ya tiene Intoxicacion.',
  icon: Icons.science_rounded,
  cooldownTurns: 2,
  value: 2,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: InyeccionCorrosivaAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo que explota buffs activos del enemigo para infligir dano extra.
const escanerRupturaAbility = BattlerAbility(
  id: BattlerAbilityId.escanerRuptura,
  rarity: RarityTier.blue,
  tags: _buffAtaqueAbilityTags,
  name: 'Escaner de Ruptura',
  description:
      'Pasiva. Tus ataques infligen +value dano si el objetivo tiene al menos un buff.',
  icon: Icons.radar_rounded,
  value: 3,
  upgradeValue: 2,
  effect: EscanerRupturaAbilityEffect(),
  isImplemented: true,
);

/// Preset manual que traslada debuffs propios al rival.
const reenrutadoInversoAbility = BattlerAbility(
  id: BattlerAbilityId.reenrutadoInverso,
  rarity: RarityTier.blue,
  tags: _debuffAbilityTags,
  name: 'Reenrutado Inverso',
  description:
      'Activacion manual en combate. Transfiere 1 turno de un debuff aleatorio tuyo al enemigo, value veces.',
  icon: Icons.alt_route_rounded,
  cooldownTurns: 3,
  value: 2,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: ReenrutadoInversoAbilityEffect(),
  isImplemented: true,
);

/// Preset manual de control que fuerza cooldown sobre habilidades manuales rivales.
const jaulaSenalAbility = BattlerAbility(
  id: BattlerAbilityId.jaulaSenal,
  rarity: RarityTier.blue,
  tags: _debuffAbilityTags,
  name: 'Jaula de Senal',
  description:
      'Activacion manual en combate. Una habilidad manual del enemigo se desactiva y gana +value turnos de cooldown.',
  icon: Icons.wifi_lock_rounded,
  cooldownTurns: 3,
  value: 1,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: JaulaSenalAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo que drena vida en el primer ataque de cada turno propio.
const nucleoParasitarioAbility = BattlerAbility(
  id: BattlerAbilityId.nucleoParasitario,
  rarity: RarityTier.purple,
  tags: _vidaAtaqueAbilityTags,
  name: 'Nucleo Parasitario',
  description:
      'Pasiva. En el primer ataque durante tu turno, drenas value de vida al objetivo.',
  icon: Icons.bloodtype_rounded,
  value: 4,
  upgradeValue: 1,
  effect: NucleoParasitarioAbilityEffect(),
  isImplemented: true,
);

/// Preset manual morado defensivo con contraataque reflejado.
const espejoDolorAbility = BattlerAbility(
  id: BattlerAbilityId.espejoDolor,
  rarity: RarityTier.purple,
  tags: _vidaBarreraAbilityTags,
  name: 'Espejo de Dolor',
  description:
      'Activacion manual en combate. El siguiente ataque recibido reduce su dano en value y refleja el dano prevenido + value.',
  icon: Icons.health_and_safety_rounded,
  cooldownTurns: 3,
  value: 4,
  upgradeValue: 2,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: EspejoDolorAbilityEffect(),
  isImplemented: true,
);

/// Preset manual verde que roba buffs activos del rival.
const protocoloUsurpacionAbility = BattlerAbility(
  id: BattlerAbilityId.protocoloUsurpacion,
  rarity: RarityTier.green,
  tags: _buffDebuffAbilityTags,
  name: 'Protocolo de Usurpacion',
  description:
      'Activacion manual en combate. Robas hasta value buffs activos del enemigo y te los aplicas.',
  icon: Icons.call_split_rounded,
  cooldownTurns: 4,
  value: 2,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: ProtocoloUsurpacionAbilityEffect(),
  isImplemented: true,
);

/// Preset manual de ruta que paga creditos para rerolear nodos visibles.
const refactorizacionTimelineAbility = BattlerAbility(
  id: BattlerAbilityId.refactorizacionTimeline,
  rarity: RarityTier.green,
  tags: _economiaAbilityTags,
  name: 'Refactorizacion de Timeline',
  description:
      'Activacion manual en ruta. A cambio de value creditos, cambias todos los nodos visibles por otros distintos.',
  icon: Icons.timeline_rounded,
  cooldownTurns: 4,
  value: 20,
  upgradeValue: -3,
  manualActivationContext: BattlerAbilityActivationContext.pathSelection,
  effect: RefactorizacionTimelineAbilityEffect(),
  isImplemented: true,
);

/// Pool canonica de habilidades que pueden usarse como recompensa o mutacion.
const abilityPresets = <BattlerAbility>[
  criticalScannerAbility,
  weaknessHunterAbility,
  ghostMeshAbility,
  cruelCatalysisAbility,
  venousOverloadAbility,
  hardResetAbility,
  cashflowAbility,
  pulsoRepLAbility,
  sustraccionAbility,
  limpiezaCacheAbility,
  hemostasiaAgresivaAbility,
  mallaReboteAbility,
  inyeccionCorrosivaAbility,
  escanerRupturaAbility,
  reenrutadoInversoAbility,
  jaulaSenalAbility,
  nucleoParasitarioAbility,
  espejoDolorAbility,
  protocoloUsurpacionAbility,
  refactorizacionTimelineAbility,
];
