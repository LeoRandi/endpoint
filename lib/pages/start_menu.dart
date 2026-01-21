import '_imports.dart';
import 'package:endpoint/pages/duel_station/_imports.dart';

class EndpointStartMenu extends StatelessWidget {
  const EndpointStartMenu({super.key});

  void _launchDemo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DuelStationDemo(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[900]!,
              Colors.grey[800]!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Text(
                'ENDPOINT',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan.shade300,
                  shadows: [
                    Shadow(
                      blurRadius: 12,
                      color: Colors.cyan.shade900.withOpacity(0.8),
                      offset: const Offset(0, 4),
                    ),
                    Shadow(
                      blurRadius: 24,
                      color: Colors.black.withOpacity(0.6),
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              // Demo Button
              ElevatedButton(
                onPressed: () => _launchDemo(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 8,
                  shadowColor: Colors.cyan.withOpacity(0.5),
                ),
                child: const Text(
                  'Demo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DuelStationDemo extends StatelessWidget {
  const DuelStationDemo({super.key});

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
