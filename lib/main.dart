import 'package:endpoint/pages/start_menu.dart';
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
      home: const EndpointStartMenu(),
    );
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
