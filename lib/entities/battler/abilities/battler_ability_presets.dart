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
  value: 1,
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
      'Pasiva. Tus efectos de Resonancia infligen daño adicional si tu Barrera supera la mitad de tu vida maxima.',
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
  value: 3,
  upgradeValue: 1,
  effect: PulsoIsometricoAbilityEffect(),
  isImplemented: true,
);

/// Pasiva de Patron que convierte un unico giro agresivo en daño directo.
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
      'Pasiva de Patron. Si el patron tiene exactamente un angulo agudo, inflige daño directo segun este valor y el ATK del patron.',
  value: 6,
  upgradeValue: 4,
  effect: CorteTangencialAbilityEffect(),
  isImplemented: true,
);

/// Pasiva general que convierte giros agudos en presion ofensiva.
const cortesAgudosAbility = BattlerAbility(
  id: BattlerAbilityId.cortesAgudos,
  rarity: RarityTier.green,
  tags: _ataqueAbilityTags,
  name: 'Cortes Agudos',
  description:
      'Pasiva de Patron. Por cada angulo agudo del Patron, ganas Potencia antes del ataque.',
  value: 1,
  upgradeValue: 1,
  effect: CortesAgudosAbilityEffect(),
  isImplemented: true,
);

/// Pasiva general que convierte giros rectos en defensa.
const rotoresDefensivosAbility = BattlerAbility(
  id: BattlerAbilityId.rotoresDefensivos,
  rarity: RarityTier.green,
  tags: _buffBarreraAbilityTags,
  name: 'Rotores Defensivos',
  description:
      'Pasiva de Patron. Por cada angulo de 90 grados del Patron, recuperas Barrera.',
  value: 1,
  upgradeValue: 1,
  effect: RotoresDefensivosAbilityEffect(),
  isImplemented: true,
);

/// Pasiva general que equilibra patrones cargados hacia una sola stat.
const polarizacionAbility = BattlerAbility(
  id: BattlerAbilityId.polarizacion,
  rarity: RarityTier.purple,
  tags: _ataqueBarreraAbilityTags,
  name: 'Polarizacion',
  description:
      'Pasiva de Patron. El menor total entre ATK y Barrera del Patron polariza parte del mayor hacia el menor.',
  value: 1,
  upgradeValue: 1,
  effect: PolarizacionAbilityEffect(),
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
  value: 1,
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
  value: 3,
  upgradeValue: -2,
  effect: EcoSimetriaAbilityEffect(),
  isImplemented: true,
);

/// Pasiva de Patron que convierte una figura perfecta en daño de Resonancia.
const patronPerfectoAbility = BattlerAbility(
  id: BattlerAbilityId.patronPerfecto,
  archetypeAffinities: _inamovibleAbilityAffinities,
  rarity: RarityTier.yellow,
  tags: _resonanciaAtaqueBarreraAbilityTags,
  name: 'Patron perfecto',
  description:
      'Pasiva de Patron. Si el patron es cerrado, simetrico, sin puntos repetidos y con el mismo ATK que Barrera, inflige daño igual a toda tu Resonancia.',
  value: 5,
  upgradeValue: 1,
  effect: PatronPerfectoAbilityEffect(),
  isImplemented: true,
);

/// Pasiva imparable que convierte Calentando entrante en sustain.
const encendidoBrutalAbility = BattlerAbility(
  id: BattlerAbilityId.encendidoBrutal,
  archetypeAffinities: _imparableAbilityAffinities,
  rarity: RarityTier.green,
  tags: _cicloVidaAtaqueBuffAbilityTags,
  name: 'Encendido Brutal',
  description:
      'Pasiva. Cuando ganas Calentando, recuperas una fraccion de ese valor como vida.',
  value: 4,
  upgradeValue: -1,
  effect: EncendidoBrutalAbilityEffect(),
  isImplemented: true,
);

