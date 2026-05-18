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

/// Preset pasivo economico que entrega creditos al comienzo de cada hora.
const cashflowAbility = BattlerAbility(
  id: BattlerAbilityId.cashflow,
  archetypeAffinities: _mercanteAbilityAffinities,
  rarity: RarityTier.yellow,
  tags: _economiaAbilityTags,
  name: 'Flujo de Caja',
  description: 'Pasiva. Al comienzo de cada hora, ganas 2 creditos.',
  icon: Icons.payments_rounded,
  value: 2,
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
  description: 'Pasiva. Al final de tu turno, ganas Barrera.',
  icon: Icons.shield_rounded,
  value: 3,
  upgradeValue: 1,
  effect: PulsoRepLAbilityEffect(),
  isImplemented: true,
);

/// Pasiva que vuelve mas peligrosa la Resonancia cuando sobra Barrera.
const masaCriticaAbility = BattlerAbility(
  id: BattlerAbilityId.masaCritica,
  archetypeAffinities: _inamovibleAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _resonanciaAtaqueBarreraAbilityTags,
  name: 'Masa Critica',
  description:
      'Pasiva. Tus efectos de Resonancia infligen dano adicional si tu Barrera supera la mitad de tu vida maxima.',
  icon: Icons.hub_rounded,
  value: 2,
  upgradeValue: 1,
  effect: MasaCriticaAbilityEffect(),
  isImplemented: true,
);

/// Pasiva general que bloquea debuffs entrantes y los convierte en Barrera.
const cortafuegosPortatilAbility = BattlerAbility(
  id: BattlerAbilityId.cortafuegosPortatil,
  rarity: RarityTier.gray,
  tags: _debuffBarreraAbilityTags,
  name: 'Cortafuegos Portatil',
  description:
      'Pasiva. Ignora los primeros debuffs recibidos en combate y gana Barrera.',
  icon: Icons.security_rounded,
  value: 1,
  upgradeValue: 1,
  effect: CortafuegosPortatilAbilityEffect(),
  isImplemented: true,
);

/// Pasiva general de emergencia que convierte curacion en purga gradual.
const triageAutomaticoAbility = BattlerAbility(
  id: BattlerAbilityId.triageAutomatico,
  rarity: RarityTier.blue,
  tags: _vidaDebuffAbilityTags,
  name: 'Triage Automatico',
  description:
      'Pasiva. Con poca vida, cura o reduce debuffs propios antes de curar.',
  icon: Icons.medical_services_rounded,
  value: 3,
  upgradeValue: 2,
  effect: TriageAutomaticoAbilityEffect(),
  isImplemented: true,
);

/// Pasiva general que gana Barrera cuando desaparecen buffs enemigos o debuffs propios.
const opresionTacticaAbility = BattlerAbility(
  id: BattlerAbilityId.opresionTactica,
  rarity: RarityTier.blue,
  tags: _buffDebuffBarreraAbilityTags,
  name: 'Opresion Tactica',
  description:
      'Pasiva. Si desaparece un buff enemigo o un debuff propio, ganas Barrera una vez por turno.',
  icon: Icons.control_camera_rounded,
  value: 4,
  upgradeValue: 2,
  isImplemented: true,
);

/// Pasiva general que salva de un ataque letal una vez por combate.
const copiaDeSeguridadAbility = BattlerAbility(
  id: BattlerAbilityId.copiaDeSeguridad,
  rarity: RarityTier.purple,
  tags: _vidaBarreraAbilityTags,
  name: 'Copia de Seguridad',
  description:
      'Pasiva. Una vez por combate, sobrevives a un ataque letal y ganas Barrera.',
  icon: Icons.backup_rounded,
  value: 8,
  upgradeValue: 4,
  effect: CopiaDeSeguridadAbilityEffect(),
  isImplemented: true,
);

