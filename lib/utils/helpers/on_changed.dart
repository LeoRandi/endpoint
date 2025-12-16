enum OnChangedType {
  insert,
  update,
  remove,
}

class OnChanged<T> {
  /// The previous value before the change.
  ///
  /// This is only set when [type] is [OnChangedType.update].
  ///
  /// If the database is SQLite, this will be null when [rawQuery] is executed.
  final T? before;
  final T after;
  final OnChangedType type;

  OnChanged({
    required this.before,
    required this.after,
    required this.type,
  });
}
