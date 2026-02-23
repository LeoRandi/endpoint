import '_imports.dart';

enum DuelStep {
  startStep,
  cardPlayStep,
  combatStep,
  rotationStep,
  endStep,
}

class DuelStationStepManager {
  int turnNumber = 1;
  DuelStep currentStep = DuelStep.startStep;
  bool isRotateButtonEnabled = false;
  bool isReadyButtonEnabled = false;
  bool isPlayerHandEnabled = false;
  bool isSlotsEnabled = false;

  final Function(DuelStep) onStepChanged;
  final Function(int) onTurnChanged;
  final Function() onStepStateChanged;

  DuelStationStepManager({
    required this.onStepChanged,
    required this.onTurnChanged,
    required this.onStepStateChanged,
  });

  String getStepDisplayName() {
    switch (currentStep) {
      case DuelStep.startStep:
        return 'Start Step';
      case DuelStep.cardPlayStep:
        return 'Card Play';
      case DuelStep.combatStep:
        return 'Combat';
      case DuelStep.rotationStep:
        return 'Rotation';
      case DuelStep.endStep:
        return 'End Step';
    }
  }

  String getStepCamelCase() {
    switch (currentStep) {
      case DuelStep.startStep:
        return 'startStep';
      case DuelStep.cardPlayStep:
        return 'cardPlayStep';
      case DuelStep.combatStep:
        return 'combatStep';
      case DuelStep.rotationStep:
        return 'rotationStep';
      case DuelStep.endStep:
        return 'endStep';
    }
  }

  void setStepState(DuelStep step) {
    currentStep = step;
    
    // Update button/hand/slot enabled states based on step
    switch (step) {
      case DuelStep.startStep:
        isRotateButtonEnabled = false;
        isReadyButtonEnabled = false;
        isPlayerHandEnabled = false;
        isSlotsEnabled = false;
        break;
      case DuelStep.cardPlayStep:
        isRotateButtonEnabled = false;
        isReadyButtonEnabled = true;
        isPlayerHandEnabled = true;
        isSlotsEnabled = true;
        break;
      case DuelStep.combatStep:
        isRotateButtonEnabled = false;
        isReadyButtonEnabled = false;
        isPlayerHandEnabled = false;
        isSlotsEnabled = false;
        break;
      case DuelStep.rotationStep:
        isRotateButtonEnabled = false;
        isReadyButtonEnabled = false;
        isPlayerHandEnabled = false;
        isSlotsEnabled = false;
        break;
      case DuelStep.endStep:
        isRotateButtonEnabled = false;
        isReadyButtonEnabled = false;
        isPlayerHandEnabled = false;
        isSlotsEnabled = false;
        break;
    }

    onStepChanged(step);
    onStepStateChanged();
  }

  // Called when Ready button is pressed
  void onReadyButtonPressed() {
    if (currentStep == DuelStep.cardPlayStep) {
      advanceToNextStep();
    }
  }

  // Advance to next step
  Future<void> advanceToNextStep() async {
    DuelStep nextStep;
    
    switch (currentStep) {
      case DuelStep.startStep:
        // Wait 800ms before advancing
        await Future.delayed(const Duration(milliseconds: TIME_BETWEEN_TURN_STEPS));
        nextStep = DuelStep.cardPlayStep;
        break;
      case DuelStep.cardPlayStep:
        // Wait 800ms before advancing
        await Future.delayed(const Duration(milliseconds: TIME_BETWEEN_TURN_STEPS));
        nextStep = DuelStep.combatStep;
        break;
      case DuelStep.combatStep:
        // Wait 800ms before advancing
        await Future.delayed(const Duration(milliseconds: TIME_BETWEEN_TURN_STEPS));
        nextStep = DuelStep.rotationStep;
        break;
      case DuelStep.rotationStep:
        // Wait 800ms before advancing
        await Future.delayed(const Duration(milliseconds: TIME_BETWEEN_TURN_STEPS));
        nextStep = DuelStep.endStep;
        break;
      case DuelStep.endStep:
        // Wait 800ms before advancing to next turn
        await Future.delayed(const Duration(milliseconds: TIME_BETWEEN_TURN_STEPS));
        turnNumber++;
        onTurnChanged(turnNumber);
        nextStep = DuelStep.startStep;
        break;
    }

    setStepState(nextStep);
  }

  // Execute start step events
  Future<void> executeStartStepEvents() async {
    // TODO: Implement start step event logic
    print('Executing start step events for turn $turnNumber');
  }
}
