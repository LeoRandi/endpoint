import '_imports.dart';

void main() {
  runApp(const Endpoint());
}

class Endpoint extends StatelessWidget {
  const Endpoint({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Endpoint',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const EndpointStart(title: 'Flutter Demo Home Page'),
    );
  }
}

class EndpointStart extends StatefulWidget {
  const EndpointStart({super.key, required this.title});

  final String title;

  @override
  State<EndpointStart> createState() => _EndpointStartState();
}

class _EndpointStartState extends State<EndpointStart> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BattleStationPage(
        {
          BattlerSide.ally: [
            Battler('Hero', 100, 50, 20, 'assets/sprites/image_1.png',
                BattlerSide.ally),
            Battler(
                'Mage', 80, 50, 30, 'assets/sprites/image_1.png', BattlerSide.ally),
          ],
          BattlerSide.enemy: [
            Battler('Goblin', 50, 50, 10, 'assets/sprites/image_1.png',
                BattlerSide.enemy),
            Battler('Orc', 120, 50, 15, 'assets/sprites/image_1.png',
                BattlerSide.enemy),
          ],
        },
      ),
    );
  }
}
