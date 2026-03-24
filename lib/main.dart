import '_imports.dart';

void main() {
  runApp(const EndpointApp());
}

class EndpointApp extends StatelessWidget {
  const EndpointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EndpointStrings.appTitle,
      theme: EndpointTheme.build(),
      debugShowCheckedModeBanner: false,
      home: const MainMenuPage(),
    );
  }
}

class Endpoint extends EndpointApp {
  const Endpoint({super.key});
}
