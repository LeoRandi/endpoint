import '_imports.dart';

class DuelStationPage extends StatefulWidget {
  final DuelStationProvider provider;
  DuelStationPage(this.provider, {super.key});

  @override
  State<DuelStationPage> createState() => _DuelStationPageState();
}

class _DuelStationPageState extends State<DuelStationPage> {
  late DuelStationStepManager _stepManager;
  int? _announcedTurn;
  DuelistSide? _coinFlipWinner;
  bool _showCoinFlip = false;
  Completer<void>? _turnAnnouncementCompleter;
  Completer<void>? _coinFlipCompleter;

  @override
  void initState() {
    super.initState();
    widget.provider.init();
    
    // Initialize step manager with callbacks that update the page
    _stepManager = DuelStationStepManager(
      onStepChanged: (_) => setState(() {}),
      onTurnChanged: (newTurn) {
        setState(() {
          _announcedTurn = newTurn;
        });
      },
      onStepStateChanged: () => setState(() {}),
    );
    
    // Start the turn cycle
    _startTurnCycle();
  }

  void _startTurnCycle() async {
    await _showTurnAnnouncement();
    await _showCoinFlipAnnouncement();

    if (!mounted) return;

    // Execute start step events
    await _stepManager.executeStartStepEvents();

    // Advance to cardPlayStep
    await _stepManager.advanceToNextStep();
  }

  Future<void> _showTurnAnnouncement() async {
    _turnAnnouncementCompleter = Completer<void>();
    setState(() {
      _announcedTurn = _stepManager.turnNumber;
    });
    await _turnAnnouncementCompleter!.future;
  }

  Future<void> _showCoinFlipAnnouncement() async {
    final coinFlipWinner =
        Random().nextBool() ? DuelistSide.ally : DuelistSide.enemy;
    _coinFlipCompleter = Completer<void>();
    setState(() {
      _coinFlipWinner = coinFlipWinner;
      _showCoinFlip = true;
    });
    await _coinFlipCompleter!.future;
  }

  void _onAnnouncementComplete() {
    if (_turnAnnouncementCompleter != null &&
        !_turnAnnouncementCompleter!.isCompleted) {
      _turnAnnouncementCompleter!.complete();
    }
    setState(() {
      _announcedTurn = null;
    });
  }

  void _onCoinFlipComplete() {
    if (_coinFlipCompleter != null && !_coinFlipCompleter!.isCompleted) {
      _coinFlipCompleter!.complete();
    }
    setState(() {
      _showCoinFlip = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Top appbar showing active battlers
            DuelStationDuelistAppBar(
              enemyBattler: widget.provider.getActiveBattler(DuelistSide.enemy),
              allyBattler: widget.provider.getActiveBattler(DuelistSide.ally),
            ),
            // Enemy hand (below enemy appbar)
            DuelStationHand(
              hand: widget.provider.getStartingHand(DuelistSide.enemy),
              isPlayerHand: false,
              isEnabled: _stepManager.isPlayerHandEnabled,
            ),

            // Duel field (center)
            Expanded(
              child: DuelStationField(
                provider: widget.provider,
                stepManager: _stepManager,
              ),
            ),

            // Ally hand (bottom)
            DuelStationHand(
              hand: widget.provider.getStartingHand(DuelistSide.ally),
              isPlayerHand: true,
              isEnabled: _stepManager.isPlayerHandEnabled,
            ),
          ],
        ),
        // Turn announcement overlay
        if (_announcedTurn != null)
          DuelStationTurnAnnouncement(
            turnNumber: _announcedTurn!,
            onAnimationComplete: _onAnnouncementComplete,
          ),
        if (_showCoinFlip && _coinFlipWinner != null)
          DuelStationCoinFlipAnnouncement(
            winner: _coinFlipWinner!,
            onAnimationComplete: _onCoinFlipComplete,
          ),
      ],
    );
  }
}
