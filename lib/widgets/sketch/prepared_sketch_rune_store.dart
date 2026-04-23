import '../_imports.dart';

/// Snapshot inmutable del dibujo precargado para el sistema Quick Draw.
class PreparedSketchRune {
  final List<EndpointSketchStroke> strokes;

  const PreparedSketchRune({
    required this.strokes,
  });

  bool get hasStrokes => strokes.isNotEmpty;
}

/// Almacen compartido en memoria para el dibujo precargado actual.
abstract final class PreparedSketchRuneStore {
  static PreparedSketchRune? _preparedRune;

  static PreparedSketchRune? get preparedRune => _preparedRune;
  static bool get hasPreparedRune => _preparedRune?.hasStrokes ?? false;

  static void saveFromStrokes(List<EndpointSketchStroke> strokes) {
    if (strokes.isEmpty) {
      return;
    }
    _preparedRune = PreparedSketchRune(
      strokes: List<EndpointSketchStroke>.unmodifiable(
        strokes.map(_cloneStroke),
      ),
    );
  }

  static List<EndpointSketchStroke> clonePreparedStrokes() {
    final rune = _preparedRune;
    if (rune == null) {
      return const <EndpointSketchStroke>[];
    }

    return rune.strokes.map(_cloneStroke).toList(growable: false);
  }

  static void clear() {
    _preparedRune = null;
  }

  static EndpointSketchStroke _cloneStroke(EndpointSketchStroke stroke) {
    return EndpointSketchStroke(
      id: stroke.id,
      color: stroke.color,
      points: List<Offset>.unmodifiable(List<Offset>.from(stroke.points)),
    );
  }
}
