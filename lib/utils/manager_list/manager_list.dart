import "_imports.dart";

class ManagerList<T> {
  final List<T> models;
  bool get isStarted => _isStarted;
  bool _isStarted = false;
  StreamSubscription? _subscription;

  final _onChange = StreamCustom<OnChanged<T>>();
  Stream<OnChanged<T>> get onChange => _onChange.stream;

  final _onStarted = StreamCustomEmpty();
  Stream<Null> get onStarted => _onStarted.stream;

  bool get isEmpty => models.isEmpty;
  bool get isNotEmpty => models.isNotEmpty;
  T? firstWhere(bool Function(T t) test) => models.firstWhere2(test);

  /// Cierra totalmente el manager e impide el uso correcto de la instancia.
  /// Se deberá crear otra instancia para seguir usándolo.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _isStarted = false;
  }

  void internalRestart() {
    _subscription?.cancel();
    _isStarted = false;
  }

  ManagerList(this.models);


}