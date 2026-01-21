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
    // Show turn announcement for the initial turn
    setState(() {
      _announcedTurn = _stepManager.turnNumber;
    });
    
    // Wait for announcement to complete (1500ms animation)
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Execute start step events
    await _stepManager.executeStartStepEvents();
    
    // Advance to cardPlayStep
    await _stepManager.advanceToNextStep();
  }

  void _onAnnouncementComplete() {
    setState(() {
      _announcedTurn = null;
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
      ],
    );
  }
}