/// Pasiva imparable que sobrecarga el primer item usado en Patron.
const combustionDirigidaAbility = BattlerAbility(
  id: BattlerAbilityId.combustionDirigida,
  archetypeAffinities: _imparableAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _buffAtaqueAbilityTags,
  name: 'Combustion Dirigida',
  description:
      'Pasiva de Patron. La primera vez por combate que usas un item, ganas Calentando. Si el item empuja ATK, ganas el doble.',
  value: 4,
  upgradeValue: 1,
  effect: CombustionDirigidaAbilityEffect(),
  isImplemented: true,
);

/// Pasiva imparable que convierte sobrecalentamiento en Desafio.
const puntoIgnicionAbility = BattlerAbility(
  id: BattlerAbilityId.puntoIgnicion,
  archetypeAffinities: _imparableAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _desafioAtaqueAbilityTags,
  name: 'Punto de Ignicion',
  description:
      'Pasiva de Patron. Si usas 3 o mas items, ganas Desafio segun tu Calentando y te quemas.',
  value: 8,
  upgradeValue: -4,
  effect: PuntoIgnicionAbilityEffect(),
  isImplemented: true,
);

/// Pasiva imparable que convierte heridas recientes en Desafio.
const deudaSangreAbility = BattlerAbility(
  id: BattlerAbilityId.deudaSangre,
  archetypeAffinities: _imparableAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _desafioAtaqueAbilityTags,
  name: 'Deuda de Sangre',
  description:
      'Pasiva. La primera vez cada turno que pierdes HP, ganas Desafio segun tu HP faltante.',
  value: 4,
  upgradeValue: 1,
  effect: DeudaSangreAbilityEffect(),
  isImplemented: true,
);

/// Pasiva mercante que paga el primer reuso del combate.
const reventaCircularAbility = BattlerAbility(
  id: BattlerAbilityId.reventaCircular,
  archetypeAffinities: _mercanteAbilityAffinities,
  rarity: RarityTier.green,
  tags: _economiaAbilityTags,
  name: 'Reventa Circular',
  description:
      'Pasiva de Patron. Una vez por combate, repetir un punto con item genera creditos.',
  value: 4,
  upgradeValue: 4,
  effect: ReventaCircularAbilityEffect(),
  isImplemented: true,
);

/// Pasiva mercante que fuerza valor extra en el primer item repetido.
const contratoReusoAbility = BattlerAbility(
  id: BattlerAbilityId.contratoReuso,
  archetypeAffinities: _mercanteAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _economiaAbilityTags,
  name: 'Contrato de Reuso',
  description:
      'Pasiva de Patron. El primer item repetido dispara Al usarse una vez extra con mas value.',
  value: 1,
  upgradeValue: 1,
  effect: ContratoReusoAbilityEffect(),
  isImplemented: true,
);

/// Pasiva mercante que convierte reusos en pagos ofensivos.
const mercadoRecursivoAbility = BattlerAbility(
  id: BattlerAbilityId.mercadoRecursivo,
  archetypeAffinities: _mercanteAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _economiaAtaqueAbilityTags,
  name: 'Mercado Recursivo',
  description:
      'Pasiva de Patron. Cada punto con item repetido consume creditos para infligir daño directo.',
  value: 5,
  upgradeValue: 5,
  effect: MercadoRecursivoAbilityEffect(),
  isImplemented: true,
);

/// Pasiva mercante que transforma pagos arriesgados de items en Potencia.
const comisionRiesgoAbility = BattlerAbility(
  id: BattlerAbilityId.comisionRiesgo,
  archetypeAffinities: _mercanteAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _economiaAtaqueAbilityTags,
  name: 'Comision de Riesgo',
  description:
      'Pasiva. Cuando un item te hace pagar creditos y quedas por debajo de 10C, ganas Potencia.',
  value: 1,
  upgradeValue: 1,
  effect: ComisionRiesgoAbilityEffect(),
  isImplemented: true,
);

