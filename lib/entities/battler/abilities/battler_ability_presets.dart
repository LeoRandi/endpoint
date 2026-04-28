part of '../battler_ability.dart';

const _velozAbilityAffinities = <BattlerAbilityArchetypeAffinity>[
  BattlerAbilityArchetypeAffinity.veloz,
];
const _inamovibleAbilityAffinities = <BattlerAbilityArchetypeAffinity>[
  BattlerAbilityArchetypeAffinity.inamovible,
];
const _imparableAbilityAffinities = <BattlerAbilityArchetypeAffinity>[
  BattlerAbilityArchetypeAffinity.imparable,
];
const _mercanteAbilityAffinities = <BattlerAbilityArchetypeAffinity>[
  BattlerAbilityArchetypeAffinity.mercante,
];

/// Preset que prepara un siguiente ataque potenciado y luego entra en cooldown.
const criticalScannerAbility = BattlerAbility(
  id: BattlerAbilityId.criticalScanner,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _ataqueAbilityTags,
  name: 'Escaner critico',
  description:
      'Activacion manual en combate. El siguiente ataque inflige daño adicional.',
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
  archetypeAffinities: _velozAbilityAffinities,
  tags: _ataqueDebuffAbilityTags,
  name: 'Caza de debilidades',
  description:
      'Pasiva. Tus ataques infligen daño adicional si el objetivo ya tiene al menos un debuff.',
  icon: Icons.track_changes_rounded,
  value: 2,
  upgradeValue: 2,
  effect: WeaknessHunterAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo defensivo que protege mientras la vida siga llena.
const ghostMeshAbility = BattlerAbility(
  id: BattlerAbilityId.ghostMesh,
  archetypeAffinities: _inamovibleAbilityAffinities,
  tags: _vidaBarreraAbilityTags,
  name: 'Malla Fantasma',
  description:
      'Pasiva. Si tu vida esta al maximo, el daño recibido por ataques se reduce a la mitad, redondeando hacia arriba.',
  icon: Icons.security_rounded,
  value: 2,
  effect: GhostMeshAbilityEffect(),
  isImplemented: true,
);

/// Pasiva de Ciclo que cura de dia y carga Potencia de noche.
const ritmoCircadianoAbility = BattlerAbility(
  id: BattlerAbilityId.ritmoCircadiano,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.green,
  tags: _cicloVidaAtaqueBuffAbilityTags,
  name: 'Ritmo Circadiano',
  description:
      'Pasiva. Al inicio de tu turno: de dia te curas y de noche ganas Potencia.',
  icon: Icons.av_timer_rounded,
  value: 2,
  upgradeValue: 1,
  effect: RitmoCircadianoAbilityEffect(),
  isImplemented: true,
);

/// Manual de combate que cambia entre refuerzo defensivo y ofensivo.
const cambioDeGuardiaAbility = BattlerAbility(
  id: BattlerAbilityId.cambioDeGuardia,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.green,
  tags: _cicloAtaqueBarreraBuffAbilityTags,
  name: 'Cambio de Guardia',
  description:
      'Activacion manual en combate. De dia ganas Barrera; de noche ganas Potencia.',
  icon: Icons.change_circle_rounded,
  cooldownTurns: 3,
  value: 2,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: CambioDeGuardiaAbilityEffect(),
  isImplemented: true,
);

/// Manual de combate que aplica control distinto segun el Ciclo.
const toqueDeQuedaAbility = BattlerAbility(
  id: BattlerAbilityId.toqueDeQueda,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _cicloAtaqueBarreraDebuffAbilityTags,
  name: 'Toque de Queda',
  description:
      'Activacion manual en combate. De dia aplica Interferencia; de noche aplica Fragilidad.',
  icon: Icons.notifications_paused_rounded,
  cooldownTurns: 3,
  value: 2,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: ToqueDeQuedaAbilityEffect(),
  isImplemented: true,
);

/// Pasiva de Ciclo que protege de dia y remata de noche.
const turnoDeNocheAbility = BattlerAbility(
  id: BattlerAbilityId.turnoDeNoche,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _cicloAtaqueBarreraBuffAbilityTags,
  name: 'Turno de Noche',
  description:
      'Pasiva. De dia reduces daño recibido. De noche infliges daño adicional.',
  icon: Icons.bedtime_rounded,
  value: 2,
  upgradeValue: 1,
  effect: TurnoDeNocheAbilityEffect(),
  isImplemented: true,
);

/// Buff de ruta que fuerza la rama diurna en el siguiente combate.
const amanecerSinteticoAbility = BattlerAbility(
  id: BattlerAbilityId.amanecerSintetico,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.green,
  tags: _cicloBuffAbilityTags,
  name: 'Amanecer Sintetico',
  description:
      'Activacion manual en ruta. Hasta el final del proximo combate, tus efectos de Ciclo cuentan siempre como dia.',
  icon: Icons.wb_sunny_rounded,
  cooldownTurns: 4,
  value: 1,
  manualActivationContext: BattlerAbilityActivationContext.pathSelection,
  effect: AmanecerSinteticoAbilityEffect(),
  isImplemented: true,
);

/// Buff de ruta que fuerza la rama nocturna en el siguiente combate.
const lunaArtificialAbility = BattlerAbility(
  id: BattlerAbilityId.lunaArtificial,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.green,
  tags: _cicloBuffAbilityTags,
  name: 'Luna Artificial',
  description:
      'Activacion manual en ruta. Hasta el final del proximo combate, tus efectos de Ciclo cuentan siempre como noche.',
  icon: Icons.dark_mode_rounded,
  cooldownTurns: 4,
  value: 1,
  manualActivationContext: BattlerAbilityActivationContext.pathSelection,
  effect: LunaArtificialAbilityEffect(),
  isImplemented: true,
);

/// Manual de combate que abre un Eclipse completo durante pocos turnos.
const eclipseManualAbility = BattlerAbility(
  id: BattlerAbilityId.eclipseManual,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.yellow,
  tags: _cicloBuffAbilityTags,
  name: 'Eclipse Manual',
  description:
      'Activacion manual en combate. Durante unos turnos, tus efectos de Ciclo cuentan como dia y noche a la vez.',
  icon: Icons.brightness_medium_rounded,
  cooldownTurns: 4,
  value: 1,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: EclipseManualAbilityEffect(),
  isImplemented: true,
);

/// Preset manual que duplica la siguiente desventaja recibida por el objetivo.
const cruelCatalysisAbility = BattlerAbility(
  id: BattlerAbilityId.cruelCatalysis,
  rarity: RarityTier.yellow,
  tags: _debuffAbilityTags,
  name: 'Catalisis Cruel',
  description:
      'Activacion manual en combate. Aplica al enemigo un debuff que multiplica la siguiente desventaja que reciba.',
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
  archetypeAffinities: _imparableAbilityAffinities,
  tags: _ataqueQuemaduraAbilityTags,
  name: 'Sobrecarga venosa',
  description:
      'Activacion manual en combate. El siguiente ataque inflige daño adicional, pero te aplica Quemadura.',
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
  archetypeAffinities: _inamovibleAbilityAffinities,
  tags: _vidaDebuffAbilityTags,
  name: 'Reinicio en seco',
  description:
      'Activacion manual en ruta. Elimina debuffs propios y luego te inflige daño segun tu vida maxima.',
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
  archetypeAffinities: _mercanteAbilityAffinities,
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
  archetypeAffinities: _inamovibleAbilityAffinities,
  rarity: RarityTier.green,
  tags: _buffBarreraAbilityTags,
  name: 'Pulso REP-L',
  description:
      'Pasiva. Al inicio de tu turno, si tienes poca barrera, subes tu barrera hasta el minimo de la habilidad.',
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
      'Activacion manual en combate. Tras el siguiente ataque, absorbes barrera del objetivo.',
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
      'Activacion manual en combate. Elimina turnos de buffs enemigos aleatorios.',
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
  archetypeAffinities: _imparableAbilityAffinities,
  rarity: RarityTier.yellow,
  tags: _vidaAtaqueAbilityTags,
  name: 'Hemostasia Agresiva',
  description: 'Pasiva. Al golpear a un objetivo con debuff, te curas vida.',
  icon: Icons.favorite_rounded,
  value: 5,
  upgradeValue: 0,
  effect: HemostasiaAgresivaAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo morado que refleja daño del primer impacto de cada turno.
const mallaReboteAbility = BattlerAbility(
  id: BattlerAbilityId.mallaRebote,
  archetypeAffinities: _inamovibleAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _buffBarreraAbilityTags,
  name: 'Malla de Rebote',
  description:
      'Pasiva. El primer ataque que recibes cada turno devuelve daño al atacante.',
  icon: Icons.sync_alt_rounded,
  value: 4,
  upgradeValue: 4,
  effect: MallaReboteAbilityEffect(),
  isImplemented: true,
);

/// Preset manual de combate centrado en Intoxicacion acumulativa.
const inyeccionCorrosivaAbility = BattlerAbility(
  id: BattlerAbilityId.inyeccionCorrosiva,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.green,
  tags: _intoxicacionDebuffAbilityTags,
  name: 'Inyeccion Corrosiva',
  description:
      'Activacion manual en combate. Aplica Intoxicacion al objetivo, o la aumenta si ya la tenia.',
  icon: Icons.science_rounded,
  cooldownTurns: 2,
  value: 2,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: InyeccionCorrosivaAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo que explota buffs activos del enemigo para infligir daño extra.
const escanerRupturaAbility = BattlerAbility(
  id: BattlerAbilityId.escanerRuptura,
  rarity: RarityTier.blue,
  tags: _buffAtaqueAbilityTags,
  name: 'Escaner de Ruptura',
  description:
      'Pasiva. Tus ataques infligen daño adicional si el objetivo tiene al menos un buff.',
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
      'Activacion manual en combate. Transfiere turnos de debuffs aleatorios tuyos al enemigo.',
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
      'Activacion manual en combate. Una habilidad manual del enemigo se desactiva y gana cooldown.',
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
  archetypeAffinities: _imparableAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _vidaAtaqueAbilityTags,
  name: 'Nucleo Parasitario',
  description:
      'Pasiva. En el primer ataque durante tu turno, drenas vida al objetivo.',
  icon: Icons.bloodtype_rounded,
  value: 4,
  upgradeValue: 1,
  effect: NucleoParasitarioAbilityEffect(),
  isImplemented: true,
);

/// Preset manual morado defensivo con contraataque reflejado.
const espejoDolorAbility = BattlerAbility(
  id: BattlerAbilityId.espejoDolor,
  archetypeAffinities: _inamovibleAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _vidaBarreraAbilityTags,
  name: 'Espejo de Dolor',
  description:
      'Activacion manual en combate. El siguiente ataque recibido reduce su daño y refleja daño directo.',
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
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.green,
  tags: _buffDebuffAbilityTags,
  name: 'Protocolo de Usurpacion',
  description:
      'Activacion manual en combate. Robas buffs activos del enemigo y te los aplicas.',
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
  archetypeAffinities: _mercanteAbilityAffinities,
  rarity: RarityTier.green,
  tags: _economiaAbilityTags,
  name: 'Refactorizacion de Timeline',
  description:
      'Activacion manual en ruta. Pagas creditos para cambiar todos los nodos visibles por otros distintos.',
  icon: Icons.timeline_rounded,
  cooldownTurns: 4,
  value: 20,
  upgradeValue: -3,
  manualActivationContext: BattlerAbilityActivationContext.pathSelection,
  effect: RefactorizacionTimelineAbilityEffect(),
  isImplemented: true,
);

/// Pasiva que recompensa mantener el inventario dentro del monopolio mercante.
const monopolioAbility = BattlerAbility(
  id: BattlerAbilityId.monopolio,
  archetypeAffinities: _mercanteAbilityAffinities,
  rarity: RarityTier.gray,
  tags: _vidaAbilityTags,
  name: 'Monopolio',
  description:
      'Pasiva. Si todos tus objetos son de Mercante o generales, te curas al principio de cada turno.',
  icon: Icons.storefront_rounded,
  value: 2,
  upgradeValue: 2,
  effect: MonopolioAbilityEffect(),
  isImplemented: true,
);

/// Manual de combate que paga creditos para preparar un golpe rentable.
const compraDeOportunidadAbility = BattlerAbility(
  id: BattlerAbilityId.compraDeOportunidad,
  archetypeAffinities: _mercanteAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _economiaAtaqueBarreraAbilityTags,
  name: 'Compra de Oportunidad',
  description:
      'Activacion manual en combate. Pagas creditos. Tu siguiente ataque inflige daño adicional y recuperas Barrera segun tus arquetipos equipados.',
  icon: Icons.price_check_rounded,
  cooldownTurns: 3,
  value: 3,
  upgradeValue: -1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: CompraDeOportunidadAbilityEffect(),
  isImplemented: true,
);

/// Pasiva que monetiza en daño la diversidad hostil del equipo.
const diversificacionHostilAbility = BattlerAbility(
  id: BattlerAbilityId.diversificacionHostil,
  archetypeAffinities: _mercanteAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _ataqueAbilityTags,
  name: 'Diversificacion Hostil',
  description:
      'Pasiva. Tus ataques infligen daño adicional por cada arquetipo no mercante distinto entre tus objetos equipados.',
  icon: Icons.hub_rounded,
  value: 2,
  upgradeValue: 1,
  effect: DiversificacionHostilAbilityEffect(),
  isImplemented: true,
);

/// Manual de ruta que transforma las opciones visibles en tiendas por tier.
const convencionRepentinaAbility = BattlerAbility(
  id: BattlerAbilityId.convencionRepentina,
  archetypeAffinities: _mercanteAbilityAffinities,
  rarity: RarityTier.yellow,
  tags: _economiaAbilityTags,
  name: 'Convencion repentina',
  description:
      'Activacion manual en ruta. Si no es al atardecer o al amanecer, cambia todos los nodos actuales por diferentes tiendas de tiers azul, morada y amarilla.',
  icon: Icons.groups_2_rounded,
  cooldownTurns: 4,
  value: 0,
  upgradeValue: 0,
  manualActivationContext: BattlerAbilityActivationContext.pathSelection,
  effect: ConvencionRepentinaAbilityEffect(),
  isImplemented: true,
);

/// Pasiva imparable que convierte la vida perdida en furia para el primer golpe.
const furiaHematicaAbility = BattlerAbility(
  id: BattlerAbilityId.furiaHematica,
  archetypeAffinities: _imparableAbilityAffinities,
  rarity: RarityTier.green,
  tags: _vidaAtaqueAbilityTags,
  name: 'Furia Hematica',
  description:
      'Pasiva. El primer ataque de tu turno inflige daño adicional por cada tramo de vida maxima que te falte.',
  icon: Icons.bloodtype_rounded,
  value: 2,
  upgradeValue: 1,
  effect: FuriaHematicaAbilityEffect(),
  isImplemented: true,
);

/// Manual de combate que muerde fuerte y devuelve parte del golpe como vida.
const mordidaDeAceroAbility = BattlerAbility(
  id: BattlerAbilityId.mordidaDeAcero,
  archetypeAffinities: _imparableAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _vidaAtaqueAbilityTags,
  name: 'Mordida de Acero',
  description:
      'Activacion manual en combate. Tu siguiente ataque inflige daño adicional y te cura la mitad del daño infligido por esta habilidad.',
  icon: Icons.hardware_rounded,
  cooldownTurns: 3,
  value: 4,
  upgradeValue: 2,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: MordidaDeAceroAbilityEffect(),
  isImplemented: true,
);

/// Pasiva reactiva que transforma el primer daño recibido en escalada ofensiva.
const noHayRetiradaAbility = BattlerAbility(
  id: BattlerAbilityId.noHayRetirada,
  archetypeAffinities: _imparableAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _buffAtaqueAbilityTags,
  name: 'No Hay Retirada',
  description:
      'Pasiva. La primera vez que recibes daño cada turno, ganas Potencia. Si ya tenias Potencia, tambien ganas Calentando.',
  icon: Icons.vertical_align_top_rounded,
  value: 1,
  upgradeValue: 1,
  effect: NoHayRetiradaAbilityEffect(),
  isImplemented: true,
);

/// Pool canonica de habilidades que pueden usarse como recompensa o mutacion.
const abilityPresets = <BattlerAbility>[
  criticalScannerAbility,
  weaknessHunterAbility,
  ghostMeshAbility,
  ritmoCircadianoAbility,
  cambioDeGuardiaAbility,
  toqueDeQuedaAbility,
  turnoDeNocheAbility,
  amanecerSinteticoAbility,
  lunaArtificialAbility,
  eclipseManualAbility,
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
  monopolioAbility,
  compraDeOportunidadAbility,
  diversificacionHostilAbility,
  convencionRepentinaAbility,
  furiaHematicaAbility,
  mordidaDeAceroAbility,
  noHayRetiradaAbility,
];

/// Indice canonico de presets para resolver ids sin duplicar switches.
final abilityPresetRegistry =
    Map<BattlerAbilityId, BattlerAbility>.unmodifiable({
  for (final ability in abilityPresets) ability.id: ability,
});
