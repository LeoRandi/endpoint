import 'dart:developer' as developer;

int idx(int x, int y, int width) {
  return y * width + x;
}

bool depthOutOfBounds(int depth) {
  return depth < -1 || depth > 2; //only accepts depths between -1 and 2
}

//================================================================================
// DateTIme
//================================================================================
DateTime get now => DateTime.now();
DateTime get lastMomentOfYear =>
    DateTime(DateTime.now().year, 12, 31, 23, 59, 59);
DateTime get firstMomentOfYear => DateTime(DateTime.now().year, 1, 1, 0, 0, 0);

//================================================================================
// Bool
//================================================================================
bool isNullOrFalse(bool? value) {
  return value == null || !value;
}

bool isTrue(bool? value) {
  return value != null && value;
}

bool isFalse(bool? value) {
  return value != null && !value;
}

//================================================================================
// String
//================================================================================
bool isStringNullOrEmpty(String? value) {
  if (value == null) return true;
  if (value.isEmpty) return true;
  return false;
}

bool isStringFilled(String? value) => !isStringNullOrEmpty(value);

bool isStringAnInteger(String? value) {
  if (isStringNullOrEmpty(value)) return false;
  if (int.tryParse(value!) == null) return false;
  return true;
}

/// Devuelve [replace] si [value] es [null] o vacío.
String replaceIfNullOrEmpty(String? value, String replace) {
  if (isStringNullOrEmpty(value)) return replace;
  return value!;
}

const splitSeparator = ";";

void printLongString(String text) {
  // Define the chunk size of each substring
  const int chunkSize = 200;
  // Calculate the number of chunks
  final int chunks = (text.length / chunkSize).ceil();

  // Loop over the number of chunks
  for (int i = 0; i < chunks; i++) {
    // Define the start and end of each chunk
    int start = i * chunkSize;
    int end =
        (i + 1) * chunkSize > text.length ? text.length : (i + 1) * chunkSize;

    // Print the substring chunk
    developer.log(text.substring(start, end));
  }
}

//================================================================================
// Num
//================================================================================
/// Comprueba si un [int] o [double] es [null] o menor que cero
bool isNullOrLesserZero(num? number) {
  if (number == null) return true;
  if ((number is int || number is double) && number < 0) return true;
  return false;
}

bool isGreaterZero(num? number) => !isNullLesserOrEqualZero(number);
bool isLesserOne(num? number) => isNullLesserOrEqualZero(number);

/// Comprueba si un [int] o [double] es [null] o cero.
bool isNullOrZero(num? number) {
  if (number == null) return true;
  if ((number is int || number is double) && number == 0) return true;
  return false;
}

/// Comprueba si un [int] o [double] es [null] o menor o igual que cero
bool isNullLesserOrEqualZero(num? number) {
  if (number == null) return true;
  if (number <= 0) return true;
  return false;
}

/// Devuelve un [String] con el número de metros o kilómetros.
String toDistanceString(num? meters, String textMeters, String textKilometers) {
  if (meters == null) return "0 $textMeters";
  if (meters < 1000) return "${meters.toStringAsFixed(0)} $textMeters";
  return "${(meters / 1000).toStringAsFixed(1)} $textKilometers";
}

//================================================================================
// Colecciones
//================================================================================
bool isListNullOrEmpty(List? object) {
  if (object == null) return true;
  if (object.isEmpty) return true;
  return false;
}

bool isListFilled(List? object) => !isListNullOrEmpty(object);

bool isListOnlyOne(List? object) => isListFilled(object) && object!.length == 1;

bool isIterableNullOrEmpty(Iterable? object) {
  if (object == null) return true;
  if (object.isEmpty) return true;
  return false;
}

bool isMapNullOrEmpty(Map? object) {
  if (object == null) return true;
  if (object.isEmpty) return true;
  return false;
}

void foreachNotNull<T>(
  List<T> list,
  void Function(T item) action,
) {
  for (T item in list) {
    if (item == null) continue;
    action(item);
  }
}

void addIfNotNull<T>(List<T> list, T item) {
  if (item != null) list.add(item);
}

K? getMapKey<K, V>(Map<K, V> map, V value) {
  final index = map.values.toList().indexWhere((e) => e == value);
  if (isNullLesserOrEqualZero(index)) return null;
  return map.keys.elementAt(index);
}

V? getMapValue<K, V>(Map<K, V> map, K key) {
  if (key == null) return null;
  if (map.containsKey(key)) return map[key];
  return null;
}

/// Devuelve -1 si no se encuentra [value].
int getIndexValue<K, V>(Map<K, V> map, V value) =>
    map.values.toList().indexWhere((e) => e == value);

/// Devuelve -1 si no se encuentra [key].
int getIndexKey<K, V>(Map<K, V> map, K key) =>
    map.keys.toList().indexWhere((e) => e == key);
