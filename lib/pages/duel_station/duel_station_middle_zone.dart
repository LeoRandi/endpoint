import '_imports.dart';

class DuelStationMiddleZone extends StatefulWidget {
  final Function()? onRotatePressed;
  final Function()? onReadyPressed;
  final int turnNumber;
  final String currentStep;

  const DuelStationMiddleZone({
    this.onRotatePressed,
    this.onReadyPressed,
    this.turnNumber = 1,
    this.currentStep = 'startStep',
    super.key,
  });

  @override
  State<DuelStationMiddleZone> createState() => _DuelStationMiddleZoneState();
}

class _DuelStationMiddleZoneState extends State<DuelStationMiddleZone>
    with TickerProviderStateMixin {
  late AnimationController _turnSlideController;
  late AnimationController _stepSlideController;
  late Animation<Offset> _turnSlideAnimation;
  late Animation<Offset> _stepSlideAnimation;

  int _previousTurnNumber = 1;
  String _previousStep = 'startStep';

  @override
  void initState() {
    super.initState();
    _turnSlideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _stepSlideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _turnSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(parent: _turnSlideController, curve: Curves.easeInOut));

    _stepSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(parent: _stepSlideController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(DuelStationMiddleZone oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger turn slide animation when turn number changes
    if (oldWidget.turnNumber != widget.turnNumber) {
      _previousTurnNumber = oldWidget.turnNumber;
      _turnSlideController.forward(from: 0.0);
    }

    // Trigger step slide animation when step changes
    if (oldWidget.currentStep != widget.currentStep) {
      _previousStep = oldWidget.currentStep;
      _stepSlideController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _turnSlideController.dispose();
    _stepSlideController.dispose();
    super.dispose();
  }

  String _formatStepName(String step) {
    // Convert camelCase to Title Case (e.g., "cardPlayStep" -> "Card Play")
    final regex = RegExp(r'(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])');
    final words = step
        .replaceAll(regex, ' ')
        .replaceAll('Step', '')
        .trim()
        .split(' ');
    return words.map((word) => '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MIDDLE_ZONE_HEIGHT,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: MIDDLE_ZONE_HORIZONTAL_PADDING,
        vertical: MIDDLE_ZONE_VERTICAL_PADDING,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          top: BorderSide(color: Colors.grey[700]!, width: 1),
          bottom: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Turn Indicator (left)
          _buildTurnIndicator(),

          // Step Indicator (center-left)
          _buildStepIndicator(),

          // Rotate Button (center-right)
          ElevatedButton(
            onPressed: widget.onRotatePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.onRotatePressed != null ? Colors.purple : Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: MIDDLE_ZONE_BUTTON_HORIZONTAL_PADDING,
                vertical: MIDDLE_ZONE_BUTTON_VERTICAL_PADDING,
              ),
            ),
            child: const Text(
              'Rotate Battlers',
              style: TextStyle(fontSize: MIDDLE_ZONE_BUTTON_TEXT_FONT_SIZE),
            ),
          ),

          // Ready Button (right)
          ElevatedButton(
            onPressed: widget.onReadyPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.onReadyPressed != null ? Colors.green : Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: MIDDLE_ZONE_BUTTON_HORIZONTAL_PADDING,
                vertical: MIDDLE_ZONE_BUTTON_VERTICAL_PADDING,
              ),
            ),
            child: const Text(
              'Finish Turn',
              style: TextStyle(fontSize: MIDDLE_ZONE_BUTTON_TEXT_FONT_SIZE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator() {
    return SizedBox(
      width: MIDDLE_ZONE_TURN_WIDTH,
      height: MIDDLE_ZONE_TURN_HEIGHT,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Current turn number
            SlideTransition(
              position: _turnSlideAnimation,
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  '${widget.turnNumber}',
                  style: const TextStyle(
                    fontSize: MIDDLE_ZONE_TURN_FONT_SIZE,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
              ),
            ),
            // Previous turn number (comes from bottom)
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: const Offset(0, 0),
              ).animate(CurvedAnimation(
                parent: _turnSlideController,
                curve: Curves.easeInOut,
              )),
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  '$_previousTurnNumber',
                  style: TextStyle(
                    fontSize: MIDDLE_ZONE_TURN_FONT_SIZE,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return SizedBox(
      width: MIDDLE_ZONE_STEP_WIDTH,
      height: MIDDLE_ZONE_STEP_HEIGHT,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Current step
            SlideTransition(
              position: _stepSlideAnimation,
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  _formatStepName(widget.currentStep),
                  style: const TextStyle(
                    fontSize: MIDDLE_ZONE_STEP_FONT_SIZE,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Previous step (comes from bottom)
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: const Offset(0, 0),
              ).animate(CurvedAnimation(
                parent: _stepSlideController,
                curve: Curves.easeInOut,
              )),
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  _formatStepName(_previousStep),
                  style: TextStyle(
                    fontSize: MIDDLE_ZONE_STEP_FONT_SIZE,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
