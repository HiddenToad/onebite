import 'dart:math';

List<T> randomSubset<T>(List<T> list, int n) {
  if (n >= list.length) {
    return List<T>.from(list)..shuffle();
  }
  var rng = Random();
  var copy = List<T>.from(list);
  copy.shuffle(rng);
  return copy.take(n).toList();
}

extension SafePop<T> on List<T> {
  T? popOrNull() {
    if (isEmpty) return null;
    return removeLast();
  }
}
