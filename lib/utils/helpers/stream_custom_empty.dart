import '_imports.dart';

class StreamCustomEmpty {
  late StreamController<Null> _controller;

  /// Crea un [StreamController] que pueden tener varios oyentes
  StreamCustomEmpty() {
    _controller = StreamController<Null>.broadcast();
  }

  /// Crea un [StreamController] de un solo oyente y única subscripción
  StreamCustomEmpty.single() {
    _controller = StreamController<Null>();
  }

  void sink() {
    if (_controller.isClosed) return;
    if (_controller.isPaused) return;
    _controller.sink.add(null);
  }

  StreamSubscription<Null> listen(void onData()) {
    if (_controller.isClosed) return EmptyStreamSubscription<Null>();
    return _controller.stream.listen((_) => onData());
  }

  Stream<Null> get stream => _controller.stream;

  /// Cierra el [StreamController] actual
  Future<void> close() async {
    await _controller.close();
  }

  void call() => sink();

  bool get hasListener => _controller.hasListener;
  bool get isClosed => _controller.isClosed;
}

class EmptyStreamSubscription<T> implements StreamSubscription<T> {
  @override
  Future<void> cancel() async {}
  @override
  void resume() {}
  @override
  bool get isPaused => false;

  @override
  Future<E> asFuture<E>([E? futureValue]) {
    return Future.value();
  }

  @override
  void onData(void Function(T data)? handleData) {}

  @override
  void onDone(void Function()? handleDone) {}

  @override
  void onError(Function? handleError) {}

  @override
  void pause([Future<void>? resumeSignal]) {}
}
