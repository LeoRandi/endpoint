import '_imports.dart';

class DuelStationTurnAnnouncement extends StatefulWidget {
  final int turnNumber;
  final VoidCallback onAnimationComplete;

  const DuelStationTurnAnnouncement({
    required this.turnNumber,
    required this.onAnimationComplete,
    super.key,
  });

  @override
  State<DuelStationTurnAnnouncement> createState() => _DuelStationTurnAnnouncementState();
}

class _DuelStationTurnAnnouncementState extends State<DuelStationTurnAnnouncement>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    // Slide animation: enters from left, exits to right
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: const Offset(1, 0),
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic));

    // Opacity: fade in, stay, fade out
    _opacityAnimation = TweenSequence<double>(
      [
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: 1),
          weight: 10, // First 10% of duration for fade in
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1, end: 1),
          weight: 80, // Middle 80% stays opaque
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1, end: 0),
          weight: 10, // Last 10% for fade out
        ),
      ],
    ).animate(_animationController);

    // Start animation and schedule completion
    _animationController.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TURN_ANNOUNCEMENT_HORIZONTAL_PADDING,
                    vertical: TURN_ANNOUNCEMENT_VERTICAL_PADDING,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(TURN_ANNOUNCEMENT_BORDER_RADIUS),
                    border: Border.all(
                      color: Colors.cyan.shade400,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    'Turn ${widget.turnNumber}',
                    style: TextStyle(
                      fontSize: TURN_ANNOUNCEMENT_FONT_SIZE,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: TURN_ANNOUNCEMENT_SHADOW_BLUR,
                          color: Colors.cyan.shade900.withOpacity(0.8),
                          offset: const Offset(0, 2),
                        ),
                        Shadow(
                          blurRadius: TURN_ANNOUNCEMENT_SHADOW_BLUR * 2,
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
