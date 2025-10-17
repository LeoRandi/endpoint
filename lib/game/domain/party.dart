import 'player.dart';

class Party {
  final List<Player> players;
  Party({required this.players});
  bool get anyAlive => players.any((p) => p.isAlive);
}
