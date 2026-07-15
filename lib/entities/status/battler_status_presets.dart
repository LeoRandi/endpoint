import '_imports.dart';

/// Preset rapido del buff Calentando con su bonus por defecto.
const calentandoStatus = CalentandoStatus();

/// Preset rapido del buff Potencia con su bonus inicial.
const potenciaStatus = PotenciaStatus();

/// Preset rapido del buff Punto Ciego con su proteccion base.
const puntoCiegoStatus = PuntoCiegoStatus();

/// Preset rapido del buff Desafio con su golpe reservado base.
const desafioStatus = DesafioStatus();

/// Preset rapido del debuff Contagio con su amplificacion inicial.
const contagioStatus = ContagioStatus();

/// Preset rapido de Fragilidad con su acumulacion inicial.
const fragilidadStatus = FragilidadStatus();

/// Preset rapido de Conmocion con su penalizacion inicial.
const conmocionStatus = ConmocionStatus();

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
  BattlerStatusId.contagio: ({
    required int remainingTurns,
    required int value,
  }) =>
      ContagioStatus(value: value),
  BattlerStatusId.fragilidad: ({
    required int remainingTurns,
    required int value,
  }) =>
      FragilidadStatus(
        remainingTurns: remainingTurns,
        value: value,
      ),
  BattlerStatusId.conmocion: ({
    required int remainingTurns,
    required int value,
  }) =>
      ConmocionStatus(value: value),
  BattlerStatusId.compensadorRuta: ({
    required int remainingTurns,
    required int value,
  }) =>
      CompensadorRutaStatus(
        stat: BattlerStat.attack,
        value: value,
      ),
  BattlerStatusId.mercadoFuturos: ({
    required int remainingTurns,
    required int value,
  }) =>
      const MercadoFuturosStatus(),
});
