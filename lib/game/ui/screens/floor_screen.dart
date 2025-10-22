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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: Text('x${_scale.toStringAsFixed(2)}')),
          ),
        ],
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

            // Área disponible (resta márgenes exteriores)
            final availW = (c.maxWidth - outerMargin * 2).clamp(0, double.infinity);
            final availH = (c.maxHeight - outerMargin * 2).clamp(0, double.infinity);

            // Área útil para tiles dentro del marco (sin contar gaps entre tiles)
            final innerW = (availW - framePad * 2 - gap * (cols - 1)).clamp(0, double.infinity);
            final innerH = (availH - framePad * 2 - gap * (rows - 1)).clamp(0, double.infinity);

            // Tamaño del tile: mínimo entre ancho/alto, y “snap” a píxel
            double tile = math.min(innerW / cols, innerH / rows);
            tile = tile.isFinite ? tile.floorToDouble() : 0;

            // Tamaño final del grid (tiles + gaps + padding)
            final gridW = (tile * cols) + gap * (cols - 1) + framePad * 2;
            final gridH = (tile * rows) + gap * (rows - 1) + framePad * 2;

            Widget buildRow(int r) {
              final children = <Widget>[];
              for (var c2 = 0; c2 < cols; c2++) {
                final t = widget.grid.cell(r, c2);
                children.add(Container(
                  width: tile,
                  height: tile,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_cellEmoji(t), textAlign: TextAlign.center),
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
                  _applyScale(_scale * factor);
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
          child: Row(
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
          ),
        ),
      ),
    );
  }
}
