import "_imports.dart";

extension IterableExtensionV2<T> on Iterable<T> {
  /// Alias de [firstWhere] que no requiere asignar [orElse].
  ///
  /// Devuelve null si no se encuentra.
  T? firstWhere2(bool Function(T m) match) => toList().firstWhere2(match);
  List<T> where2(bool Function(T m) match) => where(match).toList();
  bool get isOne => length == 1;
  bool hasIndex(int index) {
    if (isEmpty) return false;
    return index >= 0 && index < length;
  }

  T getIndexOr(int index, T Function() or) =>
      hasIndex(index) ? elementAt(index) : or();
}

extension ListExtensionV2<T> on List<T> {
  T? whereReplaceable(bool Function(T m) isMatch,
      bool Function(T original, T replacement) isReplaceable) {
    T? mf;

    for (final m in this) {
      if (isMatch(m)) {
        if (mf == null || isReplaceable(mf, m)) mf = m;
      }
    }

    return mf;
  }

  bool containsAny(List<T> other) {
    for (final o in other) {
      if (contains(o)) return true;
    }
    return false;
  }

  List<T> sortByInt(int Function(T o) getInt) {
    if (isEmpty) return this;
    sort((a, b) => getInt(a).compareTo(getInt(b)));
    return this;
  }

  List<T> sortByText(String Function(T o) getText) {
    if (isEmpty) return this;
    sort(
        (a, b) => getText(a).toLowerCase().compareTo(getText(b).toLowerCase()));
    return this;
  }

