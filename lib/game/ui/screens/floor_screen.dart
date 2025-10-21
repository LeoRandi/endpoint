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
    final rows = widget.grid.rows;
    final cols = widget.grid.cols;

    const double outerMargin = 12; // margen exterior (similar al appbar visualmente)
    const double framePad = 8;     // padding interno del marco
    const double tileSpacing = 4;  // separación entre tiles
    const double borderStroke = 1; // ancho del borde del marco

    // Área disponible dentro del body (LayoutBuilder te da ancho/alto reales)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Piso 1'),
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
            // Quitamos márgenes exteriores para que “respire” como el AppBar
            final availW = (c.maxWidth - outerMargin * 2).clamp(0, double.infinity);
            final availH = (c.maxHeight - outerMargin * 2).clamp(0, double.infinity);

            // El marco tiene: framePad a cada lado + (cols+1)*tileSpacing entre/contiguo a tiles
            // Área útil para tiles dentro del marco:
            final innerW = (availW - (framePad * 2) - (tileSpacing * (cols + 1))).clamp(0, double.infinity);
            final innerH = (availH - (framePad * 2) - (tileSpacing * (rows + 1))).clamp(0, double.infinity);

            // Tamaño de cada tile, usando el mínimo para no desbordar
            final tileSize = math.max(0, math.min(innerW / cols, innerH / rows));

            // Tamaño final del grid + marco (para centrarlo exactamente)
            final gridW = (tileSize * cols) + (tileSpacing * (cols + 1)) + (framePad * 2);
            final gridH = (tileSize * rows) + (tileSpacing * (rows + 1)) + (framePad * 2);

            final frame = Container(
              width: gridW,
              height: gridH,
              padding: const EdgeInsets.all(framePad),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: borderStroke,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(rows, (r) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(cols, (c2) {
                      final t = widget.grid.cell(r, c2);
                      return Container(
                        width: tileSize.toDouble(),
                        height: tileSize.toDouble(),
                        margin: const EdgeInsets.all(tileSpacing),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_cellEmoji(t), textAlign: TextAlign.center),
                        ),
                      );
                    }),
                  );
                }),
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
                if (evt.logicalKey != LogicalKeyboardKey.keyZ) {
                  return KeyEventResult.ignored;
                }
                if (evt is RawKeyDownEvent) _zHeld = true;
                if (evt is RawKeyUpEvent) _zHeld = false;
                return KeyEventResult.handled;
              },
              child: Listener(
                onPointerSignal: (PointerSignalEvent sig) {
                  if (!_zHeld || sig is! PointerScrollEvent) return;
                  final dy = sig.scrollDelta.dy;
                  final factor = math.pow(1.0018, -dy);
                  _applyScale(_scale * factor);
                },
                child: InteractiveViewer(
                  transformationController: _tc,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  panEnabled: true,
                  scaleEnabled: true, // pinch-zoom
                  // margen para poder “sacar” el grid del centro al hacer pan
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
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyScale(1.0),
                  child: const Text('Reset zoom'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _applyScale((_scale * 1.25).clamp(_minScale, _maxScale)),
                  child: const Text('Zoom +'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _applyScale((_scale / 1.25).clamp(_minScale, _maxScale)),
                  child: const Text('Zoom −'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