/// Pasiva mercante amarilla que escala con una plantilla llena de Mercante.
const franquiciaTotalAbility = BattlerAbility(
  id: BattlerAbilityId.franquiciaTotal,
  archetypeAffinities: _mercanteAbilityAffinities,
  rarity: RarityTier.yellow,
  tags: _economiaAbilityTags,
  name: 'Franquicia Total',
  description:
      'Pasiva. Al principio del combate, ganas creditos por item Mercante equipado. Al llegar a 20C, mejoras temporalmente el item Mercante de menor rareza.',
  value: 2,
  upgradeValue: 1,
  effect: FranquiciaTotalAbilityEffect(),
  isImplemented: true,
);

/// Pasiva veloz que convierte el primer item usado en un debuff aleatorio.
const agujaToxicaAbility = BattlerAbility(
  id: BattlerAbilityId.agujaToxica,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.green,
  tags: _ataqueDebuffAbilityTags,
  name: 'Aguja Toxica',
  description:
      'Pasiva de Patron. El primer item usado aplica o aumenta un debuff aleatorio.',
  value: 1,
  upgradeValue: 1,
  effect: AgujaToxicaAbilityEffect(),
  isImplemented: true,
);

/// Pasiva veloz que recompensa patrones con muchos puntos de item.
const rastroInestableAbility = BattlerAbility(
  id: BattlerAbilityId.rastroInestable,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _ataqueDebuffAbilityTags,
  name: 'Rastro Inestable',
  description:
      'Pasiva de Patron. Patrones con suficientes items aplican Fragilidad, duplicada si ya habia otro debuff.',
  value: 2,
  upgradeValue: 1,
  effect: RastroInestableAbilityEffect(),
  isImplemented: true,
);

/// Pasiva veloz que remata cada debuff generado por Patron.
const cadenaNeurotoxicaAbility = BattlerAbility(
  id: BattlerAbilityId.cadenaNeurotoxica,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _ataqueDebuffAbilityTags,
  name: 'Cadena Neurotoxica',
  description:
      'Pasiva de Patron. Los debuffs aplicados por items usados o aumentos infligen daño directo extra.',
  value: 3,
  upgradeValue: 2,
  effect: CadenaNeurotoxicaAbilityEffect(),
  isImplemented: true,
);

/// Pasiva veloz que castiga cada perdida de Contagio enemigo con daño directo.
const armaBiologicaAbility = BattlerAbility(
  id: BattlerAbilityId.armaBiologica,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _ataqueDebuffContagioAbilityTags,
  name: 'Arma Biologica',
  description:
      'Pasiva. Cuando Contagio enemigo pierde valor, infliges daño directo.',
  value: 1,
  upgradeValue: 2,
  effect: ArmaBiologicaAbilityEffect(),
  isImplemented: true,
);

/// Pasiva veloz defensiva que cura cuando el Contagio propio baja.
const inmunizacionAbility = BattlerAbility(
  id: BattlerAbilityId.inmunizacion,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _vidaDebuffContagioAbilityTags,
  name: 'Inmunizacion',
  description: 'Pasiva. Cuando Contagio pierde valor en ti, recuperas vida.',
  value: 4,
  upgradeValue: 4,
  effect: InmunizacionAbilityEffect(),
  isImplemented: true,
);

/// Pasiva veloz que aumenta el primer Contagio aplicado cada turno.
const cargaViricaAbility = BattlerAbility(
  id: BattlerAbilityId.cargaVirica,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.green,
  tags: _debuffContagioAbilityTags,
  name: 'Carga Virica',
  description:
      'Pasiva. La primera vez por turno que aplicas Contagio, aplica Contagio adicional.',
  value: 1,
  upgradeValue: 1,
  effect: CargaViricaAbilityEffect(),
  isImplemented: true,
);

