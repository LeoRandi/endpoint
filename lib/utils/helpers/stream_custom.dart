import '_imports.dart';

/// Simplifica la sintaxis para crear objetos de tipo [StreamController]
class StreamCustom<T> {
  late StreamController<T> _controller;

  /// Crea un [StreamController] que pueden tener varios oyentes
  StreamCustom() {
    _controller = StreamController<T>.broadcast();
  }

  /// Crea un [StreamController] de un solo oyente y única subscripción
  StreamCustom.single() {
    _controller = StreamController<T>();
  }

  /// Notifica el dato al Stream siempre que no sea un tipo de valor no válido
  void sink(T data) {
    if (_controller.isClosed) return;
    _controller.sink.add(data);
  }

  Stream<T> get stream => _controller.stream;

  /// Cierra el [StreamController] actual
  Future<void> close() async {
    await _controller.close();
  }

  void call(T data) => sink(data);

  bool get hasListener => _controller.hasListener;
  bool get isClosed => _controller.isClosed;
}
