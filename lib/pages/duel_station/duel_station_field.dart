import '_imports.dart';

class DuelStationField extends StatefulWidget {
  final DuelStationProvider provider;
  final DuelStationStepManager stepManager;

  DuelStationField({
    required this.provider,
    required this.stepManager,
    super.key,
  });

  @override
  State<DuelStationField> createState() => _DuelStationFieldState();
}

class _DuelStationFieldState extends State<DuelStationField> {
  // Global keys to access party widget states for animation
  late GlobalKey<State<DuelStationParty>> _enemyPartyKey;
  late GlobalKey<State<DuelStationParty>> _allyPartyKey;

  @override
  void initState() {
    super.initState();
    _enemyPartyKey = GlobalKey();
    _allyPartyKey = GlobalKey();
  }

  void _onRotatePressed() {
    // Rotate both parties
    widget.provider.rotateAllBattlers();

    // Trigger animations - access internal state to animate rotation
    final enemyState = _enemyPartyKey.currentState;
    final allyState = _allyPartyKey.currentState;

    if (enemyState != null) {
      // Cast to dynamic to call animateRotation
      (enemyState as dynamic).animateRotation();
    }
    if (allyState != null) {
      (allyState as dynamic).animateRotation();
    }

    // Trigger appbar update
    setState(() {});
  }

  void _onReadyPressed() {
    if (widget.stepManager.currentStep == DuelStep.cardPlayStep) {
      widget.stepManager.onReadyButtonPressed();
      
      // Continue the turn cycle through remaining steps
      _continueTurnCycle();
    }
  }

  Future<void> _continueTurnCycle() async {
    // Loop through remaining steps until we get back to startStep or cardPlayStep
    while (widget.stepManager.currentStep != DuelStep.cardPlayStep && 
           widget.stepManager.currentStep != DuelStep.startStep) {
      await widget.stepManager.advanceToNextStep();
    }
    
    // If we're at startStep, execute start step events
    if (widget.stepManager.currentStep == DuelStep.startStep) {
      await widget.stepManager.executeStartStepEvents();
      await widget.stepManager.advanceToNextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Enemy side (top)
          Padding(
            padding: EdgeInsets.all(
              FIELD_PADDING,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Enemy party (top-left)
                DuelStationParty(
                  key: _enemyPartyKey,
                  battlers: widget.provider.getFieldBattlers(DuelistSide.enemy),
                  side: DuelistSide.enemy,
                  isEnemySide: true,
                  provider: widget.provider,
                ),
                // Enemy drop slot (read-only, right of enemy party)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Ally drop slot (droppable, left of ally party)
                      DuelStationDropSlot(
                        side: DuelistSide.enemy,
                        isEnabled: false,
                      ),
                      // Additional drop slots can be added here in the future
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Middle zone with turn/step indicators and action buttons
          DuelStationMiddleZone(
            turnNumber: widget.stepManager.turnNumber,
            currentStep: widget.stepManager.getStepCamelCase(),
            onRotatePressed: widget.stepManager.isRotateButtonEnabled ? _onRotatePressed : null,
            onReadyPressed: widget.stepManager.isReadyButtonEnabled ? _onReadyPressed : null,
          ),

          // Ally side (bottom)
          Padding(
            padding: EdgeInsets.all(
              FIELD_PADDING,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ally drop slots area (left side, expandable for future slots)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Ally drop slot (droppable, left of ally party)
                      DuelStationDropSlot(
                        side: DuelistSide.ally,
                        isEnabled: widget.stepManager.isSlotsEnabled,
                        onCardDropped: (card) {
                          // if (card is BattleCardBattler) {
                          //   // Find first empty slot in ally field
                          //   final battlers = widget.provider.getFieldBattlers(DuelistSide.ally);
                          //   for (int i = 0; i < 5; i++) {
                          //     if (battlers[i] == null) {
                          //       setState(() {
                          //         widget.provider.placeBattlerOnField(card, DuelistSide.ally, i);
                          //       });
                          //       break;
                          //     }
                          //   }
                          // }
                        },
                      ),
                      // Additional drop slots can be added here in the future
                    ],
                  ),
                ),
                // Ally party (bottom-right)
                DuelStationParty(
                  key: _allyPartyKey,
                  battlers: widget.provider.getFieldBattlers(DuelistSide.ally),
                  side: DuelistSide.ally,
                  isEnemySide: false,
                  provider: widget.provider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}