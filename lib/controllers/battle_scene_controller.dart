import '../entities/_exports.dart';
import '../services/_exports.dart';
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

/// Orquesta el estado de escena alrededor de `BattleController`, incluyendo botin y acciones de UI.
class BattleSceneController extends ChangeNotifier {
  final BattleRewardService _rewardService;
  final RunRandomizer _randomizer;
  final BattleController _battleController;

  BattleSceneExitRequest? _pendingRewardExitRequest;
  BattleFlowResult? _pendingImmediateExitResult;
  bool _isPresentingRewards = false;

  /// Crea el controlador de escena de combate y enlaza la salida del motor principal a la UI.
  BattleSceneController({
    required Battler enemy,
    required Battler player,
    required int enemyTier,
    required Duration enemyTurnDelay,
    required Duration combatEndDelay,
    required int victoryMoneyFactor,
    RunRandomizer? randomizer,
    BattleRewardService rewardService = const BattleRewardService(),
  }) : this._(
          enemy: enemy,
          player: player,
          enemyTier: enemyTier,
          enemyTurnDelay: enemyTurnDelay,
          combatEndDelay: combatEndDelay,
          victoryMoneyFactor: victoryMoneyFactor,
          randomizer: randomizer ?? RunRandomizer(),
          rewardService: rewardService,
        );

