import 'battler/_exports.dart';
import 'item/_exports.dart';
import 'status/_exports.dart';

abstract final class CodexDiscoveryHook {
  static bool isSuppressed = false;
  static void Function(ItemId itemId)? onItemAdded;
  static void Function(BattlerAbilityId abilityId)? onAbilityAdded;
  static void Function(BattlerStatusId statusId)? onStatusApplied;
}
