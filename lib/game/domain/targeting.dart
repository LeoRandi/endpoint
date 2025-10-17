import 'character.dart';

enum TargetType { singleEnemy, singleAlly, self }

class Targeting {
  static Character single(List<Character> candidates) => candidates.first;
}
