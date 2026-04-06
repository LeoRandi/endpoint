import 'app/_exports.dart';
import 'pages/main_menu/main_menu_page.dart';
import 'services/_exports.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialSettings =
      await EndpointPreferencesService.loadSettingsSnapshot();
  final initialRunSnapshot =
      await EndpointPreferencesService.loadCurrentRunSnapshot();
  runApp(
    EndpointApp(
      initialSettings: initialSettings,
      initialRunSnapshot: initialRunSnapshot,
    ),
  );
}

class EndpointApp extends StatelessWidget {
  final EndpointSettingsSnapshot initialSettings;
  final EndpointCurrentRunSnapshot? initialRunSnapshot;

  const EndpointApp({
    super.key,
    this.initialSettings = const EndpointSettingsSnapshot.defaults(),
    this.initialRunSnapshot,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EndpointStrings.appTitle,
      theme: EndpointTheme.build(),
      debugShowCheckedModeBanner: false,
      home: MainMenuPage(
        initialSettings: initialSettings,
        initialRunSnapshot: initialRunSnapshot,
      ),
    );
  }
}

class Endpoint extends EndpointApp {
  const Endpoint({
    super.key,
    super.initialSettings,
    super.initialRunSnapshot,
  });
}
