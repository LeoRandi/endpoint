import "_imports.dart";

class BattlerGrid {
  final int width;
  final int height;
  final List<Battler> battlers; // length == width * height

  BattlerGrid(this.width, this.height, this.battlers);

  Battler battlerAt(int x, int y) => battlers[y * width + x];

  void setBattler(int x, int y, Battler battler) {
    battlers[y * width + x] = battler;
  }

  bool hasBattlerAt(int x, int y) => battlerAt(x, y).name.isNotEmpty;

  Widget getBattlerImage(int x, int y) {
    final battler = battlerAt(x, y);
    return Image.asset(battler.imagePath);
  }
}
