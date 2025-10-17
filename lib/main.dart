import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'game/ui/screens/home_screen.dart';
import 'game/services/save_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await SaveService.init();

  runApp(const EndpointApp());
}

class EndpointApp extends StatelessWidget {
  const EndpointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Endpoint',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
