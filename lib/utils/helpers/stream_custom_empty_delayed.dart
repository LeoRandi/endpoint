import '_imports.dart';

class StreamCustomEmptyDelayed {
  late DelayedRenewableOperationV2 _delayed;
  late StreamController<Null> _controller;

  /// Crea un [StreamController] que pueden tener varios oyentes
  StreamCustomEmptyDelayed([Duration? delay]) {
    _controller = StreamController<Null>.broadcast();
    _delayed = DelayedRenewableOperationV2(
      delay: delay ?? const Duration(milliseconds: 200),
    );
  }

  /// Crea un [StreamController] de un solo oyente y única subscripción
  StreamCustomEmptyDelayed.single(Duration delay) {
    _controller = StreamController<Null>();
    _delayed = DelayedRenewableOperationV2(delay: delay);
  }

  void sink() {
    _delayed.execute(() => _sink());
  }

  void _sink() {
    if (_controller.isClosed) return;
    _controller.sink.add(null);
  }

  StreamSubscription<Null>? listen(void Function() onData) {
    if (_controller.isClosed) return null;
    return _controller.stream.listen((_) => onData());
  }

  Stream<Null> get stream => _controller.stream;

  /// Cierra el [StreamController] actual
  Future<void> close() async {
    await _controller.close();
    _delayed.dispose();
  }

  void call() => sink();

  bool get hasListener => _controller.hasListener;
  bool get isClosed => _controller.isClosed;
}
