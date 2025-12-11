import '_imports.dart';

class StreamCustomDelayed<T> {
  late DelayedRenewableOperationV2 _delayed;
  late StreamController<T> _controller;

  /// Crea un [StreamController] que pueden tener varios oyentes
  StreamCustomDelayed([Duration? delay]) {
    _controller = StreamController<T>.broadcast();
    _delayed = DelayedRenewableOperationV2(
      delay: delay ?? const Duration(milliseconds: 200),
    );
  }

  /// Crea un [StreamController] de un solo oyente y única subscripción
  StreamCustomDelayed.single(Duration delay) {
    _controller = StreamController<T>();
    _delayed = DelayedRenewableOperationV2(delay: delay);
  }

  void sink(T data) {
    _delayed.execute(() => _sink(data));
  }

  void _sink(T data) {
    if (_controller.isClosed) return;
    _controller.sink.add(data);
  }

  StreamSubscription<T>? listen(void Function() onData) {
    if (_controller.isClosed) return null;
    return _controller.stream.listen((_) => onData());
  }

  Stream<T> get stream => _controller.stream;

  /// Cierra el [StreamController] actual
  Future<void> close() async {
    await _controller.close();
    _delayed.dispose();
  }

  void call(T data) => sink(data);

  bool get hasListener => _controller.hasListener;
  bool get isClosed => _controller.isClosed;
}
