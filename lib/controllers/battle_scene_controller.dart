import '../entities/_exports.dart';
import '../services/_exports.dart';
import 'controller_ui_text.dart';
import 'package:flutter/foundation.dart';

/// Agrupa la salida de combate ya resuelta y las recompensas que deben presentarse antes de salir.
class BattleSceneExitRequest {
  final BattleFlowResult exitResult;
  final BattleRewardBundle rewards;

  /// Construye una peticion de salida lista para que la escena decida si muestra botin o sale directamente.
  const BattleSceneExitRequest({
    required this.exitResult,
    required this.rewards,
  });
}

/// Names the current scene-level exit phase.
enum BattleSceneExitPhase {
  active,
  rewardPending,
  rewardPresenting,
  immediateExitPending,
}

/// Immutable state for pending battle exits and reward presentation.
class BattleSceneExitState {
  final BattleSceneExitPhase phase;
  final BattleSceneExitRequest? rewardRequest;
  final BattleFlowResult? immediateExitResult;

  const BattleSceneExitState._({
    required this.phase,
    this.rewardRequest,
    this.immediateExitResult,
  });

  /// No scene-level exit is waiting to be handled.
  const BattleSceneExitState.active()
      : this._(phase: BattleSceneExitPhase.active);

  /// A victory has rewards that must be presented before leaving the scene.
  const BattleSceneExitState.rewardPending(BattleSceneExitRequest request)
      : this._(
          phase: BattleSceneExitPhase.rewardPending,
          rewardRequest: request,
        );

  /// Rewards are already being presented and should not be opened twice.
  const BattleSceneExitState.rewardPresenting(BattleSceneExitRequest request)
      : this._(
          phase: BattleSceneExitPhase.rewardPresenting,
          rewardRequest: request,
        );

  /// The scene can leave immediately with [result].
  const BattleSceneExitState.immediateExit(BattleFlowResult result)
      : this._(
          phase: BattleSceneExitPhase.immediateExitPending,
          immediateExitResult: result,
        );

  bool get hasPendingVictoryRewards => rewardRequest != null;
  bool get isPresentingRewards => phase == BattleSceneExitPhase.rewardPresenting;
}

/// Orquesta el estado de escena alrededor de `BattleController`, incluyendo botin y acciones de UI.
class BattleSceneController extends ChangeNotifier {
  final BattleRewardService _rewardService;
  final RunRandomizer _randomizer;
  final BattleController _battleController;

  BattleSceneExitState _exitState = const BattleSceneExitState.active();

  /// Crea el controlador de escena de combate y enlaza la salida del motor principal a la UI.
  BattleSceneController({
    required Battler enemy,
    required Battler player,
    required RunHourPhase phase,
    required int enemyTier,
    required Duration enemyTurnDelay,
    required Duration combatEndDelay,
    required int victoryMoneyFactor,
    RunRandomizer? randomizer,
    BattleRewardService rewardService = const BattleRewardService(),
    BattleCombatAnimationCallback? onCombatAnimation,
  }) : this._(
          enemy: enemy,
          player: player,
          phase: phase,
          enemyTier: enemyTier,
          enemyTurnDelay: enemyTurnDelay,
          combatEndDelay: combatEndDelay,
          victoryMoneyFactor: victoryMoneyFactor,
          randomizer: randomizer ?? RunRandomizer(),
          rewardService: rewardService,
          onCombatAnimation: onCombatAnimation,
        );

  /// Reutiliza una unica fuente de azar para el motor de combate y las recompensas posteriores.
  BattleSceneController._({
    required Battler enemy,
    required Battler player,
    required RunHourPhase phase,
    required int enemyTier,
    required Duration enemyTurnDelay,
    required Duration combatEndDelay,
    required int victoryMoneyFactor,
    required RunRandomizer randomizer,
    required BattleRewardService rewardService,
    required BattleCombatAnimationCallback? onCombatAnimation,
  })  : _rewardService = rewardService,
        _randomizer = randomizer,
        _battleController = BattleController(
          enemy: enemy,
          player: player,
          phase: phase,
          enemyTier: enemyTier,
          randomizer: randomizer,
          enemyTurnDelay: enemyTurnDelay,
          combatEndDelay: combatEndDelay,
          onCombatAnimation: onCombatAnimation,
        ),
        _victoryMoneyFactor = victoryMoneyFactor {
    _battleController.addListener(_handleBattleControllerChanged);
  }

  final int _victoryMoneyFactor;

  /// Expone el motor de combate para que la vista escuche solo el subestado que necesita.
  BattleController get battleController => _battleController;

  /// Reexpone el jugador actual para HUD, dialogs y overlays.
  Battler get player => _battleController.player;

  /// Reexpone el enemigo actual para HUD y detalles del combate.
  Battler get enemy => _battleController.enemy;

