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
  static const String kindlingAxeBurnBoth = 'kindling_axe_burn_both';
  static const String furnaceHeartAdjacentWeapons =
      'furnace_heart_adjacent_weapons';
  static const String furnaceHeartRightAngleTrigger =
      'furnace_heart_right_angle_trigger';
  static const String bloodflameGauntletLowHpDamage =
      'bloodflame_gauntlet_low_hp_damage';
  static const String bloodflameGauntletBurnRevenge =
      'bloodflame_gauntlet_burn_revenge';
  static const String crownOfTheBlackSunBurnScaling =
      'crown_of_the_black_sun_burn_scaling';
  static const String crownOfTheBlackSunNoDeathOnce =
      'crown_of_the_black_sun_no_death_once';
  static const String crownOfTheBlackSunFinisher =
      'crown_of_the_black_sun_finisher';
  static const String oathplateCleanse = 'oathplate_cleanse';
  static const String whitewallStandardBarrierBoost =
      'whitewall_standard_barrier_boost';
  static const String whitewallStandardBuffStacking =
      'whitewall_standard_buff_stacking';
  static const String rampartRamBarrierDamage = 'rampart_ram_barrier_damage';
  static const String rampartRamFinisher = 'rampart_ram_finisher';
  static const String citadelCoreCleanseHeal = 'citadel_core_cleanse_heal';
  static const String citadelCoreFortressScaling =
      'citadel_core_fortress_scaling';
  static const String citadelCoreUnbrokenRetaliation =
      'citadel_core_unbroken_retaliation';
  static const String citadelCoreSquareFortress =
      'citadel_core_square_fortress';
  static const String needlewheelComboRepeat = 'needlewheel_combo_repeat';
  static const String venomMetronomeRepeatedActionPoison =
      'venom_metronome_repeated_action_poison';
  static const String venomMetronomeZigzag = 'venom_metronome_zigzag';
  static const String leechwireCoilHealFromDebuffs =
      'leechwire_coil_heal_from_debuffs';
  static const String leechwireCoilDebuffDamage =
      'leechwire_coil_debuff_damage';
  static const String leechwireCoilMiddleContagio =
      'leechwire_coil_middle_contagio';
  static const String thousandCutHaloActionScaling =
      'thousand_cut_halo_action_scaling';
  static const String thousandCutHaloStatusEcho =
      'thousand_cut_halo_status_echo';
  static const String thousandCutHaloFinisher = 'thousand_cut_halo_finisher';
  static const String lanzamonedasSpendGoldDamage =
      'lanzamonedas_spend_gold_damage';
  static const String cashbackBadgeRefund = 'cashback_badge_refund';
  static const String cashbackBadgeSpendPotencia =
      'cashback_badge_spend_potencia';
  static const String cashbackBadgeOpeningDiscount =
      'cashback_badge_opening_discount';
  static const String contrabandCatalogueMixedArchetypeScaling =
      'contraband_catalogue_mixed_archetype_scaling';
  static const String contrabandCatalogueGoldSpendEcho =
      'contraband_catalogue_gold_spend_echo';
  static const String contrabandCatalogueMiddleProfit =
      'contraband_catalogue_middle_profit';
  static const String goldenGodfatherRichScaling =
      'golden_godfather_rich_scaling';
  static const String goldenGodfatherFinisher =
      'golden_godfather_finisher';
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

class ItemFollowUpAction {
  final Item item;
  final ActionEffect action;

  const ItemFollowUpAction({
    required this.item,
    required this.action,
  });
}

/// Final owner/opponent state returned by item-effect lifecycle entry points.
class ItemEffectResolution {
  final Battler owner;
  final Battler opponent;
  final int attackBonusDelta;
  final int barrierBonusDelta;
  final BattlerStatus? status;
  final List<ActionEffect> followUpActions;
  final List<ItemFollowUpAction> followUpItemActions;

  const ItemEffectResolution({
    required this.owner,
    required this.opponent,
    this.attackBonusDelta = 0,
    this.barrierBonusDelta = 0,
    this.status,
    this.followUpActions = const <ActionEffect>[],
    this.followUpItemActions = const <ItemFollowUpAction>[],
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
  actionResolved,
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
