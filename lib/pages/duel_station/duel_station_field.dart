import '_imports.dart';

class DuelStationField extends StatefulWidget {
  final DuelStationProvider provider;

  DuelStationField({required this.provider, super.key});

  @override
  State<DuelStationField> createState() => _DuelStationFieldState();
}

class _DuelStationFieldState extends State<DuelStationField> {
  int _currentTurn = 1;
  String _currentStep = 'cardPlayStep';
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
    // Find the field state and call rotate
    // This will be handled by the provider
  }

  void _onReadyPressed() {
    // This will be expanded when step system is implemented
    print('Ready button pressed');
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
            turnNumber: _currentTurn,
            currentStep: _currentStep,
            onRotatePressed: _onRotatePressed,
            onReadyPressed: _onReadyPressed,
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
                        isEnabled: true,
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