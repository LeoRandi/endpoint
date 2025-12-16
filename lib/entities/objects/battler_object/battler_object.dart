import "_imports.dart";

class BattlerObject extends BaseObject {
  final int id;
  Battler battler;

  BattlerObject(int x, int y, int z, this.id, this.battler) : super(x, y, z);
}

extension BattlerObjectManager on ManagerList<BattlerObject> {
  int nextId() {
    return lastId() + 1;
  }

  int lastId() {
    if(this.isEmpty) return 0;
    final list = this.models.sortByInt((battler) => battler.id);
    return list.last.id;
  }
}
