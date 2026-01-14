import 'package:endpoint/pages/duel_station/_imports.dart';

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
    return DuelStation();
  }
}

class BattleStation extends StatelessWidget {
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

class DuelStation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final playerDeck = DeckFactories.createSamplePlayerDeck(10);
    final enemyDeck = DeckFactories.createSampleEnemyDeck(10);

    return Scaffold(
      body: SafeArea(
        child: DuelStationPage(
          DuelStationProvider(
            {
              DuelistSide.ally: playerDeck,
              DuelistSide.enemy: enemyDeck,
            },
            DuelConfigurations(maxHandSize: 5, startingHandSize: 5),
          ),
        ),
      ),
    );
  }
}
