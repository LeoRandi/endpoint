import 'package:flutter/material.dart';
import '../widgets/stat_counter.dart';

class CreateCharacterScreen extends StatefulWidget {
  const CreateCharacterScreen({super.key});

  @override
  State<CreateCharacterScreen> createState() => _CreateCharacterScreenState();
}

class _CreateCharacterScreenState extends State<CreateCharacterScreen> {
  final _nameCtrl = TextEditingController(text: 'Héroe');

  // Reglas
  static const int minStat = 2;
  static const int maxStat = 8;
  static const int poolMax = 10;

  // Stats seleccionables (empiezan en 2)
  int _attack = minStat;
  int _defense = minStat;
  int _speed = minStat;
  int _constitution = minStat;

  // Flow: visible pero no editable (también empieza en 2)
  final int _flow = minStat;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // Responsive helpers
  double _titleSize(BoxConstraints c) => (c.maxWidth * 0.05).clamp(22.0, 38.0);
  double _sectionTitleSize(BoxConstraints c) => (c.maxWidth * 0.035).clamp(16.0, 22.0);
  double _panelWidth(BoxConstraints c) => (c.maxWidth * 0.9).clamp(300.0, 780.0);

  // Cálculos
  int get _baseSum => minStat * 4; // 4 stats editables: atk/def/spd/con
  int get _currentSum => _attack + _defense + _speed + _constitution;
  int get _spent => _currentSum - _baseSum; // puntos gastados de la pool
  int get _poolLeft => poolMax - _spent;

  int _maxHpFromCon(int con) {
    // maxHp = (con * 3) + (con/3) [entero]
    return (con * 3) + (con ~/ 3);
  }

  bool get _overBudget => _poolLeft < 0;

  void _setAttack(int v) => setState(() => _attack = v.clamp(minStat, maxStat));
  void _setDefense(int v) => setState(() => _defense = v.clamp(minStat, maxStat));
  void _setSpeed(int v) => setState(() => _speed = v.clamp(minStat, maxStat));
  void _setConstitution(int v) => setState(() => _constitution = v.clamp(minStat, maxStat));

  bool _canInc(int current) => _poolLeft > 0 && current < maxStat;
  bool _canDec(int current) => current > minStat;

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
                      // Título
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

                      // Pool de puntos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Puntos disponibles: ${_poolLeft.clamp(0, poolMax)} / $poolMax',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _overBudget ? Theme.of(context).colorScheme.error : null,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Nombre
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

                      // Atributos
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Atributos', style: TextStyle(fontSize: sectionSize, fontWeight: FontWeight.w600)),
                      ),
                      _StatsGrid(
                        children: [
                          // Attack
                          StatCounter(
                            label: 'Ataque',
                            value: _attack,
                            min: minStat,
                            max: maxStat,
                            onChanged: (v) => _setAttack(v),
                            enabled: _canInc(_attack) || _canDec(_attack),
                          ),

                          // Defense
                          StatCounter(
                            label: 'Defensa',
                            value: _defense,
                            min: minStat,
                            max: maxStat,
                            onChanged: (v) => _setDefense(v),
                            enabled: _canInc(_defense) || _canDec(_defense),
                          ),

                          // Speed
                          StatCounter(
                            label: 'Velocidad',
                            value: _speed,
                            min: minStat,
                            max: maxStat,
                            onChanged: (v) => _setSpeed(v),
                            enabled: _canInc(_speed) || _canDec(_speed),
                          ),

                          // Constitution (con hint de HP)
                          StatCounter(
                            label: 'Constitución',
                            value: _constitution,
                            min: minStat,
                            max: maxStat,
                            onChanged: (v) => _setConstitution(v),
                            enabled: _canInc(_constitution) || _canDec(_constitution),
                            hintText: '→ HP Máx: ${_maxHpFromCon(_constitution)}',
                          ),

                          // Flow (solo visible)
                          StatCounter(
                            label: 'Flow',
                            value: _flow,
                            min: minStat,
                            max: maxStat,
                            onChanged: (_) {},
                            enabled: false, // deshabilitado
                            hintText: '(no editable)',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Ir a la batalla (deshabilitar si over budget)
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _overBudget
                              ? null
                              : () {
                                  // Por ahora sin navegar. Solo feedback.
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
