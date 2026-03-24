import '_imports.dart';

void main() {
  runApp(const DeathAtSunriseApp());
}

class DeathAtSunriseApp extends StatelessWidget {
  const DeathAtSunriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Death at Sunrise',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5AF78E),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF030807),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MainMenuPage(),
    );
  }
}

class Endpoint extends DeathAtSunriseApp {
  const Endpoint({super.key});
}
