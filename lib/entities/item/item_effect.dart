import '_imports.dart';

const String itemEffectValuePlaceholder = '--value--';

/// Replaces every item-effect value marker in [template] with [value].
String interpolateItemEffectValue(String template, Object value) {
  final resolvedValue = '$value';
  return template
      .replaceAll(itemEffectValuePlaceholder, resolvedValue)
      .replaceAll('{value}', resolvedValue);
}

abstract final class ItemEffectKeys {
  static const String sunglasses = 'sunglasses';
  static const String nanoBandageTurnStartHeal = 'nano_bandage_turn_start_heal';
  static const String sHarpEner = 's_harp_ener';
}

/// Base value object for every effect an item can own.
sealed class Effect {
  final int value;

  const Effect({required this.value});

  /// Creates the same effect with a different tier-scaled value.
  Effect withValue(int value);
}

/// An immediate action performed when the item is activated.
final class ActionEffect extends Effect {
  final ItemActionType actionType;
  final String? description;
  final String? customEffectKey;
  final Map<String, int> bonusValuesBySource;

  const ActionEffect({
    required this.actionType,
    this.description,
    this.customEffectKey,
    this.bonusValuesBySource = const <String, int>{},
    required super.value,
  }) : assert(
          actionType != ItemActionType.none ||
              (description != null &&
                  description != '' &&
                  customEffectKey != null &&
                  customEffectKey != ''),
          'ActionEffect.none requires a description and customEffectKey.',
        );

  int get bonusValue => bonusValuesBySource.values.fold<int>(
        0,
        (total, value) => total + value,
      );
  int get totalValue => max(0, value + bonusValue);
  bool get showsPointBadge => actionType != ItemActionType.none || value > 0;

  int bonusValueForSource(String sourceKey) {
    return bonusValuesBySource[sourceKey] ?? 0;
  }

  String? get resolvedDescription => description == null
      ? null
      : interpolateItemEffectValue(description!, totalValue);

  @override
  ActionEffect withValue(int value) => ActionEffect(
        actionType: actionType,
        description: description,
        customEffectKey: customEffectKey,
        bonusValuesBySource: bonusValuesBySource,
        value: value,
      );

  ActionEffect withBonusSource({
    required String sourceKey,
    required int bonusValue,
  }) {
    final safeSourceKey = sourceKey.trim();
    if (safeSourceKey.isEmpty) return this;

    final nextBonusValues = Map<String, int>.from(bonusValuesBySource);
    if (bonusValue == 0) {
      nextBonusValues.remove(safeSourceKey);
    } else {
      nextBonusValues[safeSourceKey] = bonusValue;
    }
    return ActionEffect(
      actionType: actionType,
      description: description,
      customEffectKey: customEffectKey,
      bonusValuesBySource: Map<String, int>.unmodifiable(nextBonusValues),
      value: value,
    );
  }

  factory ActionEffect.attack({required int value}) => ActionEffect(
        actionType: ItemActionType.attack,
        value: value,
      );

  factory ActionEffect.block({required int value}) => ActionEffect(
        actionType: ItemActionType.block,
        value: value,
      );

  factory ActionEffect.heal({required int value}) => ActionEffect(
        actionType: ItemActionType.heal,
        value: value,
      );
}

/// An action produced when the item satisfies a pattern requirement.
final class PatternEffect extends Effect {
  final OperativePatternRequirement patternType;
  final ActionEffect actionEffect;

  PatternEffect({
    required this.patternType,
    required this.actionEffect,
  }) : super(value: actionEffect.value);

  int get bonusValue => actionEffect.bonusValue;
  Map<String, int> get bonusValuesBySource => actionEffect.bonusValuesBySource;
  int get totalValue => actionEffect.totalValue;

  @override
  PatternEffect withValue(int value) => PatternEffect(
        patternType: patternType,
        actionEffect: actionEffect.withValue(value),
      );

  PatternEffect withActionBonusSource({
    required String sourceKey,
    required int bonusValue,
  }) =>
      PatternEffect(
        patternType: patternType,
        actionEffect: actionEffect.withBonusSource(
          sourceKey: sourceKey,
          bonusValue: bonusValue,
        ),
      );
}

/// A described numeric effect evaluated at a combat lifecycle hook.
final class PassiveEffect extends Effect {
  final ItemEffectHook hook;
  final String effectKey;
  final String description;

  const PassiveEffect({
    required this.hook,
    required this.effectKey,
    required this.description,
    required super.value,
  })  : assert(effectKey != '', 'PassiveEffect requires an effect key.'),
        assert(description != '', 'PassiveEffect requires a description.');

  String get resolvedDescription =>
      interpolateItemEffectValue(description, value);

  @override
  PassiveEffect withValue(int value) => PassiveEffect(
        hook: hook,
        effectKey: effectKey,
        description: description,
        value: value,
      );
}

/// Final owner/opponent state returned by item-effect lifecycle entry points.
class ItemEffectResolution {
  final Battler owner;
  final Battler opponent;
  final int attackBonusDelta;
  final int barrierBonusDelta;
  final List<ActionEffect> followUpActions;

  const ItemEffectResolution({
    required this.owner,
    required this.opponent,
    this.attackBonusDelta = 0,
    this.barrierBonusDelta = 0,
    this.followUpActions = const <ActionEffect>[],
  });
}

/// Combat moments at which a [PassiveEffect] can be evaluated.
enum ItemEffectHook {
  combatStart,
  turnStart,
  turnEnd,
  combatEnd,
  prePatternAttack,
  patternUsed,
  defendResolved,
  outgoingDamageModifier,
  incomingDamageEffect,
  incomingDamageModifier,
  calculatedStatModifier,
  basicAttackCountModifier,
  attackResolved,
  receiveDamageResolved,
  passive,
  outgoingStatusModifier,
  incomingStatusModifier,
  contagioValueLost,
  fatalDamage,
}

class ItemIncomingStatusResolution {
  final Battler owner;
  final Battler source;
  final BattlerStatus? status;

  const ItemIncomingStatusResolution({
    required this.owner,
    required this.source,
    required this.status,
  });
}
