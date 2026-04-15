import 'package:showcaseview/showcaseview.dart';

import '../../services/endpoint_preferences_service.dart';
import '../_imports.dart';

class EndpointTutorialStepDescriptor {
  final String targetId;
  final String description;
  final String? imageAssetPath;
  final BorderRadius highlightBorderRadius;
  final EdgeInsets highlightPadding;
  final TooltipPosition? tooltipPosition;

  const EndpointTutorialStepDescriptor({
    required this.targetId,
    required this.description,
    this.imageAssetPath,
    this.highlightBorderRadius = const BorderRadius.all(Radius.circular(12)),
    this.highlightPadding = const EdgeInsets.all(6),
    this.tooltipPosition,
  });
}

class EndpointTutorialHost extends StatefulWidget {
  final Widget child;
  final String tutorialId;
  final int tutorialVersion;
  final List<EndpointTutorialStepDescriptor> steps;
  final List<String> fallbackImagePool;
  final bool enabled;
  final String barrierLabel;
  final String skipLabel;
  final String previousLabel;
  final String nextLabel;

  const EndpointTutorialHost({
    super.key,
    required this.child,
    required this.tutorialId,
    this.tutorialVersion = 1,
    required this.steps,
    this.fallbackImagePool = const <String>[],
    this.enabled = true,
    this.barrierLabel = 'Tutorial',
    this.skipLabel = 'SALTAR',
    this.previousLabel = '<-',
    this.nextLabel = '->',
  });

  static Future<void> startTutorial(
    BuildContext context, {
    bool force = false,
  }) async {
    final scope = _EndpointTutorialRegistryScope.maybeOf(context);
    if (scope == null) {
      debugPrint(
        'EndpointTutorialHost.startTutorial: no se encontro scope en ese '
        'BuildContext.',
      );
      return;
    }
    await scope.state._startTutorial(force: force);
  }

  @override
  State<EndpointTutorialHost> createState() => _EndpointTutorialHostState();
}

class _EndpointTutorialHostState extends State<EndpointTutorialHost> {
  static const String _defaultImageAssetPath = 'assets/images/void.png';

  final Map<String, GlobalKey<State<StatefulWidget>>> _targetKeys =
      <String, GlobalKey<State<StatefulWidget>>>{};
  final Map<String, String> _resolvedImagePaths = <String, String>{};
  final Random _random = Random();

  late ShowcaseView _showcaseView;
  late Map<String, EndpointTutorialStepDescriptor> _stepByTargetId;
  late Map<String, int> _stepIndexByTargetId;

  bool _isShowingTutorial = false;
  bool _didTryShowingTutorial = false;
  bool _didPersistSeen = false;

  String get _scopeName {
    return 'endpoint.tutorial.${widget.tutorialId}.v${widget.tutorialVersion}';
  }

  void _refreshStepLookups() {
    _stepByTargetId = <String, EndpointTutorialStepDescriptor>{
      for (final step in widget.steps) step.targetId: step,
    };
    _stepIndexByTargetId = <String, int>{
      for (int index = 0; index < widget.steps.length; index++)
        widget.steps[index].targetId: index,
    };
  }

  void _registerShowcase() {
    _showcaseView = ShowcaseView.register(
      scope: _scopeName,
      enableShowcase: widget.enabled,
      disableBarrierInteraction: true,
      disableMovingAnimation: true,
      disableScaleAnimation: true,
      blurValue: 0,
      onFinish: _onTutorialFinished,
      onDismiss: (_) => _onTutorialDismissed(),
    );
  }

  Future<void> _markSeenIfNeeded() async {
    if (_didPersistSeen) return;
    _didPersistSeen = true;
    await EndpointPreferencesService.markTutorialSeen(
      tutorialId: widget.tutorialId,
      version: widget.tutorialVersion,
    );
  }

  void _onTutorialFinished() {
    _isShowingTutorial = false;
    unawaited(_markSeenIfNeeded());
  }

  void _onTutorialDismissed() {
    _isShowingTutorial = false;
    unawaited(_markSeenIfNeeded());
  }

  GlobalKey<State<StatefulWidget>> _keyForTarget(String targetId) {
    return _targetKeys.putIfAbsent(
      targetId,
      () => GlobalKey<State<StatefulWidget>>(
        debugLabel: 'tutorial_target_$targetId',
      ),
    );
  }

  bool _areAllTargetsReady() {
    for (final step in widget.steps) {
      if (_keyForTarget(step.targetId).currentContext == null) {
        return false;
      }
    }

    return true;
  }

