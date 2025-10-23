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

  IconData? _iconFor(CellType t) {
    switch (t) {
      case CellType.player: return Icons.person;     // jugador
      case CellType.wall:   return Icons.stop;       // cuadrado/rectángulo relleno
      case CellType.enemy:  return Icons.dangerous;  // enemigo
      case CellType.empty:  return null;             // sin icono
    }
  }

  Color _strongColorFor(BuildContext ctx, CellType t) {
    final cs = Theme.of(ctx).colorScheme;
    switch (t) {
      case CellType.wall:   return cs.outline;       // gris fuerte
      case CellType.enemy:  return Colors.redAccent; // rojo fuerte
      case CellType.player: return Colors.lightBlue; // azul fuerte
      case CellType.empty:  return Colors.transparent;
    }
  }

  Color _bgPastelFor(BuildContext ctx, CellType t) {
    final cs = Theme.of(ctx).colorScheme;
    switch (t) {
      case CellType.wall:   return cs.outlineVariant.withOpacity(0.18);
      case CellType.enemy:  return Colors.redAccent.withOpacity(0.16);
      case CellType.player: return Colors.lightBlueAccent.withOpacity(0.18);
      case CellType.empty:  return Colors.transparent;
    }
  }
  
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

            // Área disponible (resta márgenes exteriores)
            final availW = (c.maxWidth - outerMargin * 2).clamp(0, double.infinity);
            final availH = (c.maxHeight - outerMargin * 2).clamp(0, double.infinity);

            // Cálculo base del tile
            double tile = math.min(
              (availW - framePad * 2 - gap * (cols - 1)) / cols,
              (availH - framePad * 2 - gap * (rows - 1)) / rows,
            );
            if (!tile.isFinite) tile = 0;
            tile = tile.floorToDouble(); // que QUEPA

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

            // Dimensiones del contenido renderizado (incluido el outerMargin)
            final contentW = gridW + outerMargin * 2;
            final contentH = gridH + outerMargin * 2;

            // Centro del jugador en coords del child (content)
            double playerCx, playerCy;
            if (pr >= 0 && pc >= 0) {
              playerCx = outerMargin + framePad + pc * (tile + gap) + tile / 2;
              playerCy = outerMargin + framePad + pr * (tile + gap) + tile / 2;
            } else {
              playerCx = contentW / 2;
              playerCy = contentH / 2;
            }
            
            // Escala base para encajar todo
            final fitScaleW = (c.maxWidth / contentW);
            final fitScaleH = (c.maxHeight / contentH);
            final fitScale  = math.min(fitScaleW, fitScaleH).clamp(_minScale, _maxScale);

            // Queremos que la celda se “vea” (sin romper layout)
            const desiredTilePx = 18.0;
            final needForTile   = tile > 0 ? (desiredTilePx / tile) : 1.0;

            // ⚠️ Asegura que en VERTICAL el contenido llene el viewport (2% de margen)
            final needFillY = (c.maxHeight / contentH) * 1.02;

            // Boost suave
            const boost = 1.2;

            // Escala inicial final: quepa + se vea + llene vertical
            final initialScale = math.max(
              math.max(fitScale * boost, needForTile),
              needFillY,
            ).clamp(_minScale, _maxScale).toDouble();


            // Queremos: playerCenter*scale + (tx,ty) = viewportCenter
            double tx = (c.maxWidth  / 2) - playerCx * initialScale;
            double ty = (c.maxHeight / 2) - playerCy * initialScale;

            // Clamp para que el contenido completo permanezca dentro del viewport
            tx = _clampOffset(
              desired: tx,
              viewport: c.maxWidth,
              content: contentW,
              scale: initialScale,
            );
            ty = _clampOffset(
              desired: ty,
              viewport: c.maxHeight,
              content: contentH,
              scale: initialScale,
            );



            // Aplicar una única vez tras el primer frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final m = _tc.value;
              final isIdentity = m.storage[0] == 1.0 && m.storage[5] == 1.0 && m.storage[12] == 0.0 && m.storage[13] == 0.0;
              if (isIdentity) {
                _tc.value = Matrix4.identity()
                  ..translate(tx, ty)
                  ..scale(initialScale);
                _scale = initialScale;
                setState(() {});
              }
            });

            final radius = math.min(6.0, tile / 4);

            Widget buildRow(int r) {
              final children = <Widget>[];
              for (var c2 = 0; c2 < cols; c2++) {
                final t = widget.grid.cell(r, c2);
                final icon = _iconFor(t);

                children.add(Container(
                  width: tile,
                  height: tile,
                  decoration: BoxDecoration(
                    color: _bgPastelFor(context, t),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: icon == null
                      ? const SizedBox.shrink()
                      : Center(
                          child: Icon(
                            icon,
                            size: tile * 0.6,
                            color: _strongColorFor(context, t),
                          ),
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
            // (1) centro del viewport (área del body)
            // final viewportCx = c.maxWidth / 2;
            // final viewportCy = c.maxHeight / 2;
            // (2) offset tal que: playerCenter*scale + offset = viewportCenter
            // final tx = viewportCx - playerCx * initialScale;
            // final ty = viewportCy - playerCy * initialScale;
            // WidgetsBinding.instance.addPostFrameCallback((_) {
            //   // setImmediate (no animamos aquí para mantenerlo simple)
            //   if (_tc.value.storage[0] == 1.0 && _tc.value.storage[5] == 1.0) {
            //     _tc.value = Matrix4.identity()
            //       ..translate(tx, ty)
            //       ..scale(initialScale);
            //     _scale = initialScale;
            //     setState(() {});
            //   }
            // });

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
                  final newScale = (_scale * factor).clamp(_minScale, _maxScale).toDouble();

                  // Mantén la traslación actual; solo cambia la escala
                  final m = _tc.value.clone();
                  final curTx = m.storage[12];
                  final curTy = m.storage[13];

                  _tc.value = Matrix4.identity()
                    ..translate(curTx, curTy)
                    ..scale(newScale);

                  _scale = newScale;
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

  double _clampOffset({
    required double desired,   // tx o ty que quieres (centrado en jugador)
    required double viewport,  // ancho o alto del viewport
    required double content,   // ancho o alto del contenido (contentW/H)
    required double scale,
  }) {
    final span = viewport - content * scale; // si >= 0, el contenido cabe
    if (span >= 0) {
      // contenido más pequeño: rango permitido [0 .. span] (izq alineado .. dcha alineado)
      return desired.clamp(0.0, span);
    } else {
      // contenido más grande: rango permitido [span .. 0] (totalmente a la dcha .. izq)
      return desired.clamp(span, 0.0);
    }
  }


}
