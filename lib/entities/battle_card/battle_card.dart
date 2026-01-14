import '_imports.dart';

enum BattleCardTag {
  creature,
  enemy,
  ally,
  effect,
  day,
  night,
  item,
  magic,
  physical,
  field,
}

class BattleCard {
  final String id;
  final String name;
  final String description;
  final int might;
  final List<BattleCardTag> tags = [];

  BattleCard({
    required this.id,
    required this.name,
    required this.description,
    required this.might,
    required List<BattleCardTag>? tags,
  });
}

class BattleCardBattler extends BattleCard {
  final Battler battler;

  BattleCardBattler({
    required String id,
    required String name,
    required String description,
    required int might,
    required List<BattleCardTag>? tags,
    required this.battler,
  }) : super(
          id: id,
          name: name,
          description: description,
          might: might,
          tags: tags,
        );
}

class BattleCardEffect extends BattleCard {
  final String effectType;

  BattleCardEffect({
    required String id,
    required String name,
    required String description,
    required int might,
    required List<BattleCardTag>? tags,
    required this.effectType,
  }) : super(
          id: id,
          name: name,
          description: description,
          might: might,
          tags: tags,
        );
}

enum DuelistSide {
  ally(0),
  enemy(1);

  final int value;
  const DuelistSide(this.value);
}

typedef Hand = List<BattleCard>;