  String _resolveImageForStep(EndpointTutorialStepDescriptor step) {
    final cached = _resolvedImagePaths[step.targetId];
    if (cached != null && cached.trim().isNotEmpty) {
      return cached;
    }

    final explicit = step.imageAssetPath;
    if (explicit != null && explicit.trim().isNotEmpty) {
      _resolvedImagePaths[step.targetId] = explicit;
      return explicit;
    }

    if (widget.fallbackImagePool.isEmpty) {
      _resolvedImagePaths[step.targetId] = _defaultImageAssetPath;
      return _defaultImageAssetPath;
    }

    final resolved = widget
        .fallbackImagePool[_random.nextInt(widget.fallbackImagePool.length)];
    _resolvedImagePaths[step.targetId] = resolved;
    return resolved;
  }

  Future<void> _showTutorialIfNeeded() async {
    await _startTutorial(force: false);
  }

  Future<void> _startTutorial({required bool force}) async {
    if (!widget.enabled || widget.steps.isEmpty) return;
    if (_isShowingTutorial) return;
    if (!force && _didTryShowingTutorial) return;

    if (!force) {
      _didTryShowingTutorial = true;
    }

    if (!force) {
      final hasSeenTutorial = await EndpointPreferencesService.hasSeenTutorial(
        tutorialId: widget.tutorialId,
        version: widget.tutorialVersion,
      );
      if (!mounted || hasSeenTutorial) return;
    }

    for (int attempt = 0; attempt < 8; attempt++) {
      if (_areAllTargetsReady()) break;
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (!mounted) return;
    }

    if (!_areAllTargetsReady()) {
      if (!force) {
        _didTryShowingTutorial = false;
      }
      return;
    }

    _isShowingTutorial = true;
    _didPersistSeen = false;
    _showcaseView.startShowCase(
      widget.steps
          .map((step) => _keyForTarget(step.targetId))
          .toList(growable: false),
      delay: const Duration(milliseconds: 120),
    );
  }

  void _scheduleTutorialCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showTutorialIfNeeded());
    });
  }

  void _goPrevious() {
    _showcaseView.previous();
  }

  void _goNext({required int stepIndex}) {
    if (stepIndex >= widget.steps.length - 1) {
      _showcaseView.next(force: true);
      return;
    }

    _showcaseView.next(force: true);
  }

  void _skipTutorial() {
    _showcaseView.dismiss();
  }

  Widget _wrapTarget({required String targetId, required Widget child}) {
    final descriptor = _stepByTargetId[targetId];
    if (descriptor == null || !widget.enabled) {
      return child;
    }

    final stepIndex = _stepIndexByTargetId[targetId] ?? 0;
    final tooltipPosition = descriptor.tooltipPosition ?? TooltipPosition.top;

    return Showcase.withWidget(
      key: _keyForTarget(targetId),
      targetBorderRadius: descriptor.highlightBorderRadius,
      targetPadding: descriptor.highlightPadding,
      overlayColor: EndpointPalette.overlayScrimStrong,
      overlayOpacity: 0.88,
      disableBarrierInteraction: true,
      disableDefaultTargetGestures: true,
      tooltipPosition: tooltipPosition,
      toolTipMargin: 12,
      targetTooltipGap: 10,
      movingAnimationDuration: const Duration(milliseconds: 0),
      container: _EndpointShowcaseTooltip(
        description: descriptor.description,
        imageAssetPath: _resolveImageForStep(descriptor),
        tooltipPosition: tooltipPosition,
        stepIndex: stepIndex,
        totalSteps: widget.steps.length,
        isFirstStep: stepIndex == 0,
        previousLabel: widget.previousLabel,
        nextLabel: widget.nextLabel,
        skipLabel: widget.skipLabel,
        onPrevious: _goPrevious,
        onNext: () => _goNext(stepIndex: stepIndex),
        onSkip: _skipTutorial,
      ),
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshStepLookups();
    _registerShowcase();
    _scheduleTutorialCheck();
  }

  @override
  void didUpdateWidget(covariant EndpointTutorialHost oldWidget) {
    super.didUpdateWidget(oldWidget);

    _refreshStepLookups();

    final hasTutorialChanged = widget.tutorialId != oldWidget.tutorialId ||
        widget.tutorialVersion != oldWidget.tutorialVersion;

    final hasConfigChanged = widget.enabled != oldWidget.enabled ||
        widget.steps != oldWidget.steps ||
        widget.fallbackImagePool != oldWidget.fallbackImagePool;

    if (hasTutorialChanged || hasConfigChanged) {
      _showcaseView.unregister();
      _resolvedImagePaths.clear();
      _registerShowcase();
      _didTryShowingTutorial = false;
    }

    if (!_didTryShowingTutorial) {
      _scheduleTutorialCheck();
    }
  }

  @override
  void dispose() {
    _showcaseView.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EndpointTutorialRegistryScope(
      state: this,
      child: widget.child,
    );
  }
}