  /// Reutiliza una unica fuente de azar para el motor de combate y las recompensas posteriores.
  BattleSceneController._({
    required Battler enemy,
    required Battler player,
    required int enemyTier,
    required Duration enemyTurnDelay,
    required Duration combatEndDelay,
    required int victoryMoneyFactor,
    required RunRandomizer randomizer,
    required BattleRewardService rewardService,
  })  : _rewardService = rewardService,
        _randomizer = randomizer,
        _battleController = BattleController(
          enemy: enemy,
          player: player,
          enemyTier: enemyTier,
          randomizer: randomizer,
          enemyTurnDelay: enemyTurnDelay,
          combatEndDelay: combatEndDelay,
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

  /// Indica si el combate ya termino dentro del motor principal.
  bool get isCombatFinished => _battleController.isCombatFinished;

  /// Reexpone el texto corto del estado de turno para el banner central.
  String get turnTitle => _battleController.turnTitle;

  /// Reexpone la descripcion corta del estado de turno para el banner central.
  String get turnDescription => _battleController.turnDescription;
  int get currentRound => _battleController.currentRound;
  int get playerBlockBarrierGain => _battleController.playerBlockBarrierGain;
  int get playerInitialBarrier => _battleController.playerInitialBarrier;
  EnemyTurnIntentPreview get enemyTurnIntentPreview =>
      _battleController.enemyTurnIntentPreview;

  /// Indica si la escena tiene una salida en victoria pendiente de pasar por el overlay de botin.
  bool get hasPendingVictoryRewards => _pendingRewardExitRequest != null;

  /// Expone la peticion de salida pendiente cuando la escena debe abrir el overlay de recompensas.
  BattleSceneExitRequest? get pendingRewardExitRequest =>
      _pendingRewardExitRequest;

  /// Indica si ya se esta presentando el overlay de recompensas para evitar aperturas dobles.
  bool get isPresentingRewards => _isPresentingRewards;

  /// Devuelve solo las habilidades que deben verse en la interfaz del contexto de combate.
  List<BattlerAbility> visibleAbilitiesFor(Battler battler) {
    return battler.abilities
        .where(
          (ability) =>
              ability.appearsInContext(BattlerAbilityActivationContext.battle),
        )
        .toList(growable: false);
  }

  /// Indica si una habilidad puede activarse de forma rapida mediante pulsacion mantenida.
  bool canQuickActivateAbility(BattlerAbility ability) {
    return !ability.isActive &&
        isAbilityActionEnabled(
          ability,
          canControlOwner: true,
        );
  }

  /// Ejecuta el ataque basico del jugador cuando la escena lo solicita.
  void handlePlayerAttack({
    BattleAttackDrawingBonus drawingBonus = BattleAttackDrawingBonus.empty,
    BattleAttackDrawingPenalty drawingPenalty =
        BattleAttackDrawingPenalty.empty,
  }) {
    _battleController.handleAttack(
      drawingBonus: drawingBonus,
      drawingPenalty: drawingPenalty,
    );
  }

  /// Ejecuta la accion de bloqueo del jugador y termina su turno.
  void handlePlayerBlock({
    BattleAttackDrawingBonus drawingBonus = BattleAttackDrawingBonus.empty,
    BattleAttackDrawingPenalty drawingPenalty =
        BattleAttackDrawingPenalty.empty,
  }) {
    _battleController.handleBlock(
      drawingBonus: drawingBonus,
      drawingPenalty: drawingPenalty,
    );
  }

  /// Alterna una habilidad manual del jugador dentro del combate.
  void togglePlayerAbility(BattlerAbility ability) {
    _battleController.togglePlayerAbility(ability);
  }

  /// Activa una habilidad manual de combate sin abrir primero el dialogo de detalle.
  void quickActivateAbility(BattlerAbility ability) {
    if (!canQuickActivateAbility(ability)) return;

    _battleController.togglePlayerAbility(ability);
  }

  /// Indica si la escena puede abrir el overlay de inventario de combate.
  bool canOpenItemsOverlay() {
    return canUseActions && !hasPendingVictoryRewards;
  }

  /// Devuelve el texto de estado que se muestra en el dialogo de un item equipado o inventariado.
  String statusLabelFor(Battler battler, Item item) {
    if (battler.equippedItems.contains(item)) {
      return 'Estado actual: equipado';
    }
    if (battler.inventoryItems.contains(item)) {
      return 'Estado actual: en inventario';
    }
    return 'Estado actual: no disponible';
  }

  /// Construye el texto de estado de una habilidad para el dialogo contextual de combate.
  String abilityStatusTextFor(
    BattlerAbility ability, {
    required bool canControlOwner,
  }) {
    final stateText = ability.isActive
        ? 'Estado actual: activa.'
        : ability.isOnCooldown
            ? 'Estado actual: en cooldown (${ability.remainingCooldownLabel}).'
            : 'Estado actual: lista.';
    final ownershipText =
        canControlOwner ? 'Pertenece al jugador.' : 'Pertenece al enemigo.';
    final activationText = ability.manualActivationContext == null
        ? 'Se aplica sin activacion manual.'
        : 'Se puede activar manualmente en ${ability.manualActivationContext!.label}.';

    return '$stateText $ownershipText $activationText';
  }

  /// Devuelve la etiqueta del boton principal del dialogo de habilidad si la accion existe.
  String? abilityActionLabelFor(
    BattlerAbility ability, {
    required bool canControlOwner,
  }) {
    if (!canControlOwner ||
        !ability.canToggleOn(BattlerAbilityActivationContext.battle)) {
      return null;
    }

    return ability.isActive ? 'Desactivar' : 'Activar';
  }

  /// Indica si la accion principal del dialogo de habilidad esta habilitada ahora mismo.
  bool isAbilityActionEnabled(
    BattlerAbility ability, {
    required bool canControlOwner,
  }) {
    if (!canControlOwner ||
        !ability.canToggleOn(BattlerAbilityActivationContext.battle) ||
        !_battleController.canUseActions) {
      return false;
    }
    if (ability.isActive) return true;
    if (!_battleController.player.canActivateManualAbilities(
      BattlerAbilityActivationContext.battle,
    )) {
      return false;
    }

    return !ability.isOnCooldown && ability.isImplemented;
  }

  /// Explica por que la accion principal del dialogo de habilidad esta bloqueada.
  String disabledAbilityActionTooltipFor(
    BattlerAbility ability, {
    required bool canControlOwner,
  }) {
    if (!canControlOwner) return 'Solo puedes gestionar habilidades propias';
    if (!_battleController.canUseActions) {
      return 'Solo puedes gestionar habilidades en tu turno';
    }
    final blockReason =
        _battleController.player.manualAbilityActivationBlockReason(
      BattlerAbilityActivationContext.battle,
    );
    if (blockReason != null && !ability.isActive) {
      return blockReason;
    }
    if (!ability.isImplemented) return 'La habilidad aun no esta implementada';
    if (ability.isOnCooldown) {
      return 'Recarga restante: ${ability.remainingCooldownLabel}';
    }
    return 'No se puede activar desde esta pantalla';
  }

  /// Marca que el overlay de recompensas ya se esta presentando para evitar una segunda apertura.
  void beginRewardPresentation() {
    if (_pendingRewardExitRequest == null || _isPresentingRewards) return;

    _isPresentingRewards = true;
    notifyListeners();
  }

  /// Convierte la recompensa elegida por el usuario en una salida inmediata ya saneada.
  void completeRewardPresentation(Battler? rewardedPlayer) {
    final request = _pendingRewardExitRequest;
    if (request == null) return;

    _pendingRewardExitRequest = null;
    _isPresentingRewards = false;
    _pendingImmediateExitResult = _rewardService.sanitizeExitResult(
      BattleFlowResult(
        type: request.exitResult.type,
        player: rewardedPlayer ?? request.exitResult.player,
      ),
    );
    notifyListeners();
  }

  /// Devuelve y consume la siguiente salida inmediata que la escena debe materializar con navegación.
  BattleFlowResult? consumeImmediateExitResult() {
    final result = _pendingImmediateExitResult;
    _pendingImmediateExitResult = null;
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
    if (exitResult == null) return;

    if (exitResult.type != BattleFlowResultType.victory) {
      _pendingImmediateExitResult =
          _rewardService.sanitizeExitResult(exitResult);
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
      _pendingImmediateExitResult =
          _rewardService.sanitizeExitResult(exitResult);
      notifyListeners();
      return;
    }

    _pendingRewardExitRequest = BattleSceneExitRequest(
      exitResult: exitResult,
      rewards: rewards,
    );
    notifyListeners();
  }
}