/// Pasiva veloz que premia usar varios items de debuff en un Patron.
const epidemiologiaTacticaAbility = BattlerAbility(
  id: BattlerAbilityId.epidemiologiaTactica,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.blue,
  tags: _debuffContagioAbilityTags,
  name: 'Epidemiologia Tactica',
  description:
      'Pasiva de Patron. Si el Patron usa 2+ items con debuff, aplica Contagio antes de sus efectos.',
  value: 1,
  upgradeValue: 1,
  effect: EpidemiologiaTacticaAbilityEffect(),
  isImplemented: true,
);

/// Pasiva veloz que cruza Quemadura e Intoxicacion al activar Contagio.
const sintomasCruzadosAbility = BattlerAbility(
  id: BattlerAbilityId.sintomasCruzados,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _debuffContagioAbilityTags,
  name: 'Sintomas Cruzados',
  description:
      'Pasiva. Si activas Contagio aplicando Quemadura o Intoxicacion, tambien aplicas el otro debuff.',
  value: 1,
  upgradeValue: 0,
  effect: SintomasCruzadosAbilityEffect(),
  isImplemented: true,
);

/// Pasiva amarilla que abre el combate propagando Contagio por los items Veloz.
const pacienteCeroAbility = BattlerAbility(
  id: BattlerAbilityId.pacienteCero,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.yellow,
  tags: _debuffContagioAbilityTags,
  name: 'Paciente Cero',
  description:
      'Pasiva. Al principio del combate, aplica Contagio segun tus items Veloz equipados.',
  value: 1,
  upgradeValue: 1,
  effect: PacienteCeroAbilityEffect(),
  isImplemented: true,
);

/// Pasiva amarilla de Veloz que replica el doble golpe de las Gafas sin apilar su penalizacion.
const aceleracionFotovoltaicaAbility = BattlerAbility(
  id: BattlerAbilityId.aceleracionFotovoltaica,
  archetypeAffinities: _velozAbilityAffinities,
  rarity: RarityTier.yellow,
  tags: _ataqueAbilityTags,
  name: 'Aceleracion Fotovoltaica',
  description:
      'Pasiva. Cada ataque basico golpea una vez adicional, pero tus bonus de items, adyacencias y patrones se reducen a la mitad si no estaban ya reducidos.',
  value: 1,
  upgradeValue: 0,
  effect: AceleracionFotovoltaicaAbilityEffect(),
  isImplemented: true,
);

const b4r3b0n3dAbility = BattlerAbility(
  id: BattlerAbilityId.b4r3b0n3d,
  rarity: RarityTier.green,
  tags: _ataqueBarreraAbilityTags,
  name: 'B4r3B0n3D',
  description:
      'Pasiva de Patron. Si el Patron no activa efectos de items, ganas Potencia y Barrera antes del ataque.',
  value: 1,
  upgradeValue: 1,
  effect: B4r3B0n3DAbilityEffect(),
  isImplemented: true,
);

const compensadorRutaAbility = BattlerAbility(
  id: BattlerAbilityId.compensadorRuta,
  rarity: RarityTier.purple,
  tags: _ataqueBarreraAbilityTags,
  name: 'Compensador de Ruta',
  description:
      'Pasiva. Al inicio del combate, ganas valor en la stat menos aportada por tus items entre HP, ATK y Barrera.',
  value: 3,
  upgradeValue: 1,
  effect: CompensadorRutaAbilityEffect(),
  isImplemented: true,
);

const aTodoRiesgoAbility = BattlerAbility(
  id: BattlerAbilityId.aTodoRiesgo,
  rarity: RarityTier.blue,
  tags: _economiaVidaAbilityTags,
  name: 'A Todo Riesgo',
  description:
      'Pasiva. La primera vez por combate que pierdes HP, ganas creditos igual al HP perdido mas valor.',
  value: 2,
  upgradeValue: 2,
  effect: ATodoRiesgoAbilityEffect(),
  isImplemented: true,
);

