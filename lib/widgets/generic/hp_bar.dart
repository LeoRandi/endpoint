import '_imports.dart';

class HpBar extends StatelessWidget {
  final int currentHp;
  final int maxHp;

  const HpBar({super.key, required this.currentHp, required this.maxHp});

  @override
  Widget build(BuildContext context) {
    double hpPercentage = currentHp / maxHp;
    return Stack(
      children: [
        Container(
          width: 100,
          height: 20,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            color: Colors.red,
          ),
        ),
        Container(
          width: 100 * hpPercentage,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.green,
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Text('$currentHp / $maxHp',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ),
      ],
    );
  }
}