class EndpointTutorialTarget extends StatelessWidget {
  final String targetId;
  final Widget child;

  const EndpointTutorialTarget({
    super.key,
    required this.targetId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scope = _EndpointTutorialRegistryScope.maybeOf(context);
    if (scope == null) {
      return child;
    }

    return scope.state._wrapTarget(targetId: targetId, child: child);
  }
}

class _EndpointShowcaseTooltip extends StatelessWidget {
  final String description;
  final String imageAssetPath;
  final TooltipPosition tooltipPosition;
  final int stepIndex;
  final int totalSteps;
  final bool isFirstStep;
  final String previousLabel;
  final String nextLabel;
  final String skipLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _EndpointShowcaseTooltip({
    required this.description,
    required this.imageAssetPath,
    required this.tooltipPosition,
    required this.stepIndex,
    required this.totalSteps,
    required this.isFirstStep,
    required this.previousLabel,
    required this.nextLabel,
    required this.skipLabel,
    required this.onPrevious,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final width = min(MediaQuery.sizeOf(context).width - 24, 480.0);

    final panel = SizedBox(
      width: width,
      child: EndpointPanel(
        accent: EndpointPalette.infoAccent,
        backgroundColor: EndpointPalette.panelBackgroundOpaque,
        borderRadius: 18,
        glowOpacity: 0.1,
        blurRadius: 20,
        spreadRadius: 1,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 6,
                child: Image.asset(
                  imageAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: EndpointPalette.panelBackground,
                        border: Border.all(
                          color:
                              EndpointPalette.infoAccent.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: EndpointPalette.infoAccent,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            EndpointText(
              description,
              maxLines: 3,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: textSmallBold.copyWith(
                fontSize: 20,
                letterSpacing: 0.8,
                color: EndpointPalette.softForeground,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: EndpointActionButton(
                    label: previousLabel,
                    tooltip: 'Paso anterior',
                    onPressed: isFirstStep ? null : onPrevious,
                    useMarquee: false,
                    textStyle: textSmallBold.copyWith(
                      fontSize: 19,
                      letterSpacing: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: EndpointActionButton(
                    label: nextLabel,
                    tooltip: 'Siguiente paso',
                    onPressed: onNext,
                    useMarquee: false,
                    accent: EndpointPalette.infoAccent,
                    backgroundColor: EndpointPalette.blend(
                      EndpointPalette.menuButtonBackground,
                      EndpointPalette.infoAccent,
                      0.12,
                    ),
                    textStyle: textSmallBold.copyWith(
                      fontSize: 19,
                      letterSpacing: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: EndpointActionButton(
                    label: skipLabel,
                    tooltip: 'Cerrar tutorial',
                    onPressed: onSkip,
                    useMarquee: false,
                    accent: EndpointPalette.warningAccent,
                    backgroundColor: EndpointPalette.blend(
                      EndpointPalette.menuButtonBackground,
                      EndpointPalette.warningAccent,
                      0.14,
                    ),
                    textStyle: textSmallBold.copyWith(
                      fontSize: 19,
                      letterSpacing: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: EndpointText(
                '${stepIndex + 1}/$totalSteps',
                style: textSmallNumericBold.copyWith(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.84),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final pointsDown = tooltipPosition == TooltipPosition.top;
    final pointsUp = tooltipPosition == TooltipPosition.bottom;
    if (!pointsDown && !pointsUp) {
      return panel;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pointsUp)
          const Icon(
            Icons.arrow_drop_up,
            size: 36,
            color: EndpointPalette.infoAccent,
          ),
        panel,
        if (pointsDown)
          const Icon(
            Icons.arrow_drop_down,
            size: 36,
            color: EndpointPalette.infoAccent,
          ),
      ],
    );
  }
}

class _EndpointTutorialRegistryScope extends InheritedWidget {
  final _EndpointTutorialHostState state;

  const _EndpointTutorialRegistryScope({
    required this.state,
    required super.child,
  });

  static _EndpointTutorialRegistryScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_EndpointTutorialRegistryScope>();
  }

  @override
  bool updateShouldNotify(covariant _EndpointTutorialRegistryScope oldWidget) {
    return false;
  }
}
