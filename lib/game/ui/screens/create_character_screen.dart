import 'package:flutter/material.dart';
import '../widgets/stat_counter.dart';

import '../../services/save_service.dart';
import '../../data/save_data.dart';
import '../../domain/player.dart';
import '../../domain/stats.dart';
import '../../domain/floor_grid.dart';
import 'floor_screen.dart';
import '../../services/grid_generator_service.dart';

import 'dart:math' as math;



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

  void _applyChange({
    required int current,
    required int proposed,
    required void Function(int v) setter,
  }) {
    // Si intenta subir y no hay puntos, ignora
    if (proposed > current) {
      final delta = proposed - current;
      if (_poolLeft - delta < 0) return; // excede pool → bloquear
    }
    setState(() => setter(proposed.clamp(minStat, maxStat)));
  }

  void _setAttack(int v)       => _applyChange(current: _attack,       proposed: v, setter: (x) => _attack = x);
  void _setDefense(int v)      => _applyChange(current: _defense,      proposed: v, setter: (x) => _defense = x);
  void _setSpeed(int v)        => _applyChange(current: _speed,        proposed: v, setter: (x) => _speed = x);
  void _setConstitution(int v) => _applyChange(current: _constitution, proposed: v, setter: (x) => _constitution = x);

  bool _incEnabled(int current) => _poolLeft > 0 && current < maxStat;
  bool _decEnabled(int current) => current > minStat;

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
                          StatCounter(
                            label: 'Ataque',
                            value: _attack,
                            min: minStat,
                            max: maxStat,
                            onChanged: _setAttack,
                            incEnabled: _incEnabled(_attack),
                            decEnabled: _decEnabled(_attack),
                          ),
                          StatCounter(
                            label: 'Defensa',
                            value: _defense,
                            min: minStat,
                            max: maxStat,
                            onChanged: _setDefense,
                            incEnabled: _incEnabled(_defense),
                            decEnabled: _decEnabled(_defense),
                          ),
                          StatCounter(
                            label: 'Velocidad',
                            value: _speed,
                            min: minStat,
                            max: maxStat,
                            onChanged: _setSpeed,
                            incEnabled: _incEnabled(_speed),
                            decEnabled: _decEnabled(_speed),
                          ),
                          StatCounter(
                            label: 'Constitución',
                            value: _constitution,
                            min: minStat,
                            max: maxStat,
                            onChanged: _setConstitution,
                            incEnabled: _incEnabled(_constitution),
                            decEnabled: _decEnabled(_constitution),
                            hintText: '→ HP Máx: ${_maxHpFromCon(_constitution)}',
                          ),
                          StatCounter(
                            label: 'Flow',
                            value: _flow,
                            min: minStat,
                            max: maxStat,
                            onChanged: (_) {},
                            incEnabled: false,
                            decEnabled: false,
                            hintText: '(no editable)',
                          ),

                        ],
                      ),

                      // (El contador y el botón ahora están fijos abajo)
                      const SizedBox(height: 100), // respiro para que no tape el footer al hacer scroll
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // ✅ Footer sticky con puntos + botón
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container
        (
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Puntos disponibles
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Puntos disponibles: ${_poolLeft.clamp(0, poolMax)} / $poolMax',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _overBudget ? Theme.of(context).colorScheme.error : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Botón Ir a la batalla
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _overBudget
                    ? null
                    : () async {
                        final name = _nameCtrl.text.trim().isEmpty ? 'Héroe' : _nameCtrl.text.trim();
                        final maxHp = SaveData.hpFromCon(_constitution);

                        final save = SaveData(
                          version: 1,
                          playerName: name,
                          level: 1,
                          hp: maxHp,
                          maxHp: maxHp,
                          attack: _attack,
                          defense: _defense,
                          speed: _speed,
                          constitution: _constitution,
                          flow: 2,
                        );
                        await SaveService.save(save);

                        final player = Player(
                          name: name,
                          stats: Stats(maxHp: maxHp, attack: _attack, defense: _defense, speed: _speed),
                        );

                        if (context.mounted) {
                          // 1) Seed reproducible
                          final seed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
                          final rng = math.Random(seed);

                          // 2) Densidades controladas
                          double randRange(double a, double b) => a + rng.nextDouble() * (b - a);
                          // redondeo ligero para evitar sorpresas de coma flotante al depurar
                          double tidy(double x) => double.parse(x.toStringAsFixed(3));

                          final roomDensity = tidy(randRange(0.25, 0.45));
                          final enemyDensity = tidy(randRange(0.05, 0.125));

                          // 3) Opciones de generación con esas densidades
                          final opts = GridGenOptions(
                            width: 33,
                            height: 25,
                            roomDensity: roomDensity,
                            enemyDensity: enemyDensity,
                            minRoomW: 4,
                            minRoomH: 5,
                            maxAspectRatio: 4.0,
                            roomPlacementTries: 300,
                          );

                          // 4) Generar grid con la seed
                          final grid = FloorGrid.fromGenerator(opts, seed: seed);

                          // 5) Navegar
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FloorScreen(player: player, grid: grid),
                            ),
                          );
                        }
                      },

                  child: const Text('Ir a la batalla'),
                ),
              ),
            ],
          ),
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