/// Pasiva imparable que abre combate con Desafio y controla su riesgo.
const mandatoColiseoAbility = BattlerAbility(
  id: BattlerAbilityId.mandatoColiseo,
  archetypeAffinities: _imparableAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _desafioAtaqueAbilityTags,
  name: 'Mandato de Coliseo',
  description:
      'Pasiva. La primera vez por turno que un Desafio se consume, no provoca contraataque. Ganas Desafio al principio del combate.',
  icon: Icons.stadium_rounded,
  value: 2,
  upgradeValue: 2,
  effect: MandatoColiseoAbilityEffect(),
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

/// Pasiva reactiva que transforma el primer daño recibido en escalada ofensiva.
const noHayRetiradaAbility = BattlerAbility(
  id: BattlerAbilityId.noHayRetirada,
  archetypeAffinities: _imparableAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _buffAtaqueAbilityTags,
  name: 'No Hay Retirada',
  description:
      'Pasiva. La primera vez que recibes daño en combate, ganas Potencia. Si ya tenias Potencia, tambien ganas Calentando.',
  icon: Icons.vertical_align_top_rounded,
  value: 1,
  upgradeValue: 1,
  effect: NoHayRetiradaAbilityEffect(),
  isImplemented: true,
);

/// Pasiva de Patron que premia geometria ortogonal defensiva.
const geometriaLimpiaAbility = BattlerAbility(
  id: BattlerAbilityId.geometriaLimpia,
  archetypeAffinities: _inamovibleAbilityAffinities,
  rarity: RarityTier.green,
  tags: _resonanciaAtaqueBarreraAbilityTags,
  name: 'Geometria Limpia',
  description:
      'Pasiva de Patron. Si el patron solo tiene angulos rectos, ganas Barrera y Resonancia.',
  icon: Icons.grid_4x4_rounded,
  value: 2,
  upgradeValue: 1,
  effect: GeometriaLimpiaAbilityEffect(),
  isImplemented: true,
);

/// Pasiva de Patron que recompensa trazos sin angulos agudos ni obtusos.
const pulsoIsometricoAbility = BattlerAbility(
  id: BattlerAbilityId.pulsoIsometrico,
  archetypeAffinities: _inamovibleAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _vidaBarreraAbilityTags,
  name: 'Pulso Isometrico',
  description:
      'Pasiva de Patron. Si el patron no tiene angulos agudos ni obtusos, recuperas HP y ganas Barrera.',
  icon: Icons.crop_square_rounded,
  value: 3,
  upgradeValue: 1,
  effect: PulsoIsometricoAbilityEffect(),
  isImplemented: true,
);

/// Pasiva de Patron que convierte un unico giro agresivo en dano directo.
const corteTangencialAbility = BattlerAbility(
  id: BattlerAbilityId.corteTangencial,
  archetypeAffinities: [
    BattlerAbilityArchetypeAffinity.veloz,
    BattlerAbilityArchetypeAffinity.imparable,
  ],
  rarity: RarityTier.purple,
  tags: _ataqueAbilityTags,
  name: 'Corte Tangencial',
  description:
      'Pasiva de Patron. Si el patron tiene exactamente un angulo agudo, inflige dano directo segun este valor y el ATK del patron.',
  icon: Icons.swipe_rounded,
  value: 6,
  upgradeValue: 4,
  effect: CorteTangencialAbilityEffect(),
  isImplemented: true,
);

/// Pasiva de Patron que duplica el peso defensivo de figuras sin angulos agudos.
const arquitecturaPesadaAbility = BattlerAbility(
  id: BattlerAbilityId.arquitecturaPesada,
  archetypeAffinities: _inamovibleAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _resonanciaAtaqueBarreraAbilityTags,
  name: 'Arquitectura Pesada',
  description:
      'Pasiva de Patron. Si el patron no tiene angulos agudos, repite su bonus de Barrera y gana Resonancia.',
  icon: Icons.foundation_rounded,
  value: 4,
  upgradeValue: 2,
  effect: ArquitecturaPesadaAbilityEffect(),
  isImplemented: true,
);

/// Pasiva de Patron que premia activar equipamiento de otros arquetipos.
const rutaContrabandoAbility = BattlerAbility(
  id: BattlerAbilityId.rutaContrabando,
  archetypeAffinities: _mercanteAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _economiaAbilityTags,
  name: 'Ruta de Contrabando',
  description:
      'Pasiva de Patron. Si activas items de otro arquetipo, ganas creditos, Potencia y Barrera.',
  icon: Icons.alt_route_rounded,
  value: 2,
  upgradeValue: 1,
  effect: RutaContrabandoAbilityEffect(),
  isImplemented: true,
);

/// Pasiva de Patron que devuelve parte del bonus dominante en figuras simetricas.
const ecoSimetriaAbility = BattlerAbility(
  id: BattlerAbilityId.ecoSimetria,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _cicloAtaqueBarreraBuffAbilityTags,
  name: 'Eco de Simetria',
  description:
      'Pasiva de Patron. Si el patron tiene simetria, repite el bonus dominante con una reduccion que mejora al subir de rareza.',
  icon: Icons.flip_rounded,
  value: 3,
  upgradeValue: -2,
  effect: EcoSimetriaAbilityEffect(),
  isImplemented: true,
);

/// Pasiva de Patron que convierte una figura perfecta en dano de Resonancia.
const patronPerfectoAbility = BattlerAbility(
  id: BattlerAbilityId.patronPerfecto,
  archetypeAffinities: _inamovibleAbilityAffinities,
  rarity: RarityTier.yellow,
  tags: _resonanciaAtaqueBarreraAbilityTags,
  name: 'Patron perfecto',
  description:
      'Pasiva de Patron. Si el patron es cerrado, simetrico, sin puntos repetidos y con el mismo ATK que Barrera, inflige dano igual a toda tu Resonancia.',
  icon: Icons.auto_awesome_rounded,
  value: 5,
  upgradeValue: 1,
  effect: PatronPerfectoAbilityEffect(),
  isImplemented: true,
);

/// Pool canonica de aumentos pasivos que pueden usarse como recompensa o mutacion.
const abilityPresets = <BattlerAbility>[
  weaknessHunterAbility,
  ghostMeshAbility,
  ritmoCircadianoAbility,
  turnoDeNocheAbility,
  cashflowAbility,
  pulsoRepLAbility,
  masaCriticaAbility,
  cortafuegosPortatilAbility,
  triageAutomaticoAbility,
  opresionTacticaAbility,
  copiaDeSeguridadAbility,
  mandatoColiseoAbility,
  hemostasiaAgresivaAbility,
  mallaReboteAbility,
  escanerRupturaAbility,
  nucleoParasitarioAbility,
  monopolioAbility,
  diversificacionHostilAbility,
  furiaHematicaAbility,
  noHayRetiradaAbility,
  geometriaLimpiaAbility,
  pulsoIsometricoAbility,
  corteTangencialAbility,
  arquitecturaPesadaAbility,
  rutaContrabandoAbility,
  ecoSimetriaAbility,
  patronPerfectoAbility,
];

/// Indice canonico de presets para resolver ids sin duplicar switches.
final abilityPresetRegistry =
    Map<BattlerAbilityId, BattlerAbility>.unmodifiable({
  for (final ability in abilityPresets) ability.id: ability,
});
