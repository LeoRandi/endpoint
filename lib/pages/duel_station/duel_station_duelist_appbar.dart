import "_imports.dart";

class DuelStationDuelistAppBar extends StatelessWidget {
  final Battler? enemyBattler;
  final Battler? allyBattler;

  const DuelStationDuelistAppBar({
    this.enemyBattler,
    this.allyBattler,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Color.fromARGB(APPBAR_BACKGROUND_ALPHA, 255, 255, 255),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: APPBAR_HORIZONTAL_PADDING, vertical: APPBAR_VERTICAL_PADDING),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Enemy side (left) with red background
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(APPBAR_BACKGROUND_OPACITY),
                  borderRadius: BorderRadius.circular(APPBAR_BORDER_RADIUS),
                ),
                padding: const EdgeInsets.symmetric(horizontal: APPBAR_HORIZONTAL_PADDING, vertical: APPBAR_VERTICAL_PADDING),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Enemy image
                    Image.asset(
                      enemyBattler?.imagePath ?? "assets/sprites/unknown.png",
                      width: APPBAR_BATTLER_IMAGE_WIDTH,
                      height: APPBAR_BATTLER_IMAGE_HEIGHT,
                    ),
                    const SizedBox(width: APPBAR_IMAGE_SPACING),
                    // Enemy stats
                    Expanded(
                      child: DuelStationBattlerStatsWidget(battler: enemyBattler),
                    ),
                  ],
                ),
              ),
            ),
            // Vertical divider
            Container(
              width: APPBAR_DIVIDER_WIDTH,
              height: APPBAR_DIVIDER_HEIGHT,
              color: Colors.grey[600],
              margin: const EdgeInsets.symmetric(horizontal: APPBAR_IMAGE_SPACING),
            ),
            // Ally side (right) with green background
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(APPBAR_BACKGROUND_OPACITY),
                  borderRadius: BorderRadius.circular(APPBAR_BORDER_RADIUS),
                ),
                padding: const EdgeInsets.symmetric(horizontal: APPBAR_HORIZONTAL_PADDING, vertical: APPBAR_VERTICAL_PADDING),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Ally stats
                    Expanded(
                      child: DuelStationBattlerStatsWidget(battler: allyBattler),
                    ),
                    const SizedBox(width: APPBAR_IMAGE_SPACING),
                    // Ally image
                    Image.asset(
                      allyBattler?.imagePath ?? "assets/sprites/unknown.png",
                      width: APPBAR_BATTLER_IMAGE_WIDTH,
                      height: APPBAR_BATTLER_IMAGE_HEIGHT,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
