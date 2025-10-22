import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/floor_grid.dart';
import '../../domain/player.dart';

class FloorScreen extends StatefulWidget {
  final Player player;
  final FloorGrid grid;
  const FloorScreen({super.key, required this.player, required this.grid});

  @override
  State<FloorScreen> createState() => _FloorScreenState();
}

class _FloorScreenState extends State<FloorScreen> {
  final _tc = TransformationController();
  bool _zHeld = false;
  double _scale = 1.0;
  static const double _minScale = 0.5;
  static const double _maxScale = 6.0;

  void _applyScale(double s) {
    _scale = s.clamp(_minScale, _maxScale);
    _tc.value = Matrix4.identity()..scale(_scale);
    setState(() {});
  }

  String _cellEmoji(CellType t) => switch (t) {
        CellType.player => '🗡️',
        CellType.wall => '🧱',
        CellType.enemy => '💀',
        CellType.empty => '·',
      };

  @override
  Widget build(BuildContext context) {

    // Área disponible dentro del body (LayoutBuilder te da ancho/alto reales)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Piso 1'),
        shape: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final rows = widget.grid.rows;
            final cols = widget.grid.cols;

            // Márgenes y paddings
            const double outerMargin = 12;
            const double framePad = 8;
            const double gap = 4;
            const double minTile = 14; // evita círculos por borderRadius

            // Área disponible (resta márgenes exteriores)
            final availW = (c.maxWidth - outerMargin * 2).clamp(0, double.infinity);
            final availH = (c.maxHeight - outerMargin * 2).clamp(0, double.infinity);

            // Cálculo base del tile
            double tile = math.min(
              (availW - framePad * 2 - gap * (cols - 1)) / cols,
              (availH - framePad * 2 - gap * (rows - 1)) / rows,
            );
            if (!tile.isFinite) tile = 0;
            tile = tile.floorToDouble();
            if (tile < minTile) tile = minTile;

            // Tamaño final del grid (tiles + gaps + padding)
            final gridW = (tile * cols) + gap * (cols - 1) + framePad * 2;
            final gridH = (tile * rows) + gap * (rows - 1) + framePad * 2;

            // Localiza jugador
            int pr = -1, pc = -1;
            for (var r = 0; r < rows; r++) {
              for (var cc = 0; cc < cols; cc++) {
                if (widget.grid.cell(r, cc) == CellType.player) {
                  pr = r; pc = cc; break;
                }
              }
              if (pr != -1) break;
            }

            // Posición del centro del jugador en coords del child (content)
            double playerCx, playerCy;
            if (pr >= 0 && pc >= 0) {
              playerCx = outerMargin + framePad + pc * (tile + gap) + tile / 2;
              playerCy = outerMargin + framePad + pr * (tile + gap) + tile / 2;
            } else {
              // fallback: centro del grid
              playerCx = outerMargin + framePad + gridW / 2 - framePad;
              playerCy = outerMargin + framePad + gridH / 2 - framePad;
            }

            // Construcción de celdas con colores pastel
            Color cellBg(CellType t) {
              final base = Theme.of(context).colorScheme;
              switch (t) {
                case CellType.wall:
                  return base.outlineVariant.withOpacity(0.18); // gris suave
                case CellType.enemy:
                  return Colors.redAccent.withOpacity(0.16);
                case CellType.player:
                  return Colors.lightBlueAccent.withOpacity(0.18);
                case CellType.empty:
                  return Colors.transparent;
              }
            }

            String cellEmoji(CellType t) => switch (t) {
                  CellType.player => '🗡️',
                  CellType.wall   => '🧱',
                  CellType.enemy  => '💀',
                  CellType.empty  => '·',
                };

            final radius = math.min(6.0, tile / 4);

            Widget buildRow(int r) {
              final children = <Widget>[];
              for (var c2 = 0; c2 < cols; c2++) {
                final t = widget.grid.cell(r, c2);
                children.add(Container(
                  width: tile,
                  height: tile,
                  decoration: BoxDecoration(
                    color: cellBg(t),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(cellEmoji(t), textAlign: TextAlign.center),
                  ),
                ));
                if (c2 < cols - 1) children.add(const SizedBox(width: gap));
              }
              return Row(mainAxisSize: MainAxisSize.min, children: children);
            }

            final frame = Container(
              width: gridW,
              height: gridH,
              padding: const EdgeInsets.all(framePad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var r = 0; r < rows; r++) ...[
                    buildRow(r),
                    if (r < rows - 1) const SizedBox(height: gap),
                  ],
                ],
              ),
            );

            final content = Center(
              child: Padding(
                padding: const EdgeInsets.all(outerMargin),
                child: frame,
              ),
            );

            // Auto-zoom y centrado en el jugador la primera vez
            // (1) escala inicial agradable
            const double initialScale = 1.6;
            // (2) centro del viewport (área del body)
            final viewportCx = c.maxWidth / 2;
            final viewportCy = c.maxHeight / 2;
            // (3) offset tal que: playerCenter*scale + offset = viewportCenter
            final tx = viewportCx - playerCx * initialScale;
            final ty = viewportCy - playerCy * initialScale;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // setImmediate (no animamos aquí para mantenerlo simple)
              if (_tc.value.storage[0] == 1.0 && _tc.value.storage[5] == 1.0) {
                _tc.value = Matrix4.identity()
                  ..translate(tx, ty)
                  ..scale(initialScale);
                _scale = initialScale;
                setState(() {});
              }
            });

            return Focus(
              autofocus: true,
              onKey: (node, RawKeyEvent evt) {
                if (evt.logicalKey != LogicalKeyboardKey.keyZ) return KeyEventResult.ignored;
                if (evt is RawKeyDownEvent) _zHeld = true;
                if (evt is RawKeyUpEvent) _zHeld = false;
                return KeyEventResult.handled;
              },
              child: Listener(
                onPointerSignal: (PointerSignalEvent sig) {
                  if (!_zHeld || sig is! PointerScrollEvent) return;
                  final factor = math.pow(1.0018, -sig.scrollDelta.dy);
                  final newScale = (_scale * factor).clamp(_minScale, _maxScale);
                  // mantenemos el centro actual; simple
                  _tc.value = Matrix4.identity()
                    ..translate(tx, ty)
                    ..scale(newScale as double);
                  _scale = newScale.toDouble();
                  setState(() {});
                },
                child: InteractiveViewer(
                  transformationController: _tc,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  panEnabled: true,
                  scaleEnabled: true,
                  boundaryMargin: const EdgeInsets.all(200),
                  child: content,
                ),
              ),
            );
          },

        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final isCompact = c.maxWidth <= 480;
              if (isCompact) {
                final ctrl = PageController(viewportFraction: 0.9);
                return SizedBox(
                  height: 44,
                  child: PageView(
                    controller: ctrl,
                    physics: const PageScrollPhysics(),
                    children: [
                      Row(children: [
                        Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Equipo'))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Inventario'))),
                      ]),
                      Row(children: [
                        Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Skills'))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Quests'))),
                      ]),
                      Row(children: [
                        Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Más'))),
                        const Spacer(),
                      ]),
                    ],
                  ),
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Equipo'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Inventario'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Skills'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Quests'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Más'))),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