const ultimaPiezaAbility = BattlerAbility(
  id: BattlerAbilityId.ultimaPieza,
  rarity: RarityTier.yellow,
  tags: _ataqueBarreraAbilityTags,
  name: 'Ultima Pieza',
  description:
      'Pasiva. Al inicio del combate, mejora el item equipado con menos bonuses y lo marca con un aura.',
  value: 2,
  upgradeValue: 1,
  effect: UltimaPiezaAbilityEffect(),
  isImplemented: true,
);

const geometriaBolsilloAbility = BattlerAbility(
  id: BattlerAbilityId.geometriaBolsillo,
  rarity: RarityTier.blue,
  tags: _ataqueBarreraAbilityTags,
  name: 'Geometria de Bolsillo',
  description:
      'Pasiva. Al inicio del combate, hasta 1 item sin bonus de Patron gana un bonus de Patron aleatorio.',
  value: 1,
  upgradeValue: 1,
  effect: GeometriaBolsilloAbilityEffect(),
  isImplemented: true,
);

/// Pasiva general que permite que items simples funcionen como huecos de Patron.
const adaptacionAbility = BattlerAbility(
  id: BattlerAbilityId.adaptacion,
  rarity: RarityTier.purple,
  tags: _ataqueBarreraAbilityTags,
  name: 'Adaptacion',
  description:
      'Pasiva de Patron. Los items sin bonus de patron ni adyacencia cuentan como espacios vacios con bonus limitado.',
  value: 2,
  upgradeValue: 1,
  effect: AdaptacionAbilityEffect(),
  isImplemented: true,
);

/// Pasiva especial de Cinder Executioner que convierte cada turno en un horno compartido.
const hornoSimetricoAbility = BattlerAbility(
  id: BattlerAbilityId.hornoSimetrico,
  archetypeAffinities: _imparableAbilityAffinities,
  rarity: RarityTier.purple,
  tags: _ataqueDebuffAbilityTags,
  name: 'Horno Simetrico',
  description:
      'Pasiva. Al inicio de tu turno, aplicas Quemadura a ti y al rival.',
  value: 2,
  upgradeValue: 1,
  effect: HornoSimetricoAbilityEffect(),
  isImplemented: true,
);

/// Pasiva defensiva que amortigua la Purga de final de ronda.
const kilotonificacionAbility = BattlerAbility(
  id: BattlerAbilityId.kilotonificacion,
  archetypeAffinities: _inamovibleAbilityAffinities,
  rarity: RarityTier.green,
  tags: _vidaBarreraAbilityTags,
  name: 'Kilotónificación',
  description: 'Pasiva. Recibes value daño menos de la Purga.',
  value: 3,
  upgradeValue: 3,
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
  cortesAgudosAbility,
  rotoresDefensivosAbility,
  polarizacionAbility,
  arquitecturaPesadaAbility,
  rutaContrabandoAbility,
  ecoSimetriaAbility,
  patronPerfectoAbility,
  encendidoBrutalAbility,
  combustionDirigidaAbility,
  puntoIgnicionAbility,
  deudaSangreAbility,
  reventaCircularAbility,
  contratoReusoAbility,
  mercadoRecursivoAbility,
  comisionRiesgoAbility,
  franquiciaTotalAbility,
  agujaToxicaAbility,
  rastroInestableAbility,
  cadenaNeurotoxicaAbility,
  armaBiologicaAbility,
  inmunizacionAbility,
  cargaViricaAbility,
  epidemiologiaTacticaAbility,
  sintomasCruzadosAbility,
  pacienteCeroAbility,
  aceleracionFotovoltaicaAbility,
  b4r3b0n3dAbility,
  compensadorRutaAbility,
  aTodoRiesgoAbility,
  ultimaPiezaAbility,
  geometriaBolsilloAbility,
  adaptacionAbility,
  hornoSimetricoAbility,
  kilotonificacionAbility,
];

/// Indice canonico de presets para resolver ids sin duplicar switches.
final abilityPresetRegistry =
    Map<BattlerAbilityId, BattlerAbility>.unmodifiable({
  for (final ability in abilityPresets) ability.id: ability,
});