  List<T> intercalate(T middle) {
    if (isEmpty) return this;
    List<T> result = [];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < (length - 1)) result.add(middle);
    }
    return result;
  }

  double sumDouble(double Function(T m) getDouble) {
    double result = 0;
    for (final m in this) {
      result += getDouble(m);
    }
    return result;
  }

  int sumInt(int Function(T m) getInt) {
    int result = 0;
    for (final m in this) {
      result += getInt(m);
    }
    return result;
  }

  /// Devuelve la lista sin duplicados.
  List<T> distinct() => toSet().toList();

  T? getByIndexNullable(int index) {
    if (isNullOrLesserZero(index)) return null;
    if (index >= length) return null;
    return this[index];
  }

  void removeNulls() => removeWhere((m) => m == null);

  /// Esto ordena las fechas de más antigua a más reciente.
  void sortByDateAsc(DateTime? Function(T o) getDate) =>
      _sortByDate(getDate, isAscendent: true);

  /// Esto ordena las fechas de más reciente a más antigua.
  void sortByDateDesc(DateTime? Function(T o) getDate) =>
      _sortByDate(getDate, isAscendent: false);

  void _sortByDate(DateTime? Function(T o) getDate, {bool isAscendent = true}) {
    if (isListNullOrEmpty(this)) return;

    sort((m1, m2) {
      final d1 = getDate(m1);
      final d2 = getDate(m2);
      if (d1 == null && d2 == null) return 0;
      if (d1 == null) return isAscendent ? 1 : -1;
      if (d2 == null) return isAscendent ? -1 : 1;
      return isAscendent ? d1.compareTo(d2) : d2.compareTo(d1);
    });
  }

  /// Alias de [firstWhere] que no requiere asignar [orElse].
  ///
  /// Devuelve null si no se encuentra.
  T? firstWhere2(bool Function(T m) match) {
    for (T e in this) {
      if (match(e)) return e;
    }
    return null;
  }

  bool exists(bool Function(T m) match) {
    final o = this.firstWhere2(match);
    return o != null;
  }

  void addOrUpdate(T m1, bool Function(T m1, T m2) match) {
    final index = indexWhere((m2) => match(m1, m2));
    if (index < 0) {
      add(m1);
    } else {
      this[index] = m1;
    }
  }

  void addNew(T m1, bool Function(T m1, T m2) match) {
    final index = indexWhere((m2) => match(m1, m2));
    if (index < 0) add(m1);
  }

  /// Alias de [firstWhere] que no requiere asignar [orElse].
  ///
  /// Devuelve null si no se encuentra.
  List<T> where2(bool Function(T m) match) => where(match).toList();
  void forEach2(void Function(T m) funct) => forEach(funct);
  List<E> map2<E>(E Function(T e) funct) => map<E>(funct).toList();
  bool get isOne => length == 1;
  bool get isGreaterOne => length >= 2;
  bool get isOneOrLess => isListNullOrEmpty(this) || length == 1;

  /// Devuelve elementos únicos de la lista.

  List<T> getUniques({
    required bool Function(T object1, T object2) isEquals,
  }) {
    final result = <T>[];
    for (final m in this) {
      if (result.exists((m2) => isEquals(m, m2))) continue;
      result.add(m);
    }
    return result;
  }

  /// Obtiene los elementos del listado paginados.
  ///
  /// [pageIndex] empieza por valor 0.
  List<T> getPaginated(int pageIndex, int itemsByPage) {
    if (isEmpty) return this;

    int start = pageIndex * itemsByPage;
    if (length <= start) return [];

    int end = min((pageIndex + 1) * itemsByPage, length);
    if (end == start) return [];

    return getRange(start, end).toList();
  }

  /// Devuelve la lista que esta envuelta por otras listas. Por ejemplo:
  /// ```
  /// List<List<List<List<double>>>> list =
  /// [
  ///  [
  ///   [
  ///    [1, 2, 3],
  ///    [4, 5, 6],
  ///    [7, 8, 9]
  ///   ]
  ///  ]
  /// ];
  /// ```
  ///
  /// ```dart
  /// final result = list.flatten();
  /// ```
  /// Devuelve:
  /// ```
  /// [ [1, 2, 3], [4, 5, 6], [7, 8, 9] ]
  /// ```
  List<dynamic> flatten() => _flatten(this);

  List<dynamic> _flatten(List<dynamic> lista) {
    if (lista.length == 1 && lista[0] is List) return _flatten(lista[0]);
    return lista;
  }

  T? getWithGreaterNum(
    num? Function(T object) getNum,
  ) {
    T? result;
    for (final m in this) {
      if (result == null) {
        if (getNum(m) != null) result = m;
      } else {
        final temp = getNum(m);
        if (temp == null) continue;
        if (temp <= getNum(result)!) continue;
        result = m;
      }
    }
    return result;
  }

  T? getWithCloserToZero(
    num? Function(T object) getNum,
  ) {
    T? result;
    for (final m in this) {
      if (result == null) {
        if (getNum(m) != null) result = m;
      } else {
        final temp = getNum(m)?.abs();
        if (temp == null) continue;
        if (temp >= getNum(result)!.abs()) continue;
        result = m;
      }
    }
    return result;
  }

  T? getLatestDate(DateTime Function(T o) getDate) {
    if (isEmpty) return null;
    // Clonamos el listado para que no altere el orden original.
    final ms = toList();
    ms.sortByDateDesc(getDate);
    return ms.first;
  }

  /// Divide una lista en listas más pequeñas (chunks) de tamaño [chunkSize].
  // ignore: avoid_shadowing_type_parameters
  List<List<T>> chunkList<T>(int chunkSize) {
    if (chunkSize <= 0) return [];

    List<List<T>> chunks = [];

    for (var i = 0; i < length; i += chunkSize) {
      final end = (i + chunkSize < length) ? i + chunkSize : length;
      final sl = sublist(i, end);
      chunks.add(sl as List<T>);
    }

    return chunks;
  }

  /// Devuelve el siguiente valor en la lista, si es el último devuelve el primero.
  T getNext(T currentValue) {
    if (isEmpty) return currentValue;
    if (isOne) return first;

    final currentIndex = indexOf(currentValue);
    if (currentIndex == -1) return first;

    final nextIndex = (currentIndex + 1) % length;
    return this[nextIndex];
  }
}
