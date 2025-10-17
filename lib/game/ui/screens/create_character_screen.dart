import 'package:flutter/material.dart';
import '../widgets/stat_counter.dart';

class CreateCharacterScreen extends StatefulWidget {
  const CreateCharacterScreen({super.key});

  @override
  State<CreateCharacterScreen> createState() => _CreateCharacterScreenState();
}

class _CreateCharacterScreenState extends State<CreateCharacterScreen> {
  final _nameCtrl = TextEditingController(text: 'Héroe');

  // Stats base alineados con tu dominio: maxHp, attack, defense, speed
  int _maxHp = 30;
  int _attack = 8;
  int _defense = 3;
  int _speed = 5;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  double _titleSize(BoxConstraints c) => (c.maxWidth * 0.05).clamp(22.0, 38.0);
  double _sectionTitleSize(BoxConstraints c) => (c.maxWidth * 0.035).clamp(16.0, 22.0);
  double _panelWidth(BoxConstraints c) => (c.maxWidth * 0.9).clamp(300.0, 780.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear personaje')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final titleSize = _titleSize(c);
            final sectionSize = _sectionTitleSize(c);
            final panelWidth = _panelWidth(c);

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: panelWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título grande centrado
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'CREACIÓN DE PERSONAJE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      // Selector de nombre
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Nombre', style: TextStyle(fontSize: sectionSize, fontWeight: FontWeight.w600)),
                      ),
                      TextField(
                        controller: _nameCtrl,
                        maxLength: 20,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Introduce un nombre',
                        ),
                      ),

                      const SizedBox(height: 8),
                      // Selector de stats
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Atributos', style: TextStyle(fontSize: sectionSize, fontWeight: FontWeight.w600)),
                      ),
                      _StatsGrid(
                        children: [
                          StatCounter(
                            label: 'HP Máx',
                            value: _maxHp,
                            onChanged: (v) => setState(() => _maxHp = v.clamp(10, 999)),
                            step: 5, // HP sube/baja de 5 en 5
                            min: 10,
                            max: 999,
                          ),
                          StatCounter(
                            label: 'Ataque',
                            value: _attack,
                            onChanged: (v) => setState(() => _attack = v.clamp(1, 99)),
                            min: 1,
                            max: 99,
                          ),
                          StatCounter(
                            label: 'Defensa',
                            value: _defense,
                            onChanged: (v) => setState(() => _defense = v.clamp(0, 99)),
                            min: 0,
                            max: 99,
                          ),
                          StatCounter(
                            label: 'Velocidad',
                            value: _speed,
                            onChanged: (v) => setState(() => _speed = v.clamp(1, 99)),
                            min: 1,
                            max: 99,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      // Botón "Ir a la batalla" (sin funcionalidad de momento)
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ir a la batalla — por implementar')),
                            );
                          },
                          child: const Text('Ir a la batalla'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Grid responsive de stats: 1 columna en pantallas estrechas, 2 en anchas
class _StatsGrid extends StatelessWidget {
  final List<Widget> children;
  const _StatsGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final twoCols = c.maxWidth >= 520;
      return GridView.count(
        crossAxisCount: twoCols ? 2 : 1,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: twoCols ? 3.6 : 3.2,
        children: children,
      );
    });
  }
}
