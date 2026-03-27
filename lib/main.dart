import 'app/_exports.dart';
import 'pages/main_menu/main_menu_page.dart';
import 'package:flutter/material.dart';

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
