import 'dart:math';
import '_imports.dart';

class DuelStationParty extends StatefulWidget {
  final List<Battler?> battlers; // Up to 5 battlers, null for empty slots
  final DuelistSide side;
  final bool isEnemySide;
  final DuelStationProvider provider;

  DuelStationParty({
    required this.battlers,
    required this.side,
    required this.isEnemySide,
    required this.provider,
    super.key,
  });

  @override
  State<DuelStationParty> createState() => _DuelStationPartyState();
}

class _DuelStationPartyState extends State<DuelStationParty>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void animateRotation() {
    _rotationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // Pentagon layout positions (5 slots arranged in a pentagon)
    final positions = _calculatePentagonPositions();

    return SizedBox(
      width: PARTY_CONTAINER_WIDTH,
      height: PARTY_CONTAINER_HEIGHT,
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          // Rotation angle: 72° per slot (360° / 5)
          // Enemy rotates counter-clockwise (negative), Ally rotates clockwise (positive)
          final rotationAngle = _rotationAnimation.value * 72 * (widget.isEnemySide ? -1 : 1);
          final radianAngle = rotationAngle * pi / 180;

          // Rotation center is at the pentagon's center point
          final rotationOrigin = Offset(PENTAGON_CENTER_X, PENTAGON_CENTER_Y);

          return Transform.rotate(
            angle: radianAngle,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Draw pentagon outline
                CustomPaint(
                  size: Size(PARTY_CONTAINER_WIDTH, PARTY_CONTAINER_HEIGHT),
                  painter: PentagonPainter(
                    color: widget.isEnemySide
                        ? Colors.red.withOpacity(0.3)
                        : Colors.green.withOpacity(0.3),
                    isEnemySide: widget.isEnemySide,
                  ),
                ),
                // Place battler slots at pentagon positions (non-active first, so they're drawn behind)
                for (int i = 0; i < 5; i++)
                  if (i != DuelStationProvider.ACTIVE_BATTLER_SLOT)
                    Positioned(
                      left: positions[i]['x'] as double,
                      top: positions[i]['y'] as double,
                      child: Transform.translate(
                        offset: Offset(-BATTLER_SLOT_OFFSET_X,
                            -BATTLER_SLOT_OFFSET_Y), // Center the card
                        child: DuelStationBattlerSlot(
                          battler: _getBattlerAtSlot(i),
                          slotIndex: i,
                          side: widget.side,
                          isActive: false,
                        ),
                      ),
                    ),
                // Place active battler last so it's drawn on top
                Positioned(
                  left: positions[DuelStationProvider.ACTIVE_BATTLER_SLOT]['x']
                      as double,
                  top: positions[DuelStationProvider.ACTIVE_BATTLER_SLOT]['y']
                      as double,
                  child: Transform.translate(
                    offset: Offset(
                      -BATTLER_SLOT_OFFSET_X * ACTIVE_BATTLER_SCALE,
                      -BATTLER_SLOT_OFFSET_Y * ACTIVE_BATTLER_SCALE,
                    ), // Center the larger card
                    child: DuelStationBattlerSlot(
                      battler: _getBattlerAtSlot(
                          DuelStationProvider.ACTIVE_BATTLER_SLOT),
                      slotIndex: DuelStationProvider.ACTIVE_BATTLER_SLOT,
                      side: widget.side,
                      isActive: true,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Get battler for a slot, accounting for active battler rotation offset
  Battler? _getBattlerAtSlot(int slotIndex) {
    // Get current active battler index from provider
    final activeIndex = widget.provider.getActiveBattlerSlotIndex(widget.side);

    // Map slot index to battler index, starting from active slot and going clockwise
    final battlerIndex = (slotIndex - DuelStationProvider.ACTIVE_BATTLER_SLOT + activeIndex + 5) % 5;
    return battlerIndex < widget.battlers.length ? widget.battlers[battlerIndex] : null;
  }

  List<Map<String, double>> _calculatePentagonPositions() {
    // Calculate 5 pentagon vertices dynamically
    final List<Map<String, double>> positions = [];
    final angleOffset = widget.isEnemySide
        ? 0
        : 180; // Flip ally pentagon by 180 degrees
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90 + angleOffset) *
          pi /
          180; // 72° per vertex, starting from top
      final x = PENTAGON_CENTER_X + PENTAGON_RADIUS * cos(angle);
      final y = PENTAGON_CENTER_Y + PENTAGON_RADIUS * sin(angle);
      positions.add({'x': x, 'y': y});
    }
    return positions;
  }
}

class PentagonPainter extends CustomPainter {
  final Color color;
  final bool isEnemySide;

  PentagonPainter({required this.color, this.isEnemySide = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final angleOffset = isEnemySide ? 0 : 180; // Flip ally pentagon by 180 degrees
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90 + angleOffset) * pi / 180;
      final x = PENTAGON_CENTER_X + PENTAGON_RADIUS * cos(angle);
      final y = PENTAGON_CENTER_Y + PENTAGON_RADIUS * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(PentagonPainter oldDelegate) => oldDelegate.color != color || oldDelegate.isEnemySide != isEnemySide;
}

class DuelStationBattlerSlot extends StatelessWidget {
  final Battler? battler;
  final int slotIndex;
  final DuelistSide side;
  final bool isActive;

  DuelStationBattlerSlot({
    required this.battler,
    required this.slotIndex,
    required this.side,
    this.isActive = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final slotWidth = isActive ? BATTLER_SLOT_WIDTH * ACTIVE_BATTLER_SCALE : BATTLER_SLOT_WIDTH;
    final slotHeight = isActive ? BATTLER_SLOT_HEIGHT * ACTIVE_BATTLER_SCALE : BATTLER_SLOT_HEIGHT;
    final borderWidth = isActive ? ACTIVE_BATTLER_BORDER_WIDTH : BATTLER_SLOT_BORDER_WIDTH;
    final borderColor = isActive
        ? (side == DuelistSide.ally ? Colors.green : Colors.red)
        : (battler != null ? Colors.blue : Colors.grey);

    return DragTarget<BattleCard>(
      onAccept: (card) {
        // Handle drop - this will be managed by parent provider
        print('Dropped card on slot $slotIndex for $side');
      },
      onWillAccept: (card) => side == DuelistSide.ally, // Only ally side can accept drops
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: slotWidth,
          height: slotHeight,
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
            borderRadius: BorderRadius.circular(3),
            color: candidateData.isNotEmpty
                ? Colors.yellow.withOpacity(0.5)
                : (battler != null ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.1)),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: (side == DuelistSide.ally ? Colors.green : Colors.red).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: battler != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        battler!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: isActive ? BATTLER_NAME_FONT_SIZE * 1.2 : BATTLER_NAME_FONT_SIZE, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'HP:${battler!.health}',
                        style: TextStyle(fontSize: isActive ? BATTLER_HP_FONT_SIZE * 1.2 : BATTLER_HP_FONT_SIZE),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Text(
                    '—',
                    style: TextStyle(
                      fontSize: BATTLER_EMPTY_SLOT_FONT_SIZE,
                      color: side == DuelistSide.ally ? Colors.grey : Colors.transparent,
                    ),
                  ),
                ),
        );
      },
    );
  }
}
