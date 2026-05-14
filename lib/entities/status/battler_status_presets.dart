import '../_imports.dart';

/// Preset rapido del buff Calentando con su bonus por defecto.
const calentandoStatus = CalentandoStatus();

/// Preset rapido del buff Potencia con su bonus inicial.
const potenciaStatus = PotenciaStatus();

/// Preset rapido del buff de Eclipse Manual con su duracion base.
const cicloEclipseStatus = CicloEclipseStatus();

/// Preset rapido del buff Punto Ciego con su proteccion base.
const puntoCiegoStatus = PuntoCiegoStatus();

/// Preset rapido del buff Desafio con su golpe reservado base.
const desafioStatus = DesafioStatus();

/// Preset rapido del buff que mejora los siguientes Desafios.
const desafioExcitanteStatus = DesafioExcitanteStatus();

/// Preset rapido del debuff Catalisis Cruel con su multiplicador inicial.
const catalisisCruelStatus = CatalisisCruelStatus();

/// Preset rapido de Fragilidad con su acumulacion inicial.
const fragilidadStatus = FragilidadStatus();

/// Preset rapido de Interferencia con su bloqueo corto por defecto.
const interferenciaStatus = InterferenciaStatus();

/// Preset rapido de Conmocion con su penalizacion inicial.
const conmocionStatus = ConmocionStatus();

/// Preset rapido de Inercia con la ganancia base por activacion.
const inerciaStatus = InerciaStatus();

/// Preset rapido de Deuda con la cuota inicial estandar.
const deudaStatus = DeudaStatus();

/// Preset rapido de Quemadura con la duracion base.
const quemaduraStatus = QuemaduraStatus();

/// Preset rapido de Intoxicacion con el valor inicial mas simple.
const intoxicacionStatus = IntoxicacionStatus();

/// Firma comun para reconstruir estados serializados desde ids estables.
typedef BattlerStatusFactory = BattlerStatus Function({
  required int remainingTurns,
  required int value,
});

/// Registro canonico de factorias de estados para codec y contenido runtime.
final battlerStatusFactoryById =
    Map<BattlerStatusId, BattlerStatusFactory>.unmodifiable({
  BattlerStatusId.calentando: ({
    required int remainingTurns,
    required int value,
  }) =>
      CalentandoStatus(
        remainingTurns: remainingTurns,
        value: value,
      ),
  BattlerStatusId.potencia: ({
    required int remainingTurns,
    required int value,
  }) =>
      PotenciaStatus(value: value),
  BattlerStatusId.cicloEclipse: ({
    required int remainingTurns,
    required int value,
  }) =>
      CicloEclipseStatus(
        remainingTurns: remainingTurns,
        value: value,
      ),
  BattlerStatusId.puntoCiego: ({
    required int remainingTurns,
    required int value,
  }) =>
      PuntoCiegoStatus(
        remainingTurns: remainingTurns,
        value: value,
      ),
  BattlerStatusId.desafio: ({
    required int remainingTurns,
    required int value,
  }) =>
      DesafioStatus(value: value),
  BattlerStatusId.desafioExcitante: ({
    required int remainingTurns,
    required int value,
  }) =>
      DesafioExcitanteStatus(value: value),
  BattlerStatusId.quemadura: ({
    required int remainingTurns,
    required int value,
  }) =>
      QuemaduraStatus(
        remainingTurns: remainingTurns,
        value: value,
      ),
  BattlerStatusId.intoxicacion: ({
    required int remainingTurns,
    required int value,
  }) =>
      IntoxicacionStatus(
        remainingTurns: remainingTurns,
        value: value,
      ),
  BattlerStatusId.catalisisCruel: ({
    required int remainingTurns,
    required int value,
  }) =>
      CatalisisCruelStatus(value: value),
  BattlerStatusId.fragilidad: ({
    required int remainingTurns,
    required int value,
  }) =>
      FragilidadStatus(
        remainingTurns: remainingTurns,
        value: value,
      ),
  BattlerStatusId.interferencia: ({
    required int remainingTurns,
    required int value,
  }) =>
      InterferenciaStatus(
        remainingTurns: remainingTurns,
        value: value,
      ),
  BattlerStatusId.conmocion: ({
    required int remainingTurns,
    required int value,
  }) =>
      ConmocionStatus(value: value),
  BattlerStatusId.inercia: ({
    required int remainingTurns,
    required int value,
  }) =>
      InerciaStatus(value: value),
  BattlerStatusId.inerciaAtaque: ({
    required int remainingTurns,
    required int value,
  }) =>
      InerciaAtaqueStatus(value: value),
  BattlerStatusId.inerciaBarrera: ({
    required int remainingTurns,
    required int value,
  }) =>
      InerciaBarreraStatus(value: value),
  BattlerStatusId.deuda: ({
    required int remainingTurns,
    required int value,
  }) =>
      DeudaStatus(value: value),
});
