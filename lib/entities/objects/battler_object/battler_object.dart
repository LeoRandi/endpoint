import "_imports.dart";

class BattlerObject extends BaseObject {
  Battler battler;

  BattlerObject(int x, int y, int z, int id, this.battler) : super(x, y, z, id);
}