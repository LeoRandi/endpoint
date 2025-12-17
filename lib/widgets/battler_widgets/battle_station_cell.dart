import '_imports.dart';

class BattleStationCell extends StatelessWidget {
  final GridObject gridObject;
  final int size;
  final VoidCallback? onTap;

  const BattleStationCell({
    Key? key,
    required this.gridObject,
    this.size = 24,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size.toDouble(),
        height: size.toDouble(),
        child: gridObject.getGridObjectWidget(size),
      ),
    );
  }
}
