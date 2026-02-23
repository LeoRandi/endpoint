import '_imports.dart';

class DuelStationBattlerLineup extends StatelessWidget {
  final List<Battler?> battlers;
  final DuelistSide side;

  const DuelStationBattlerLineup({
    required this.battlers,
    required this.side,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (int i = 0; i < battlers.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DuelStationBattlerLineupCard(
                  battler: battlers[i],
                  side: side,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DuelStationBattlerLineupCard extends StatelessWidget {
  final Battler? battler;
  final DuelistSide side;

  const DuelStationBattlerLineupCard({
    required this.battler,
    required this.side,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sideColor = side == DuelistSide.ally ? Colors.green : Colors.red;

    return Container(
      width: 90,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: sideColor.withOpacity(0.7), width: 2),
        color: sideColor.withOpacity(0.15),
      ),
      child: battler == null
          ? Center(
              child: Text(
                'Empty',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    child: Image.asset(
                      battler!.imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black26,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Column(
                    children: [
                      Text(
                        battler!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${battler!.health}/${battler!.maxHealth}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
