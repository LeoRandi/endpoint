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
    final playableHero = BattlerFactories.hero();
    global.setPlayingBattler(playableHero);

    final allies = [
      playableHero,
      BattlerFactories.heroMage(),
      BattlerFactories.heroCleric(),
      BattlerFactories.heroRogue(),
    ];

    final enemies = [
      BattlerFactories.goblin(),
      BattlerFactories.goblinTank(),
      BattlerFactories.goblinArcher(),
      BattlerFactories.trashGoblin(),
    ];

    return Scaffold(
      body: SafeArea(
        child: BattleStationPage(
          {
            BattlerSide.ally: allies,
            BattlerSide.enemy: enemies,
          },
        ),
      ),
    );
  }
}
