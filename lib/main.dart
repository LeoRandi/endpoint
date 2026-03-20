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
