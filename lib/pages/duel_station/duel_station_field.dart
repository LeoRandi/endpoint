import '_imports.dart';

class DuelStationField extends StatefulWidget {
  final DuelStationProvider provider;
  final DuelStationStepManager stepManager;

  const DuelStationField({
    required this.provider,
    required this.stepManager,
    super.key,
  });

  @override
  State<DuelStationField> createState() => _DuelStationFieldState();
}

class _DuelStationFieldState extends State<DuelStationField> {
  void _onReadyPressed() {
    if (widget.stepManager.currentStep == DuelStep.cardPlayStep) {
      widget.stepManager.onReadyButtonPressed();
      _continueTurnCycle();
    }
  }

  Future<void> _continueTurnCycle() async {
    while (widget.stepManager.currentStep != DuelStep.cardPlayStep &&
        widget.stepManager.currentStep != DuelStep.startStep) {
      await widget.stepManager.advanceToNextStep();
    }

    if (widget.stepManager.currentStep == DuelStep.startStep) {
      await widget.stepManager.executeStartStepEvents();
      await widget.stepManager.advanceToNextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(FIELD_PADDING),
          child: DuelStationBattlerLineup(
            battlers: widget.provider.getFieldBattlers(DuelistSide.enemy),
            side: DuelistSide.enemy,
          ),
        ),
        DuelStationMiddleZone(
          turnNumber: widget.stepManager.turnNumber,
          currentStep: widget.stepManager.getStepCamelCase(),
          onRotatePressed: null,
          onReadyPressed:
              widget.stepManager.isReadyButtonEnabled ? _onReadyPressed : null,
        ),
        Padding(
          padding: const EdgeInsets.all(FIELD_PADDING),
          child: DuelStationBattlerLineup(
            battlers: widget.provider.getFieldBattlers(DuelistSide.ally),
            side: DuelistSide.ally,
          ),
        ),
      ],
    );
  }
}
