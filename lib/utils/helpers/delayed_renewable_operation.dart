import '_imports.dart';

/// Ejecuta una función al terminar el tiempo indicado.
/// Si se vuelve a llamar la función antes de finalizar, reinicia el tiempo transcurrido.
class DelayedRenewableOperation {
  Timer? _timer;
  final Duration delay;
  final void Function() function;

  DelayedRenewableOperation({required this.delay, required this.function});

  void execute() {
    _timer?.cancel();
    _timer = Timer(delay, function);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  void call() => execute();
}

/// Ejecuta una función al terminar el tiempo indicado.
/// Si se vuelve a llamar la función antes de finalizar, reinicia el tiempo transcurrido.
class DelayedRenewableOperationV2 {
  Timer? _timer;
  final Duration delay;

  DelayedRenewableOperationV2({required this.delay});

  void execute(Function() function) {
    _timer?.cancel();
    _timer = Timer(delay, function);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

class DelayedRenewableOperationV3 {
  Timer? _timer;

  DelayedRenewableOperationV3();

  void execute(Duration delay, Function() function) {
    _timer?.cancel();
    _timer = Timer(delay, () => function());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
