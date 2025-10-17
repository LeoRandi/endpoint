import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'create_character_screen.dart';
import '../../services/save_service.dart';
import '../../data/save_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  double _titleSize(BoxConstraints c) => (c.maxWidth * 0.06).clamp(28.0, 48.0);
  double _buttonWidth(BoxConstraints c) => (c.maxWidth * 0.6).clamp(220.0, 420.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final titleSize = _titleSize(c);
            final btnWidth = _buttonWidth(c);

            return Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () {}, // TODO ajustes
                    icon: const Icon(Iconsax.setting_2),
                    iconSize: 28,
                    tooltip: 'Ajustes',
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Text(
                            'ENDPOINT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: btnWidth,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CreateCharacterScreen()),
                              );
                            },
                            child: const Text('Nueva partida'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: btnWidth,
                          child: OutlinedButton(
                            onPressed: () {
                              final save = SaveService.load();
                              final has = save != null;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    has
                                        ? 'Cargando: ${save.playerName} (Nv.${save.level}) HP ${save.hp}'
                                        : 'No hay guardado',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Continuar'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: btnWidth,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Salir'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