  /// Reexpone la fuente de azar compartida por combate, overlays y recompensas.
  RunRandomizer get randomizer => _randomizer;

  /// Reexpone el turno actual del combate.
  BattleTurnState get turn => _battleController.turn;

  /// Indica si la vista puede ofrecer acciones manuales al jugador.
  bool get canUseActions => _battleController.canUseActions;

  /// Indica si el enemigo tiene listo un Patron que debe resolverse desde la escena.
  bool get canResolveEnemyPattern => _battleController.canResolveEnemyPattern;

  /// Indica si el combate ya termino dentro del motor principal.
  bool get isCombatFinished => _battleController.isCombatFinished;

  /// Reexpone el texto corto del estado de turno para el banner central.
  String get turnTitle => _battleController.turnTitle;

  /// Reexpone la descripcion corta del estado de turno para el banner central.
  String get turnDescription => _battleController.turnDescription;

  /// Reexpone la ronda actual para contadores y ayudas visuales de la escena.
  int get currentRound => _battleController.currentRound;
  List<List<String>> get playerBannedPatternPointKeys =>
      _battleController.playerBannedPatternPointKeys;
  List<List<String>> get enemyBannedPatternPointKeys =>
      _battleController.enemyBannedPatternPointKeys;

  /// Ronda en la que la Purga empieza a aplicar daño automatico.
  int get purgeStartRound => _battleController.purgeStartRound;

  /// Ronda en la que la escena debe empezar a advertir sobre la Purga.
  int get purgeWarningRound => _battleController.purgeWarningRound;

  /// Indica si el aviso visual de Purga debe mostrarse en esta ronda.
  bool get isPurgeWarningVisible => _battleController.isPurgeWarningVisible;

  /// Indica si la Purga ya esta activa y causando daño por ronda.
  bool get isPurgeActive => _battleController.isPurgeActive;

  /// Daño de Purga previsto sobre el jugador si avanza la ronda actual.
  int get playerPurgeDamagePreview =>
      _battleController.playerPurgeDamagePreview;

  /// Daño de Purga previsto sobre el enemigo si avanza la ronda actual.
  int get enemyPurgeDamagePreview => _battleController.enemyPurgeDamagePreview;

  /// Barrera que ganara el jugador al ejecutar la accion de bloqueo.
  int get playerBlockBarrierGain => _battleController.playerBlockBarrierGain;

  /// Reexpone la barrera base del jugador al inicio del combate.
  int get playerInitialBarrier => _battleController.playerInitialBarrier;

  /// Reexpone la intencion prevista del enemigo para HUDs y ayudas de decision.
  EnemyTurnIntentPreview get enemyTurnIntentPreview =>
      _battleController.enemyTurnIntentPreview;

  /// Reexpone la previsualizacion de la accion del jugador para los HUDs.
  PlayerActionIntentPreview get playerActionIntentPreview =>
      _battleController.playerActionIntentPreview;

  /// Indica si la escena tiene una salida en victoria pendiente de pasar por el overlay de botin.
  bool get hasPendingVictoryRewards => _exitState.hasPendingVictoryRewards;

  /// Expone la peticion de salida pendiente cuando la escena debe abrir el overlay de recompensas.
  BattleSceneExitRequest? get pendingRewardExitRequest =>
      _exitState.rewardRequest;

  /// Indica si ya se esta presentando el overlay de recompensas para evitar aperturas dobles.
  bool get isPresentingRewards => _exitState.isPresentingRewards;

  /// Expone el estado agrupado de salida para vistas nuevas.
  BattleSceneExitState get exitState => _exitState;

  /// Sustituye el jugador vivo del combate tras cambios externos como overlays.
  void replacePlayer(Battler player) {
    _battleController.replacePlayer(player);
  }

  /// Sustituye el enemigo activo cuando un efecto externo rehace el encuentro.
  void replaceEnemy(Battler enemy) {
    _battleController.replaceEnemy(enemy);
  }

  /// Ejecuta el ataque basico del jugador cuando la escena lo solicita.
  Future<void> handlePlayerAttack({
    BattleActionBonus actionBonus = BattleActionBonus.empty,
  }) {
    return _battleController.handleAttack(
      actionBonus: actionBonus,
    );
  }

  /// Ejecuta una coincidencia de Patron, que puede contar como ataque, defensa o ambas.
  Future<void> handlePlayerPatternMatch({
    BattleActionBonus actionBonus = BattleActionBonus.empty,
    BattlePatternMatchContext? patternContext,
    bool scheduleEnemyTurn = true,
  }) {
    return _battleController.handlePatternMatch(
      actionBonus: actionBonus,
      patternContext: patternContext,
      scheduleEnemyTurn: scheduleEnemyTurn,
    );
  }

