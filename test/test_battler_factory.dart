import 'package:endpoint/entities/_exports.dart';

Battler buildTestBattler({
  required String name,
  String iconEmoji = '\u{1F916}',
  required int attack,
  required int defense,
  required int health,
  int? maxHealth,
  int money = 0,
  int income = 0,
  List<Object> abilities = const [],
  List<BattlerStatus> statuses = const [],
  List<Item> inventoryItems = const [],
  List<Item> equippedItems = const [],
  Set<String> combatFlags = const <String>{},
}) {
  return Battler(
    name: name,
    iconEmoji: iconEmoji,
    health: health,
    money: money,
    income: income,
    baseStats: {
      BattlerStat.health: maxHealth ?? health,
      BattlerStat.attack: attack,
      BattlerStat.defense: defense,
      BattlerStat.thorns: 0,
      BattlerStat.damageReduction: 0,
      BattlerStat.vampirism: 0,
    },
    abilities: List<BattlerAbility>.unmodifiable(
      abilities.map(_resolveTestAbility),
    ),
    statuses: List<BattlerStatus>.unmodifiable(statuses),
    inventoryItems: inventoryItems,
    equippedItems: equippedItems,
    combatFlags: combatFlags,
  );
}

BattlerAbility _resolveTestAbility(Object value) {
  if (value is BattlerAbility) return value;
  if (value is BattlerAbilityId) return BattlerAbility.presetForId(value);
  if (value is! String) {
    throw ArgumentError.value(
        value, 'value', 'Unsupported test ability value.');
  }

  switch (value.trim().toLowerCase()) {
    case 'defender':
    case 'defend':
      return defendAbility;
    case 'overclock':
      return overclockAbility;
    case 'purge':
      return purgeAbility;
    case 'escaner critico':
    case 'scanner critico':
    case 'critical scanner':
      return criticalScannerAbility;
    case 'caza de debilidades':
    case 'weakness hunter':
      return weaknessHunterAbility;
    case 'malla fantasma':
    case 'ghost mesh':
      return ghostMeshAbility;
    case 'catalisis cruel':
    case 'cruel catalysis':
      return cruelCatalysisAbility;
    case 'sobrecarga venosa':
    case 'venous overload':
      return venousOverloadAbility;
    case 'reinicio en seco':
    case 'hard reset':
      return hardResetAbility;
  }

  throw ArgumentError.value(value, 'value', 'Unknown test battler ability.');
}
