import '_imports.dart';

class DuelStationCoinFlipAnnouncement extends StatefulWidget {
  final DuelistSide winner;
  final VoidCallback onAnimationComplete;

  const DuelStationCoinFlipAnnouncement({
    required this.winner,
    required this.onAnimationComplete,
    super.key,
  });

  @override
  State<DuelStationCoinFlipAnnouncement> createState() =>
      _DuelStationCoinFlipAnnouncementState();
}

class _DuelStationCoinFlipAnnouncementState
    extends State<DuelStationCoinFlipAnnouncement>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _coinTurns;
  late Animation<double> _winnerOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _coinTurns = Tween<double>(begin: 0, end: 10 + _winnerTurnOffset()).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _winnerOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1, curve: Curves.easeIn),
    );

    _controller.forward().then((_) => widget.onAnimationComplete());
  }

  double _winnerTurnOffset() {
    // Base icon is arrow_left.
    // Ally winner => arrow points down  (left - 90 degrees => -0.25 turns).
    // Enemy winner => arrow points up   (left + 90 degrees => +0.25 turns).
    return widget.winner == DuelistSide.ally ? -0.25 : 0.25;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winnerColor =
        widget.winner == DuelistSide.ally ? Colors.greenAccent : Colors.redAccent;
    final winnerLabel =
        widget.winner == DuelistSide.ally ? 'Allies go first' : 'Enemies go first';

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withOpacity(0.55),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Coin Flip',
                    style: TextStyle(
                      color: Colors.amber.shade200,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RotationTransition(
                    turns: _coinTurns,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber.shade200,
                            Colors.amber.shade700,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_left,
                        color: Colors.black87,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeTransition(
                    opacity: _winnerOpacity,
                    child: Text(
                      winnerLabel,
                      style: TextStyle(
                        color: winnerColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