  /// Ejecuta una coincidencia de Patron generada por el enemigo.
  ///
  /// Se mantiene separada de la ruta del jugador porque no agenda otro turno
  /// enemigo y porque algunos efectos diferencian el origen de la accion.
  Future<void> handleEnemyPatternMatch({
    BattleActionBonus actionBonus = BattleActionBonus.empty,
    BattlePatternMatchContext? patternContext,
  }) {
    return _battleController.handleEnemyPatternMatch(
      actionBonus: actionBonus,
      patternContext: patternContext,
    );
  }

  Future<void> handleSimultaneousPatternMatches({
    required BattleActionBonus playerActionBonus,
    required BattlePatternMatchContext playerPatternContext,
    required BattleActionBonus enemyActionBonus,
    required BattlePatternMatchContext enemyPatternContext,
    required List<BattlePatternActionPileEntry> playerActionPile,
    required List<BattlePatternActionPileEntry> enemyActionPile,
    BattlePatternActionPileStepCallback? onActionPileStep,
    BattlePatternActionPileUpdateCallback? onActionPileUpdate,
  }) {
    return _battleController.handleSimultaneousPatternMatches(
      playerActionBonus: playerActionBonus,
      playerPatternContext: playerPatternContext,
      enemyActionBonus: enemyActionBonus,
      enemyPatternContext: enemyPatternContext,
      playerActionPile: playerActionPile,
      enemyActionPile: enemyActionPile,
      onActionPileStep: onActionPileStep,
      onActionPileUpdate: onActionPileUpdate,
    );
  }

  /// Ejecuta la accion de bloqueo del jugador y termina su turno.
  Future<void> handlePlayerBlock({
    BattleActionBonus actionBonus = BattleActionBonus.empty,
  }) {
    return _battleController.handleBlock(
      actionBonus: actionBonus,
    );
  }

  /// Indica si la escena puede abrir el overlay de inventario de combate.
  bool canOpenItemsOverlay() {
    return canUseActions && !hasPendingVictoryRewards;
  }

  /// Devuelve el texto de estado que se muestra en el dialogo de un item equipado o inventariado.
  String statusLabelFor(Battler battler, Item item) {
    return ControllerUiText.itemStatusLabel(owner: battler, item: item);
  }

  /// Marca que el overlay de recompensas ya se esta presentando para evitar una segunda apertura.
  void beginRewardPresentation() {
    final request = _exitState.rewardRequest;
    if (request == null || _exitState.isPresentingRewards) return;

    _exitState = BattleSceneExitState.rewardPresenting(request);
    notifyListeners();
  }

  /// Convierte la recompensa elegida por el usuario en una salida inmediata ya saneada.
  void completeRewardPresentation(Battler? rewardedPlayer) {
    final request = _exitState.rewardRequest;
    if (request == null) return;

    _exitState = BattleSceneExitState.immediateExit(
      _rewardService.sanitizeExitResult(
        BattleFlowResult(
          type: request.exitResult.type,
          player: rewardedPlayer ?? request.exitResult.player,
        ),
      ),
    );
    notifyListeners();
  }

  /// Devuelve y consume la siguiente salida inmediata que la escena debe materializar con navegación.
  BattleFlowResult? consumeImmediateExitResult() {
    final result = _exitState.immediateExitResult;
    if (result != null) {
      _exitState = const BattleSceneExitState.active();
    }
    return result;
  }

  /// Libera listeners y el motor interno cuando la escena desaparece.
  @override
  void dispose() {
    _battleController
      ..removeListener(_handleBattleControllerChanged)
      ..dispose();
    super.dispose();
  }

  /// Reacciona a los resultados diferidos del motor de combate y los traduce a salidas de escena.
  void _handleBattleControllerChanged() {
    final exitResult = _battleController.consumePendingExitResult();
    if (exitResult == null) {
      notifyListeners();
      return;
    }

    if (exitResult.type != BattleFlowResultType.victory) {
      _exitState = BattleSceneExitState.immediateExit(
        _rewardService.sanitizeExitResult(exitResult),
      );
      notifyListeners();
      return;
    }

    final rewards = _rewardService.buildVictoryRewards(
      enemy: _battleController.enemy,
      player: exitResult.player,
      victoryMoneyFactor: _victoryMoneyFactor,
      randomizer: _randomizer,
    );
    if (!rewards.hasRewards) {
      _exitState = BattleSceneExitState.immediateExit(
        _rewardService.sanitizeExitResult(exitResult),
      );
      notifyListeners();
      return;
    }

    _exitState = BattleSceneExitState.rewardPending(
      BattleSceneExitRequest(
        exitResult: exitResult,
        rewards: rewards,
      ),
    );
    notifyListeners();
  }
}
